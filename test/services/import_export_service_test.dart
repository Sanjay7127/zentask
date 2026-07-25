import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/event.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/import_export/import_export_service.dart';

void main() {
  late Directory tempDir;
  late Box projectsBox;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late Box eventsBox;
  late ProjectRepository projectRepository;
  late TaskRepository taskRepository;
  late EventRepository eventRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_import_export_test');
    Hive.init(tempDir.path);
    projectsBox = await Hive.openBox('projects_test');
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    eventsBox = await Hive.openBox('events_test');

    projectRepository = ProjectRepository(box: projectsBox);
    taskRepository = TaskRepository(
      box: legacyBox,
      recordsBox: recordsBox,
      settingsBox: settingsBox,
    );
    eventRepository = EventRepository(box: eventsBox);
  });

  tearDown(() async {
    await projectsBox.deleteFromDisk();
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await eventsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  JsonImportExportService service() => JsonImportExportService(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        eventRepository: eventRepository,
      );

  test('exports an empty dataset without crashing', () async {
    final json = await service().exportToJson();
    expect(json, contains('"projects":[]'));
    expect(json, contains('"tasks":[]'));
    expect(json, contains('"events":[]'));
  });

  test('round-trips projects, tasks, and events through export/import',
      () async {
    final project = Project.create(title: 'ZenTask Hackathon');
    final task = Task.create(title: 'Submit demo', projectId: project.id);
    final event = Event.create(title: 'Global Hack Week');

    await projectRepository.save(project);
    await taskRepository.saveTaskRecord(task);
    await eventRepository.save(event);

    final exported = await service().exportToJson();

    // Simulate a fresh install: wipe everything, then import.
    await projectsBox.clear();
    await recordsBox.clear();
    await eventsBox.clear();

    expect(projectRepository.getAll(), isEmpty);
    expect(taskRepository.getAllTaskRecords(), isEmpty);
    expect(eventRepository.getAll(), isEmpty);

    await service().importFromJson(exported);

    final restoredProjects = projectRepository.getAll();
    final restoredTasks = taskRepository.getAllTaskRecords();
    final restoredEvents = eventRepository.getAll();

    expect(restoredProjects.single.title, 'ZenTask Hackathon');
    expect(restoredTasks.single.title, 'Submit demo');
    expect(restoredTasks.single.projectId, project.id);
    expect(restoredEvents.single.title, 'Global Hack Week');
  });

  test('importFromJson tolerates a payload missing optional sections',
      () async {
    await service().importFromJson('{"version": 1}');
    expect(projectRepository.getAll(), isEmpty);
    expect(taskRepository.getAllTaskRecords(), isEmpty);
    expect(eventRepository.getAll(), isEmpty);
  });
}
