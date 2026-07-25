import 'package:hive/hive.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for tasks.
///
/// Holds two independent Hive boxes:
/// - the legacy box (`box`, defaulting to `HiveService.tasksBox` /
///   `'mybox'`), read/written via [loadTasks]/[saveTasks] exactly as
///   before Phase 3 — untouched, so `TaskController`/`HomeScreen` keep
///   working unchanged.
/// - the new rich box (`recordsBox`, defaulting to
///   `HiveService.taskRecordsBox` / `'task_records'`), read/written via
///   [getAllTaskRecords]/[getTaskRecordsByProject]/[saveTaskRecord]/
///   [deleteTaskRecord], used by the Projects module onward
///   (Phase 3.2+).
///
/// [migrateLegacyTasksIfNeeded] copies data from the legacy box into the
/// new one once, idempotently, so existing users don't lose tasks when
/// the richer [Task] model takes over — see the doc comment on [Task].
class TaskRepository {
  final Box _box;
  final Box _recordsBox;
  final Box _settingsBox;

  TaskRepository({Box? box, Box? recordsBox, Box? settingsBox})
      : _box = box ?? HiveService.tasksBox,
        _recordsBox = recordsBox ?? HiveService.taskRecordsBox,
        _settingsBox = settingsBox ?? HiveService.settingsBox;

  static const String _tasksKey = 'TODOLIST';
  static const String _migrationFlagKey = 'legacy_tasks_migrated';

  // --- Legacy API (unchanged from before Phase 3) ---

  /// Reads the persisted task list from the legacy box.
  ///
  /// Technical debt carried over unchanged from the original
  /// `tododatabase.loaddata()`: this method is not called anywhere in the
  /// app today, so the legacy task list still never rehydrates into the
  /// old UI on restart. Preserved exactly as-is, per "preserve existing
  /// functionality" — fixing it is a behavior change and belongs in a
  /// dedicated phase, not this one.
  List<Task> loadTasks() {
    final raw = _box.get(_tasksKey);
    if (raw == null) return [];
    return (raw as List)
        .map((item) => Task.fromStorage(item as List<dynamic>))
        .toList();
  }

  void saveTasks(List<Task> tasks) {
    _box.put(_tasksKey, tasks.map((task) => task.toStorage()).toList());
  }

  // --- Rich API (Phase 3 onward) ---

  List<Task> getAllTaskRecords() {
    return _recordsBox.values.map((raw) => Task.fromMap(raw as Map)).toList();
  }

  List<Task> getTaskRecordsByProject(String projectId) {
    return getAllTaskRecords()
        .where((task) => task.projectId == projectId)
        .toList();
  }

  Future<void> saveTaskRecord(Task task) {
    return _recordsBox.put(task.id, task.toMap());
  }

  Future<void> deleteTaskRecord(String taskId) {
    return _recordsBox.delete(taskId);
  }

  /// One-time, idempotent migration from the legacy `[title, isDone]`
  /// format into the new rich [Task] shape. Safe to call on every app
  /// launch — does nothing after the first successful run (tracked via
  /// a flag in the settings box, not the records box, so it can never be
  /// mistaken for a task record by [getAllTaskRecords]).
  Future<void> migrateLegacyTasksIfNeeded() async {
    if (_settingsBox.get(_migrationFlagKey) == true) return;

    final legacyRaw = _box.get(_tasksKey);
    if (legacyRaw != null) {
      final legacyTasks = (legacyRaw as List)
          .map((item) => Task.fromStorage(item as List<dynamic>))
          .toList();

      for (var i = 0; i < legacyTasks.length; i++) {
        final legacy = legacyTasks[i];
        final migrated = Task.create(
          title: legacy.title,
          status: legacy.isDone ? TaskStatus.done : TaskStatus.todo,
          order: i,
        );
        await _recordsBox.put(migrated.id, migrated.toMap());
      }
    }

    await _settingsBox.put(_migrationFlagKey, true);
  }
}
