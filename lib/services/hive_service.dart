import 'package:hive_flutter/hive_flutter.dart';

import 'package:zentask/services/security/secure_key_service.dart';

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

  /// Per-entity-type sync bookkeeping (Phase 11): last-pushed/pulled
  /// timestamps and a snapshot of locally-known ids as of the last
  /// push. [CloudSyncEngine] diffs the current local id set against
  /// that snapshot to infer local deletions — deliberately **not** a
  /// hook added to `ProjectRepository`/`TaskRepository`/etc.'s `delete`
  /// methods, which would mean every existing test exercising those
  /// repositories now needs this box open too. Diffing known-ids
  /// against current-ids gets the same answer without touching any
  /// existing repository at all.
  static const String syncMetaBoxName = 'sync_meta';

  // --- Phase 12 feature boxes ---
  static const String labelsBoxName = 'labels';
  static const String habitsBoxName = 'habits';
  static const String habitCompletionsBoxName = 'habit_completions';
  static const String goalsBoxName = 'goals';
  static const String achievementsBoxName = 'achievements';
  static const String focusSessionsBoxName = 'focus_sessions';
  static const String savedFiltersBoxName = 'saved_filters';

  /// All box names opened by [init], in one place so
  /// `EncryptionMigrationService` can re-open the exact same set with a
  /// different cipher without duplicating this list.
  static const List<String> allBoxNames = [
    tasksBoxName,
    taskRecordsBoxName,
    projectsBoxName,
    eventsBoxName,
    settingsBoxName,
    bookmarksBoxName,
    syncMetaBoxName,
    labelsBoxName,
    habitsBoxName,
    habitCompletionsBoxName,
    goalsBoxName,
    achievementsBoxName,
    focusSessionsBoxName,
    savedFiltersBoxName,
  ];

  /// Opens every box in [allBoxNames], transparently encrypting all of
  /// them with the stored key from [SecureKeyService] if one exists.
  ///
  /// A fresh install has no stored key, so this opens boxes exactly as
  /// before (zero risk to existing unencrypted data). Once a key has
  /// been generated (see `HiveEncryptionService.enableEncryption`),
  /// every subsequent app start transparently opens boxes encrypted —
  /// no other code needs to know encryption is active.
  static Future<void> init({SecureKeyService? secureKeyService}) async {
    await Hive.initFlutter();
    final keyService = secureKeyService ?? SecureKeyService();
    final key = await keyService.getKey();
    final cipher = key != null ? HiveAesCipher(key) : null;
    await Future.wait([
      for (final name in allBoxNames) Hive.openBox(name, encryptionCipher: cipher),
    ]);
  }

  static Box get tasksBox => Hive.box(tasksBoxName);
  static Box get taskRecordsBox => Hive.box(taskRecordsBoxName);
  static Box get projectsBox => Hive.box(projectsBoxName);
  static Box get eventsBox => Hive.box(eventsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box get bookmarksBox => Hive.box(bookmarksBoxName);
  static Box get syncMetaBox => Hive.box(syncMetaBoxName);
  static Box get labelsBox => Hive.box(labelsBoxName);
  static Box get habitsBox => Hive.box(habitsBoxName);
  static Box get habitCompletionsBox => Hive.box(habitCompletionsBoxName);
  static Box get goalsBox => Hive.box(goalsBoxName);
  static Box get achievementsBox => Hive.box(achievementsBoxName);
  static Box get focusSessionsBox => Hive.box(focusSessionsBoxName);
  static Box get savedFiltersBox => Hive.box(savedFiltersBoxName);
}
