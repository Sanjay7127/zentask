import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/event.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/search/advanced_search_service.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late Box projectsBox;
  late Box eventsBox;
  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;
  late EventRepository eventRepository;
  late AdvancedSearchService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_advanced_search_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    projectsBox = await Hive.openBox('projects_test');
    eventsBox = await Hive.openBox('events_test');

    taskRepository = TaskRepository(box: legacyBox, recordsBox: recordsBox, settingsBox: settingsBox);
    projectRepository = ProjectRepository(box: projectsBox);
    eventRepository = EventRepository(box: eventsBox);
    service = AdvancedSearchService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      eventRepository: eventRepository,
    );
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await projectsBox.deleteFromDisk();
    await eventsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('empty query returns no results', () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'Buy milk'));
    expect(service.search(''), isEmpty);
    expect(service.search('   '), isEmpty);
  });

  test('matches a task by title, case-insensitively', () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'Buy Milk'));

    final results = service.search('milk');

    expect(results, hasLength(1));
    expect(results.single.type, SearchResultType.task);
    expect(results.single.title, 'Buy Milk');
  });

  test('matches a task by description or tag when title doesn\'t match', () async {
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Groceries', description: 'pick up eggs'),
    );
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Chores', tags: const ['urgent']),
    );

    expect(service.search('eggs'), hasLength(1));
    expect(service.search('urgent'), hasLength(1));
  });

  test('filters tasks by priority', () async {
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Ship report', priority: TaskPriority.high),
    );
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Ship dishes', priority: TaskPriority.low),
    );

    final results = service.search('ship', priority: TaskPriority.high);

    expect(results, hasLength(1));
    expect(results.single.title, 'Ship report');
  });

  test('filters tasks by due date range, excluding tasks with no due date', () async {
    final inRange = DateTime(2026, 3, 15);
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Deadline task', dueDate: inRange),
    );
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Deadline task without date'),
    );

    final results = service.search(
      'deadline',
      dueAfter: DateTime(2026, 3, 1),
      dueBefore: DateTime(2026, 3, 31),
    );

    expect(results, hasLength(1));
    expect(results.single.title, 'Deadline task');
  });

  test('matches projects and events alongside tasks', () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'Launch prep'));
    await projectRepository.save(Project.create(title: 'Launch website'));
    await eventRepository.save(Event.create(title: 'Launch Hackathon'));

    final results = service.search('launch');

    expect(results, hasLength(3));
    expect(results.map((r) => r.type), containsAll(SearchResultType.values));
  });
}
