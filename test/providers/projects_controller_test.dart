import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';

void main() {
  late Directory tempDir;
  late Box projectsBox;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late ProjectRepository projectRepository;
  late TaskRepository taskRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_projects_ctrl_test');
    Hive.init(tempDir.path);
    projectsBox = await Hive.openBox('projects_test');
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');

    projectRepository = ProjectRepository(box: projectsBox);
    taskRepository = TaskRepository(
      box: legacyBox,
      recordsBox: recordsBox,
      settingsBox: settingsBox,
    );
  });

  tearDown(() async {
    await projectsBox.deleteFromDisk();
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ProjectsController controller() => ProjectsController(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        analyticsEngine: AnalyticsEngine(taskRepository: taskRepository),
      );

  test('starts empty when there are no projects', () {
    final c = controller();
    expect(c.totalProjectCount, 0);
    expect(c.activeProjectCount, 0);
    expect(c.archivedProjectCount, 0);
    expect(c.averageActiveCompletion, 0.0);
  });

  test('createProject adds a project and notifies listeners', () async {
    final c = controller();
    var notified = false;
    c.addListener(() => notified = true);

    await c.createProject(title: 'ZenTask Hackathon', priority: TaskPriority.high);

    expect(c.totalProjectCount, 1);
    expect(c.projects.single.title, 'ZenTask Hackathon');
    expect(c.projects.single.priority, TaskPriority.high);
    expect(notified, true);
  });

  test('archiveProject/restoreProject move a project between the two lists',
      () async {
    final c = controller();
    await c.createProject(title: 'Old project');
    final id = c.projects.single.id;

    await c.archiveProject(id);
    expect(c.activeProjectCount, 0);
    expect(c.archivedProjectCount, 1);

    await c.restoreProject(id);
    expect(c.activeProjectCount, 1);
    expect(c.archivedProjectCount, 0);
  });

  test('deleteProject removes the project and unassigns its tasks',
      () async {
    final c = controller();
    await c.createProject(title: 'To delete');
    final project = c.projects.single;

    await taskRepository.saveTaskRecord(
      Task.create(title: 'orphaned task', projectId: project.id),
    );

    await c.deleteProject(project.id);

    expect(c.totalProjectCount, 0);
    final task = taskRepository.getAllTaskRecords().single;
    expect(task.projectId, isNull);
    expect(task.title, 'orphaned task'); // task itself is preserved
  });

  test('completedTaskCountFor/totalTaskCountFor/completionRateFor are scoped '
      'to one project', () async {
    final c = controller();
    await c.createProject(title: 'P1');
    await c.createProject(title: 'P2');
    final p1 = c.projects[0];
    final p2 = c.projects[1];

    await taskRepository.saveTaskRecord(
        Task.create(title: 'a', projectId: p1.id, status: TaskStatus.done));
    await taskRepository.saveTaskRecord(
        Task.create(title: 'b', projectId: p1.id, status: TaskStatus.todo));
    await taskRepository.saveTaskRecord(
        Task.create(title: 'c', projectId: p2.id, status: TaskStatus.done));

    expect(c.totalTaskCountFor(p1.id), 2);
    expect(c.completedTaskCountFor(p1.id), 1);
    expect(c.completionRateFor(p1.id), 0.5);
    expect(c.completionRateFor(p2.id), 1.0);
  });

  test('nextUpcomingTaskFor returns the soonest not-done task with a due date',
      () async {
    final c = controller();
    await c.createProject(title: 'P1');
    final project = c.projects.single;

    await taskRepository.saveTaskRecord(Task.create(
        title: 'later', projectId: project.id, dueDate: DateTime(2026, 12, 1)));
    await taskRepository.saveTaskRecord(Task.create(
        title: 'sooner', projectId: project.id, dueDate: DateTime(2026, 1, 1)));
    await taskRepository.saveTaskRecord(Task.create(
        title: 'done already',
        projectId: project.id,
        dueDate: DateTime(2025, 1, 1),
        status: TaskStatus.done));

    expect(c.nextUpcomingTaskFor(project.id)?.title, 'sooner');
  });

  test('upcomingDeadlines only returns tasks due within the window',
      () async {
    final c = controller();
    final now = DateTime.now();
    await taskRepository.saveTaskRecord(
        Task.create(title: 'within window', dueDate: now.add(const Duration(days: 3))));
    await taskRepository.saveTaskRecord(
        Task.create(title: 'too far', dueDate: now.add(const Duration(days: 30))));
    await taskRepository.saveTaskRecord(
        Task.create(title: 'already done',
            dueDate: now.add(const Duration(days: 2)), status: TaskStatus.done));

    final upcoming = c.upcomingDeadlines(withinDays: 7);
    expect(upcoming.length, 1);
    expect(upcoming.single.title, 'within window');
  });

  group('visibleProjects (Phase 9)', () {
    test('search matches title case-insensitively', () async {
      final c = controller();
      await c.createProject(title: 'ZenTask Hackathon');
      await c.createProject(title: 'Personal Errands');

      final results = c.visibleProjects(searchQuery: 'hackathon');
      expect(results.single.title, 'ZenTask Hackathon');
    });

    test('filter: active excludes archived and fully-completed projects',
        () async {
      final c = controller();
      await c.createProject(title: 'Active');
      await c.createProject(title: 'Archived');
      await c.createProject(title: 'Completed');
      final active = c.projects[0];
      final archived = c.projects[1];
      final completed = c.projects[2];

      await c.archiveProject(archived.id);
      await taskRepository.saveTaskRecord(Task.create(
          title: 't', projectId: completed.id, status: TaskStatus.done));
      await taskRepository.saveTaskRecord(
          Task.create(title: 't2', projectId: active.id));

      final results =
          c.visibleProjects(filter: ProjectStatusFilter.active);
      expect(results.map((p) => p.title), ['Active']);
    });

    test('filter: completed requires at least one task, all done',
        () async {
      final c = controller();
      await c.createProject(title: 'Empty project');
      await c.createProject(title: 'Completed project');
      final empty = c.projects[0];
      final completed = c.projects[1];

      await taskRepository.saveTaskRecord(Task.create(
          title: 't', projectId: completed.id, status: TaskStatus.done));

      final results = c.visibleProjects(filter: ProjectStatusFilter.completed);
      expect(results.map((p) => p.title), ['Completed project']);
      expect(results.any((p) => p.id == empty.id), false);
    });

    test('filter: archived only returns archived projects', () async {
      final c = controller();
      await c.createProject(title: 'Active');
      await c.createProject(title: 'Archived');
      await c.archiveProject(c.projects[1].id);

      final results = c.visibleProjects(filter: ProjectStatusFilter.archived);
      expect(results.map((p) => p.title), ['Archived']);
    });

    test('sort by name is alphabetical, case-insensitive', () async {
      final c = controller();
      await c.createProject(title: 'banana');
      await c.createProject(title: 'Apple');
      await c.createProject(title: 'cherry');

      final results = c.visibleProjects(sort: ProjectSortOption.name);
      expect(results.map((p) => p.title), ['Apple', 'banana', 'cherry']);
    });

    test('sort by progress ranks highest completion first', () async {
      final c = controller();
      await c.createProject(title: 'Half done');
      await c.createProject(title: 'Fully done');
      final half = c.projects[0];
      final full = c.projects[1];

      await taskRepository.saveTaskRecord(Task.create(
          title: 'a', projectId: half.id, status: TaskStatus.done));
      await taskRepository.saveTaskRecord(
          Task.create(title: 'b', projectId: half.id));
      await taskRepository.saveTaskRecord(Task.create(
          title: 'c', projectId: full.id, status: TaskStatus.done));

      final results = c.visibleProjects(sort: ProjectSortOption.progress);
      expect(results.map((p) => p.title), ['Fully done', 'Half done']);
    });

    test('sort by dueDate puts projects with no upcoming task last',
        () async {
      final c = controller();
      await c.createProject(title: 'No due date');
      await c.createProject(title: 'Has due date');
      final noDue = c.projects[0];
      final hasDue = c.projects[1];

      await taskRepository.saveTaskRecord(Task.create(
          title: 't', projectId: hasDue.id, dueDate: DateTime(2026, 6, 1)));

      final results = c.visibleProjects(sort: ProjectSortOption.dueDate);
      expect(results.map((p) => p.title), ['Has due date', 'No due date']);
      expect(noDue.title, 'No due date'); // sanity check on fixture setup
    });

    test('sort by recentlyUpdated puts the most recently saved project first',
        () async {
      final c = controller();
      await c.createProject(title: 'First');
      await c.createProject(title: 'Second');
      final first = c.projects[0];

      // Re-saving "First" bumps its updatedAt to now, making it the most
      // recently updated even though it was created first.
      await c.updateProject(first.copyWith(description: 'edited'));

      final results = c.visibleProjects(sort: ProjectSortOption.recentlyUpdated);
      expect(results.first.title, 'First');
    });
  });
}
