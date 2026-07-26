import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:zentask/models/event.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/bookmarks_repository.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/cloud/auth_service.dart';
import 'package:zentask/services/cloud/entity_row_mappers.dart';
import 'package:zentask/services/cloud/sync_metadata_store.dart';
import 'package:zentask/services/cloud/sync_service.dart';
import 'package:zentask/services/hive_service.dart';

/// Real [SyncService], backed by Supabase Postgres tables (see
/// `supabase/schema.sql`) plus Realtime.
///
/// **Conflict resolution**: last-write-wins by `updatedAt`. Every model
/// already carries one (added back in Phase 3/6/7 for exactly this kind
/// of "which copy is newer" question), so pulling a remote row only
/// overwrites the local copy when the remote is strictly newer — a
/// device that's been offline and made local edits doesn't lose them to
/// a stale pull.
///
/// **Offline queue**: rather than an eagerly-written mutation log (which
/// would mean instrumenting every existing repository's save/delete —
/// see the doc comment on [HiveService.syncMetaBoxName] for why that was
/// deliberately avoided), this diffs "records changed since last push"
/// and "known ids vs. current ids" to infer what needs to go up. Calling
/// [syncNow] while offline surfaces [SyncStatus.error] and simply leaves
/// `lastPushedAt`/`knownIds` unmoved, so the next successful sync
/// naturally picks up everything that accumulated in the meantime — the
/// queue is implicit in "not yet marked as synced" rather than an
/// explicit list.
///
/// **Realtime**: subscribes to `postgres_changes` on each table filtered
/// to the signed-in user's rows; incoming changes go through the same
/// last-write-wins merge as a pull, so a realtime event can never
/// clobber a newer local edit either.
class CloudSyncEngine implements SyncService {
  final supabase.SupabaseClient _client;
  final AuthService _authService;
  final SyncMetadataStore _meta;
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;
  final EventRepository _eventRepository;
  final BookmarksRepository _bookmarksRepository;
  final _statusController = StreamController<SyncStatus>.broadcast();
  final List<supabase.RealtimeChannel> _channels = [];

  SyncStatus _currentStatus = SyncStatus.idle;

  /// Settings keys worth syncing across devices — deliberately not the
  /// whole settings box, which also holds device-local bookkeeping
  /// (migration flags, this very sync engine's own metadata) that would
  /// make no sense to sync. See `supabase/schema.sql`'s doc comment.
  static const List<String> settingsSyncKeys = [
    'app_theme_mode',
    'app_accent_color',
    'notifications_enabled',
  ];

  CloudSyncEngine({
    supabase.SupabaseClient? client,
    required AuthService authService,
    SyncMetadataStore? metadataStore,
    ProjectRepository? projectRepository,
    TaskRepository? taskRepository,
    EventRepository? eventRepository,
    BookmarksRepository? bookmarksRepository,
  })  : _client = client ?? supabase.Supabase.instance.client,
        _authService = authService,
        _meta = metadataStore ?? SyncMetadataStore(),
        _projectRepository = projectRepository ?? ProjectRepository(),
        _taskRepository = taskRepository ?? TaskRepository(),
        _eventRepository = eventRepository ?? EventRepository(),
        _bookmarksRepository = bookmarksRepository ?? BookmarksRepository();

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  SyncStatus get currentStatus => _currentStatus;

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  Future<void> syncNow() async {
    final user = _authService.currentUser;
    if (user == null) return;

    _setStatus(SyncStatus.syncing);
    try {
      await _pushProjects(user.id);
      await _pushTasks(user.id);
      await _pushEvents(user.id);
      await _pushSettings(user.id);
      await _pushBookmarks(user.id);

      await _pullProjects(user.id);
      await _pullTasks(user.id);
      await _pullEvents(user.id);
      await _pullSettings(user.id);
      await _pullBookmarks(user.id);

      _setStatus(SyncStatus.idle);
    } catch (_) {
      _setStatus(SyncStatus.error);
      rethrow;
    }
  }

  // --- Projects ---

  Future<void> _pushProjects(String ownerId) async {
    const type = 'project';
    final local = _projectRepository.getAll();
    await _pushRecords(
      entityType: type,
      table: 'projects',
      ownerId: ownerId,
      ids: local.map((p) => p.id).toSet(),
      changed: (since) => local.where((p) => since == null || p.updatedAt.isAfter(since)),
      updatedAtOf: (p) => p.updatedAt,
      toRow: (p) => EntityRowMappers.projectToRow(p, ownerId),
    );
  }

