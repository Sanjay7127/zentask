import 'package:hive/hive.dart';
import 'package:zentask/models/focus_session.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for [FocusSession]s.
class FocusSessionRepository {
  final Box _box;

  FocusSessionRepository({Box? box}) : _box = box ?? HiveService.focusSessionsBox;

  List<FocusSession> getAll() =>
      _box.values.map((raw) => FocusSession.fromMap(raw as Map)).toList();

  Future<void> save(FocusSession session) =>
      _box.put(session.id, session.toMap());
}
