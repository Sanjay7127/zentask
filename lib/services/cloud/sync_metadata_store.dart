import 'package:hive/hive.dart';
import 'package:zentask/services/hive_service.dart';

/// Per-entity-type sync bookkeeping backing [CloudSyncEngine]: when each
/// entity type was last pushed/pulled, and a snapshot of which local ids
/// existed as of the last push (used to infer local deletions — see the
/// doc comment on [HiveService.syncMetaBoxName]).
class SyncMetadataStore {
  final Box _box;

  SyncMetadataStore({Box? box}) : _box = box ?? HiveService.syncMetaBox;

  DateTime? lastPushedAt(String entityType) => _readTime('last_pushed_$entityType');

  DateTime? lastPulledAt(String entityType) => _readTime('last_pulled_$entityType');

  Future<void> setLastPushedAt(String entityType, DateTime time) =>
      _box.put('last_pushed_$entityType', time.toIso8601String());

  Future<void> setLastPulledAt(String entityType, DateTime time) =>
      _box.put('last_pulled_$entityType', time.toIso8601String());

  Set<String> knownIds(String entityType) {
    final raw = _box.get('known_ids_$entityType') as List?;
    return raw?.cast<String>().toSet() ?? <String>{};
  }

  Future<void> setKnownIds(String entityType, Set<String> ids) =>
      _box.put('known_ids_$entityType', ids.toList());

  DateTime? _readTime(String key) {
    final raw = _box.get(key) as String?;
    return raw != null ? DateTime.parse(raw) : null;
  }
}