  Future<void> _pullProjects(String ownerId) async {
    const type = 'project';
    final rows = await _pullRows(entityType: type, table: 'projects', ownerId: ownerId);
    for (final row in rows) {
      final id = row['id'] as String;
      if (row['deleted_at'] != null) {
        await _projectRepository.delete(id);
        continue;
      }
      final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
      final localProject = _projectRepository.getById(id);
      if (localProject != null && !remoteUpdatedAt.isAfter(localProject.updatedAt)) {
        continue; // local copy is newer or the same — last-write-wins
      }
      await _projectRepository.save(Project.fromMap(EntityRowMappers.rowToProjectMap(row)));
    }
    await _meta.setLastPulledAt(type, DateTime.now());
  }

  // --- Tasks ---

  Future<void> _pushTasks(String ownerId) async {
    const type = 'task';
    final local = _taskRepository.getAllTaskRecords();
    await _pushRecords(
      entityType: type,
      table: 'tasks',
      ownerId: ownerId,
      ids: local.map((t) => t.id).toSet(),
      changed: (since) => local.where(
          (t) => since == null || (t.updatedAt != null && t.updatedAt!.isAfter(since))),
      updatedAtOf: (t) => t.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      toRow: (t) => EntityRowMappers.taskToRow(t, ownerId),
    );
  }

  Future<void> _pullTasks(String ownerId) async {
    const type = 'task';
    final rows = await _pullRows(entityType: type, table: 'tasks', ownerId: ownerId);
    for (final row in rows) {
      final id = row['id'] as String;
      if (row['deleted_at'] != null) {
        await _taskRepository.deleteTaskRecord(id);
        continue;
      }
      final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
      final localTasks = _taskRepository.getAllTaskRecords();
      Task? localTask;
      for (final t in localTasks) {
        if (t.id == id) {
          localTask = t;
          break;
        }
      }
      if (localTask != null &&
          localTask.updatedAt != null &&
          !remoteUpdatedAt.isAfter(localTask.updatedAt!)) {
        continue;
      }
      await _taskRepository.saveTaskRecord(Task.fromMap(EntityRowMappers.rowToTaskMap(row)));
    }
    await _meta.setLastPulledAt(type, DateTime.now());
  }

  // --- Events ---

  Future<void> _pushEvents(String ownerId) async {
    const type = 'event';
    final local = _eventRepository.getAll();
    await _pushRecords(
      entityType: type,
      table: 'events',
      ownerId: ownerId,
      ids: local.map((e) => e.id).toSet(),
      changed: (since) => local.where((e) => since == null || e.updatedAt.isAfter(since)),
      updatedAtOf: (e) => e.updatedAt,
      toRow: (e) => EntityRowMappers.eventToRow(e, ownerId),
    );
  }

  Future<void> _pullEvents(String ownerId) async {
    const type = 'event';
    final rows = await _pullRows(entityType: type, table: 'events', ownerId: ownerId);
    for (final row in rows) {
      final id = row['id'] as String;
      if (row['deleted_at'] != null) {
        await _eventRepository.delete(id);
        continue;
      }
      final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
      final localEvent = _eventRepository.getById(id);
      if (localEvent != null && !remoteUpdatedAt.isAfter(localEvent.updatedAt)) {
        continue;
      }
      await _eventRepository.save(Event.fromMap(EntityRowMappers.rowToEventMap(row)));
    }
    await _meta.setLastPulledAt(type, DateTime.now());
  }

  // --- Settings (single JSON blob per user, whitelisted keys) ---

