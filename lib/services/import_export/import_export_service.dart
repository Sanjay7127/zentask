import 'dart:convert';

import 'package:zentask/models/event.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';

/// Contract for exporting/importing all of a user's ZenTask data as a
/// single portable JSON string.
///
/// Deliberately works with a `String`, not a file — writing that string
/// to disk (or sharing it, or picking one to import) is a UI/platform
/// concern for a future phase. This keeps the actual export/import
/// logic fully platform-agnostic and testable everywhere, including web,
/// where `dart:io` file access isn't available.
abstract class ImportExportService {
  Future<String> exportToJson();
  Future<void> importFromJson(String json);
}

/// JSON shape: `{version, exportedAt, projects[], tasks[], events[]}`,
/// each entry using the same `toMap`/`fromMap` shapes already used for
/// Hive storage — so this is also, incidentally, a working reference
/// for what a future cloud-sync payload could look like.
class JsonImportExportService implements ImportExportService {
  static const int _formatVersion = 1;

  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;
  final EventRepository _eventRepository;

  JsonImportExportService({
    ProjectRepository? projectRepository,
    TaskRepository? taskRepository,
    EventRepository? eventRepository,
  })  : _projectRepository = projectRepository ?? ProjectRepository(),
        _taskRepository = taskRepository ?? TaskRepository(),
        _eventRepository = eventRepository ?? EventRepository();

  @override
  Future<String> exportToJson() async {
    final data = {
      'version': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'projects': _projectRepository.getAll().map((p) => p.toMap()).toList(),
      'tasks':
          _taskRepository.getAllTaskRecords().map((t) => t.toMap()).toList(),
      'events': _eventRepository.getAll().map((e) => e.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  @override
  Future<void> importFromJson(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;

    for (final raw in (data['projects'] as List? ?? const [])) {
      await _projectRepository.save(Project.fromMap(raw as Map));
    }
    for (final raw in (data['tasks'] as List? ?? const [])) {
      await _taskRepository.saveTaskRecord(Task.fromMap(raw as Map));
    }
    for (final raw in (data['events'] as List? ?? const [])) {
      await _eventRepository.save(Event.fromMap(raw as Map));
    }
  }
}
