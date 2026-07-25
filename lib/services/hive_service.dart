import 'package:hive_flutter/hive_flutter.dart';

/// Initializes Hive and opens all of the app's storage boxes.
///
/// Extracted from `main()` so storage bootstrapping is separate from the
/// app entrypoint/widget tree.
///
/// **Naming note (Phase 3):** `tasksBoxName`/`tasksBox` still refer to
/// the *original* box (`'mybox'`) from before Phase 3 — left unchanged
/// so `TaskRepository()`'s existing default constructor keeps resolving
/// to the same box it always has. The new Phase 3 rich-task storage
/// lives in the differently-named `taskRecordsBox` (`'task_records'`)
/// specifically to avoid quietly repointing that existing default at a
/// different box.
class HiveService {
  HiveService._();

  static const String tasksBoxName = 'mybox';
  static const String taskRecordsBoxName = 'task_records';
  static const String projectsBoxName = 'projects';
  static const String eventsBoxName = 'events';
  static const String settingsBoxName = 'settings';
  static const String bookmarksBoxName = 'bookmarks';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(tasksBoxName),
      Hive.openBox(taskRecordsBoxName),
      Hive.openBox(projectsBoxName),
      Hive.openBox(eventsBoxName),
      Hive.openBox(settingsBoxName),
      Hive.openBox(bookmarksBoxName),
    ]);
  }

  static Box get tasksBox => Hive.box(tasksBoxName);
  static Box get taskRecordsBox => Hive.box(taskRecordsBoxName);
  static Box get projectsBox => Hive.box(projectsBoxName);
  static Box get eventsBox => Hive.box(eventsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box get bookmarksBox => Hive.box(bookmarksBoxName);
}
