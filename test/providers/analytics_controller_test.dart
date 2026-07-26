import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/analytics_controller.dart';
import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late Box projectsBox;
  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_analytics_controller_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    projectsBox = await Hive.openBox('projects_test');
    taskRepository = TaskRepository(
      box: legacyBox,
      recordsBox: recordsBox,
      settingsBox: settingsBox,
    );
    projectRepository = ProjectRepository(box: projectsBox);
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await projectsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AnalyticsController controller() => AnalyticsController(
        analyticsEngine: AnalyticsEngine(taskRepository: taskRepository),
        projectsController: ProjectsController(
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          analyticsEngine: AnalyticsEngine(taskRepository: taskRepository),
        ),
      );

  test('snapshot reflects task completion state', () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'A', status: TaskStatus.done));
    await taskRepository.saveTaskRecord(Task.create(title: 'B', status: TaskStatus.todo));

    final snapshot = controller().snapshot;

    expect(snapshot.totalTasks, 2);
    expect(snapshot.completedTasks, 1);
  });

  test('activeProjectCount and finishedProjectCount delegate to ProjectsController',
      () async {
    final active = Project.create(title: 'Active');
    final finished = Project.create(title: 'Finished');
    await projectRepository.save(active);
    await projectRepository.save(finished);
    await taskRepository.saveTaskRecord(
      Task.create(title: 'T', projectId: finished.id, status: TaskStatus.done),
    );

    final c = controller();

    expect(c.activeProjectCount, 2);
    expect(c.finishedProjectCount, 1);
  });

  test('weeklyActivity and monthlyActivity return fixed-length series', () {
    final c = controller();

    expect(c.weeklyActivity, hasLength(7));
    expect(c.monthlyActivity, hasLength(5));
  });

  test('currentStreak and longestStreak default to 0 with no history', () {
    final c = controller();

    expect(c.currentStreak, 0);
    expect(c.longestStreak, 0);
  });
}
