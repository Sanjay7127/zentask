import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/calendar_controller.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late Box eventsBox;
  late Box projectsBox;
  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;
  late TimelineEngine engine;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_calendar_controller_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    eventsBox = await Hive.openBox('events_test');
    projectsBox = await Hive.openBox('projects_test');
    taskRepository = TaskRepository(
      box: legacyBox,
      recordsBox: recordsBox,
      settingsBox: settingsBox,
    );
    projectRepository = ProjectRepository(box: projectsBox);
    engine = TimelineEngine(
      taskRepository: taskRepository,
      eventRepository: EventRepository(box: eventsBox),
    );
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await eventsBox.deleteFromDisk();
    await projectsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  CalendarController controller({DateTime? initialDate}) => CalendarController(
        timelineEngine: engine,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        initialDate: initialDate,
      );

  test('defaults to month view focused on the initial date', () {
    final c = controller(initialDate: DateTime(2026, 3, 15));
    expect(c.viewMode, CalendarViewMode.month);
    expect(c.focusedMonth, DateTime(2026, 3));
    expect(c.selectedDate, DateTime(2026, 3, 15));
  });

  test('goToPrevious/goToNext in month view shift by a month', () {
    final c = controller(initialDate: DateTime(2026, 3, 15));
    c.goToNext();
    expect(c.focusedMonth, DateTime(2026, 4));
    c.goToPrevious();
    c.goToPrevious();
    expect(c.focusedMonth, DateTime(2026, 2));
  });

  test('goToPrevious/goToNext in agenda view shift the selected date by a day',
      () {
    final c = controller(initialDate: DateTime(2026, 3, 15));
    c.setViewMode(CalendarViewMode.agenda);
    c.goToNext();
    expect(c.selectedDate, DateTime(2026, 3, 16));
    c.goToPrevious();
    c.goToPrevious();
    expect(c.selectedDate, DateTime(2026, 3, 14));
  });

  test('goToToday resets to today\'s date and month', () {
    final c = controller(initialDate: DateTime(2020, 1, 1));
    c.goToToday();
    final now = DateTime.now();
    expect(c.selectedDate, DateTime(now.year, now.month, now.day));
    expect(c.focusedMonth, DateTime(now.year, now.month));
  });

  test('selectDateAndShowAgenda selects the date and switches view', () {
    final c = controller(initialDate: DateTime(2026, 3, 1));
    c.selectDateAndShowAgenda(DateTime(2026, 3, 20));
    expect(c.selectedDate, DateTime(2026, 3, 20));
    expect(c.viewMode, CalendarViewMode.agenda);
  });

  test('entriesForDay returns only entries on that exact day', () async {
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Due today', dueDate: DateTime(2026, 3, 10, 9)),
    );
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Due tomorrow', dueDate: DateTime(2026, 3, 11, 9)),
    );
    final c = controller(initialDate: DateTime(2026, 3, 10));

    final entries = c.entriesForDay(DateTime(2026, 3, 10));

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Due today');
  });

  test('entriesByDayForMonthGrid groups entries by day across the grid',
      () async {
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Mid-month', dueDate: DateTime(2026, 3, 15)),
    );
    final c = controller(initialDate: DateTime(2026, 3, 1));

    final grouped = c.entriesByDayForMonthGrid(DateTime(2026, 3));

    expect(grouped[DateTime(2026, 3, 15)], hasLength(1));
  });

  test('isEntryCompleted reflects the underlying task\'s isDone', () async {
    await taskRepository.saveTaskRecord(Task.create(
      title: 'Done task',
      dueDate: DateTime(2026, 3, 10),
      status: TaskStatus.done,
    ));
    final c = controller();
    final entry = c.entriesForDay(DateTime(2026, 3, 10)).single;

    expect(c.isEntryCompleted(entry), true);
  });

  test('isEntryOverdue is true only for a past, not-done task due date',
      () async {
    final past = DateTime.now().subtract(const Duration(days: 3));
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Overdue', dueDate: past),
    );
    final c = controller();
    final entry = c.entriesForDay(past).single;

    expect(c.isEntryOverdue(entry), true);
  });

  test('isEntryOverdue is false once the task is done', () async {
    final past = DateTime.now().subtract(const Duration(days: 3));
    await taskRepository.saveTaskRecord(Task.create(
      title: 'Overdue but done',
      dueDate: past,
      status: TaskStatus.done,
    ));
    final c = controller();
    final entry = c.entriesForDay(past).single;

    expect(c.isEntryOverdue(entry), false);
  });

  test('colorValueForEntry returns the task\'s project color', () async {
    final project = Project.create(title: 'Colorful', colorValue: 0xFF123456);
    await projectRepository.save(project);
    await taskRepository.saveTaskRecord(Task.create(
      title: 'Project task',
      projectId: project.id,
      dueDate: DateTime(2026, 3, 10),
    ));
    final c = controller();
    final entry = c.entriesForDay(DateTime(2026, 3, 10)).single;

    expect(c.colorValueForEntry(entry), 0xFF123456);
  });

  test('colorValueForEntry is null for a task with no project', () async {
    await taskRepository.saveTaskRecord(
      Task.create(title: 'No project', dueDate: DateTime(2026, 3, 10)),
    );
    final c = controller();
    final entry = c.entriesForDay(DateTime(2026, 3, 10)).single;

    expect(c.colorValueForEntry(entry), isNull);
  });
}
