import 'package:hive/hive.dart';
import 'package:zentask/services/hive_service.dart';

/// Generic bookmark store, keyed by `'<entityType>:<entityId>'`.
///
/// Not yet wired to anything — [Event] currently carries its own
/// `bookmarked` field for simplicity (see the doc comment on
/// `Event.bookmarked`). This repository exists so future entity types
/// (projects, tasks) can be bookmarked without each needing their own
/// flag, and so the Events module (Phase 3.4) has a real store to
/// reconcile `Event.bookmarked` against.
class BookmarksRepository {
  final Box _box;

  BookmarksRepository({Box? box}) : _box = box ?? HiveService.bookmarksBox;

  bool isBookmarked(String entityType, String entityId) {
    return _box.get('$entityType:$entityId') == true;
  }

  /// Every bookmarked `'<entityType>:<entityId>'` key currently stored —
  /// used by [CloudSyncEngine] to push the full bookmark set (Phase 11).
  Set<String> getAllKeys() => _box.keys.cast<String>().toSet();

  /// Marks [key] (a `'<entityType>:<entityId>'` pair) as bookmarked
  /// without needing to split it back into its two parts first — used
  /// when pulling bookmark keys down from the cloud (Phase 11).
  Future<void> markKeyBookmarked(String key) => _box.put(key, true);

  Future<void> setBookmarked(
    String entityType,
    String entityId,
    bool bookmarked,
  ) {
    final key = '$entityType:$entityId';
    if (bookmarked) {
      return _box.put(key, true);
    }
    return _box.delete(key);
  }
}
