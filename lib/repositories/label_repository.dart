import 'package:hive/hive.dart';
import 'package:zentask/models/label.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for [Label]s. Mirrors [ProjectRepository]'s shape.
class LabelRepository {
  final Box _box;

  LabelRepository({Box? box}) : _box = box ?? HiveService.labelsBox;

  List<Label> getAll() =>
      _box.values.map((raw) => Label.fromMap(raw as Map)).toList();

  Label? getById(String id) {
    final raw = _box.get(id);
    return raw != null ? Label.fromMap(raw as Map) : null;
  }

  Future<void> save(Label label) => _box.put(label.id, label.toMap());

  Future<void> delete(String id) => _box.delete(id);
}
