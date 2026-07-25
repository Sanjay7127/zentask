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
