import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/project_detail_controller.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

import '../test_utils/fake_reminder_scheduler.dart';

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
  late FakeReminderScheduler reminderScheduler;
  late Project project;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_detail_ctrl_test');
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
    reminderScheduler = FakeReminderScheduler();

    project = Project.create(title: 'Test Project');
    await projectRepository.save(project);
  });

  tearDown(() async {
    await projectsBox.deleteFromDisk();
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await eventsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProjectDetailController controller() => ProjectDetailController(
        projectId: project.id,
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        analyticsEngine: AnalyticsEngine(taskRepository: taskRepository),
        timelineEngine: TimelineEngine(
          taskRepository: taskRepository,
          eventRepository: eventRepository,
        ),
        reminderScheduler: reminderScheduler,
      );

  test('loads the project and starts with no tasks', () {
    final c = controller();
    expect(c.project?.title, 'Test Project');
    expect(c.tasks, isEmpty);
    expect(c.totalTaskCount, 0);
  });

  test('createTask adds a task scoped to this project', () async {
    final c = controller();
    await c.createTask(title: 'Submit demo', priority: TaskPriority.urgent);

    expect(c.tasks.single.title, 'Submit demo');
    expect(c.tasks.single.projectId, project.id);
    expect(c.totalTaskCount, 1);
  });

  test('createTask with a future reminder schedules it', () async {
    final c = controller();
    await c.createTask(
      title: 'Prep slides',
      reminder: DateTime.now().add(const Duration(days: 1)),
    );

    expect(reminderScheduler.scheduled, [c.tasks.single.id]);
  });

  test('createTask without a reminder does not schedule anything', () async {
    final c = controller();
    await c.createTask(title: 'No reminder here');
    expect(reminderScheduler.scheduled, isEmpty);
  });

  test('updateTask(reminder: null) alone leaves the reminder unchanged '
      '(copyWith null-coalescing convention)', () async {
    final c = controller();
    await c.createTask(
      title: 'Has reminder',
      reminder: DateTime.now().add(const Duration(days: 1)),
    );
    final task = c.tasks.single;
    expect(reminderScheduler.scheduled, [task.id]);

    await c.updateTask(task, reminder: null);
    expect(reminderScheduler.cancelled, isEmpty);
    expect(c.tasks.single.reminder, isNotNull);
  });

  test('updateTask(clearReminder: true) actually clears and cancels it',
      () async {
    final c = controller();
    await c.createTask(
      title: 'Has reminder',
      reminder: DateTime.now().add(const Duration(days: 1)),
    );
    final task = c.tasks.single;
    expect(reminderScheduler.scheduled, [task.id]);

    await c.updateTask(task, clearReminder: true);

    expect(c.tasks.single.reminder, isNull);
    expect(reminderScheduler.cancelled, contains(task.id));
  });

  test('updateTask(clearDueDate: true) actually clears the due date',
      () async {
    final c = controller();
    await c.createTask(title: 'Has due date', dueDate: DateTime(2026, 12, 1));
    final task = c.tasks.single;

    await c.updateTask(task, clearDueDate: true);

    expect(c.tasks.single.dueDate, isNull);
  });

  test('updateTask marking a task done cancels its reminder', () async {
    final c = controller();
    await c.createTask(
      title: 'Has reminder',
      reminder: DateTime.now().add(const Duration(days: 1)),
    );
    final task = c.tasks.single;

    await c.updateTask(task, isDone: true);
    expect(reminderScheduler.cancelled, contains(task.id));
  });

  test('deleteTask removes the task and cancels its reminder', () async {
    final c = controller();
    await c.createTask(title: 'To delete');
    final task = c.tasks.single;

    await c.deleteTask(task);

    expect(c.tasks, isEmpty);
    expect(reminderScheduler.cancelled, contains(task.id));
  });

  test('moveTask reassigns projectId to another project', () async {
    final otherProject = Project.create(title: 'Other');
    await projectRepository.save(otherProject);

    final c = controller();
    await c.createTask(title: 'Movable');
    final task = c.tasks.single;

    await c.moveTask(task, otherProject.id);

    expect(c.tasks, isEmpty); // no longer in this project's list
    final moved = taskRepository.getTaskRecordsByProject(otherProject.id).single;
    expect(moved.projectId, otherProject.id);
  });

  test('moveTask with null unassigns the task from any project', () async {
    final c = controller();
    await c.createTask(title: 'Movable');
    final task = c.tasks.single;

    await c.moveTask(task, null);

    expect(c.tasks, isEmpty);
    final unassigned = taskRepository.getAllTaskRecords().single;
    expect(unassigned.projectId, isNull);
  });

  test('completionRate/overdueTaskCount reflect the project\'s own tasks',
      () async {
    final c = controller();
    await c.createTask(title: 'done', priority: TaskPriority.low);
    await c.updateTask(c.tasks.single, isDone: true);
    await c.createTask(
        title: 'overdue', dueDate: DateTime.now().subtract(const Duration(days: 1)));

    expect(c.completionRate, 0.5);
    expect(c.overdueTaskCount, 1);
  });

  test('deleteProject unassigns all tasks, cancels reminders, clears state',
      () async {
    final c = controller();
    await c.createTask(
      title: 'a',
      reminder: DateTime.now().add(const Duration(days: 1)),
    );
    final taskId = c.tasks.single.id;

    await c.deleteProject();

    expect(c.project, isNull);
    expect(c.tasks, isEmpty);
    expect(reminderScheduler.cancelled, contains(taskId));
    expect(projectRepository.getById(project.id), isNull);
    final orphan = taskRepository.getAllTaskRecords().single;
    expect(orphan.projectId, isNull);
  });
}
