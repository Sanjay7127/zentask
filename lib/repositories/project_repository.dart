import 'package:hive/hive.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for projects. Mirrors [TaskRepository]'s rich-record
/// API shape for consistency across the data layer.
class ProjectRepository {
  final Box _box;

  ProjectRepository({Box? box}) : _box = box ?? HiveService.projectsBox;

  List<Project> getAll() {
    return _box.values.map((raw) => Project.fromMap(raw as Map)).toList();
  }

  Project? getById(String id) {
    final raw = _box.get(id);
    return raw != null ? Project.fromMap(raw as Map) : null;
  }

  Future<void> save(Project project) {
    return _box.put(project.id, project.toMap());
  }

  Future<void> delete(String id) {
    return _box.delete(id);
  }
}