  Future<void> _pushSettings(String ownerId) async {
    final box = HiveService.settingsBox;
    final data = {for (final key in settingsSyncKeys) key: box.get(key)};
    await _client.from('user_settings').upsert({
      'owner_id': ownerId,
      'data': data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _pullSettings(String ownerId) async {
    final rows = await _client
        .from('user_settings')
        .select()
        .eq('owner_id', ownerId)
        .limit(1);
    if (rows.isEmpty) return;
    final data = rows.first['data'] as Map<String, dynamic>?;
    if (data == null) return;
    final box = HiveService.settingsBox;
    for (final key in settingsSyncKeys) {
      if (data.containsKey(key) && data[key] != null) {
        await box.put(key, data[key]);
      }
    }
  }

  // --- Bookmarks (whole-set sync — see the class doc comment on why
  // this entity gets a simpler treatment than Projects/Tasks/Events) ---

  Future<void> _pushBookmarks(String ownerId) async {
    final keys = _bookmarksRepository.getAllKeys();
    await _client.from('bookmarks').delete().eq('owner_id', ownerId);
    if (keys.isEmpty) return;
    await _client.from('bookmarks').upsert([
      for (final key in keys)
        {
          'owner_id': ownerId,
          'key': key,
          'updated_at': DateTime.now().toIso8601String(),
          'deleted_at': null,
        },
    ]);
  }

  Future<void> _pullBookmarks(String ownerId) async {
    final rows = await _client
        .from('bookmarks')
        .select()
        .eq('owner_id', ownerId)
        .isFilter('deleted_at', null);
    final localKeys = _bookmarksRepository.getAllKeys();
    for (final row in rows) {
      final key = row['key'] as String;
      if (!localKeys.contains(key)) {
        await _bookmarksRepository.markKeyBookmarked(key);
      }
    }
  }

  // --- Shared push/pull helpers ---

  Future<void> _pushRecords<T>({
    required String entityType,
    required String table,
    required String ownerId,
    required Set<String> ids,
    required Iterable<T> Function(DateTime? since) changed,
    required DateTime Function(T) updatedAtOf,
    required Map<String, dynamic> Function(T) toRow,
  }) async {
    final lastPushed = _meta.lastPushedAt(entityType);
    final knownIds = _meta.knownIds(entityType);
    final deletedIds = knownIds.difference(ids);

    for (final record in changed(lastPushed)) {
      await _client.from(table).upsert(toRow(record));
    }

    for (final id in deletedIds) {
      await _client
          .from(table)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .eq('owner_id', ownerId);
    }

    await _meta.setKnownIds(entityType, ids);
    await _meta.setLastPushedAt(entityType, DateTime.now());
  }

  Future<List<Map<String, dynamic>>> _pullRows({
    required String entityType,
    required String table,
    required String ownerId,
  }) async {
    final since = _meta.lastPulledAt(entityType);
    var query = _client.from(table).select().eq('owner_id', ownerId);
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final rows = await query;
    return rows.cast<Map<String, dynamic>>();
  }

  // --- Realtime ---

  @override
  void startRealtime() {
    final user = _authService.currentUser;
    if (user == null) return;
    stopRealtime();

    for (final table in ['projects', 'tasks', 'events']) {
      final channel = _client
          .channel('public:$table:${user.id}')
          .onPostgresChanges(
            event: supabase.PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: supabase.PostgresChangeFilter(
              type: supabase.PostgresChangeFilterType.eq,
              column: 'owner_id',
              value: user.id,
            ),
            callback: (payload) => _handleRealtimeChange(table, payload),
          )
          .subscribe();
      _channels.add(channel);
    }
  }

  void _handleRealtimeChange(String table, supabase.PostgresChangePayload payload) {
    final row = payload.newRecord;
    if (row.isEmpty) return;
    switch (table) {
      case 'projects':
        _applyRemoteProjectRow(row);
        break;
      case 'tasks':
        _applyRemoteTaskRow(row);
        break;
      case 'events':
        _applyRemoteEventRow(row);
        break;
    }
  }

  void _applyRemoteProjectRow(Map<String, dynamic> row) {
    final id = row['id'] as String;
    if (row['deleted_at'] != null) {
      _projectRepository.delete(id);
      return;
    }
    final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
    final local = _projectRepository.getById(id);
    if (local != null && !remoteUpdatedAt.isAfter(local.updatedAt)) return;
    _projectRepository.save(Project.fromMap(EntityRowMappers.rowToProjectMap(row)));
  }

  void _applyRemoteTaskRow(Map<String, dynamic> row) {
    final id = row['id'] as String;
    if (row['deleted_at'] != null) {
      _taskRepository.deleteTaskRecord(id);
      return;
    }
    final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
    final localTasks = _taskRepository.getAllTaskRecords();
    Task? local;
    for (final t in localTasks) {
      if (t.id == id) {
        local = t;
        break;
      }
    }
    if (local != null && local.updatedAt != null && !remoteUpdatedAt.isAfter(local.updatedAt!)) {
      return;
    }
    _taskRepository.saveTaskRecord(Task.fromMap(EntityRowMappers.rowToTaskMap(row)));
  }

  void _applyRemoteEventRow(Map<String, dynamic> row) {
    final id = row['id'] as String;
    if (row['deleted_at'] != null) {
      _eventRepository.delete(id);
      return;
    }
    final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
    final local = _eventRepository.getById(id);
    if (local != null && !remoteUpdatedAt.isAfter(local.updatedAt)) return;
    _eventRepository.save(Event.fromMap(EntityRowMappers.rowToEventMap(row)));
  }

  @override
  void stopRealtime() {
    for (final channel in _channels) {
      _client.removeChannel(channel);
    }
    _channels.clear();
  }

  @override
  void dispose() {
    stopRealtime();
    _statusController.close();
  }
}
