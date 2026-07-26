import 'package:hive/hive.dart';
import 'package:zentask/models/goal.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for [Goal]s.
class GoalRepository {
  final Box _box;

  GoalRepository({Box? box}) : _box = box ?? HiveService.goalsBox;

  List<Goal> getAll() =>
      _box.values.map((raw) => Goal.fromMap(raw as Map)).toList();

  Goal? getById(String id) {
    final raw = _box.get(id);
    return raw != null ? Goal.fromMap(raw as Map) : null;
  }

  Future<void> save(Goal goal) => _box.put(goal.id, goal.toMap());

  Future<void> delete(String id) => _box.delete(id);
}
