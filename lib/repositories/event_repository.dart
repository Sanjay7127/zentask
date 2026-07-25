import 'package:hive/hive.dart';
import 'package:zentask/models/event.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for events (competitions, hackathons, workshops, etc).
class EventRepository {
  final Box _box;

  EventRepository({Box? box}) : _box = box ?? HiveService.eventsBox;

  List<Event> getAll() {
    return _box.values.map((raw) => Event.fromMap(raw as Map)).toList();
  }

  Event? getById(String id) {
    final raw = _box.get(id);
    return raw != null ? Event.fromMap(raw as Map) : null;
  }

  Future<void> save(Event event) {
    return _box.put(event.id, event.toMap());
  }

  Future<void> delete(String id) {
    return _box.delete(id);
  }
}
