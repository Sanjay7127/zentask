import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late TaskRepository taskRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_analytics_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    taskRepository = TaskRepository(
      box: legacyBox,
      recordsBox: recordsBox,
      settingsBox: settingsBox,
    );
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AnalyticsEngine engine() => AnalyticsEngine(taskRepository: taskRepository);

  test('projectCompletionRate is 0 for a project with no tasks', () {
    expect(engine().projectCompletionRate('nonexistent'), 0.0);
  });

  test('projectCompletionRate reflects done/total for that project only',
      () async {
    await taskRepository
        .saveTaskRecord(Task.create(title: 'A', projectId: 'p1', status: TaskStatus.done));
    await taskRepository
        .saveTaskRecord(Task.create(title: 'B', projectId: 'p1', status: TaskStatus.todo));
    await taskRepository
        .saveTaskRecord(Task.create(title: 'C', projectId: 'p2', status: TaskStatus.done));

    expect(engine().projectCompletionRate('p1'), 0.5);
    expect(engine().projectCompletionRate('p2'), 1.0);
  });

  test('computeSnapshot reports total/completed counts correctly', () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'A', status: TaskStatus.done));
    await taskRepository.saveTaskRecord(Task.create(title: 'B', status: TaskStatus.done));
    await taskRepository.saveTaskRecord(Task.create(title: 'C', status: TaskStatus.todo));

    final snapshot = engine().computeSnapshot();

    expect(snapshot.totalTasks, 3);
    expect(snapshot.completedTasks, 2);
    expect(snapshot.completionRate, closeTo(2 / 3, 0.0001));
  });

  test('computeSnapshot on an empty task list has 0 completion rate, no crash',
      () {
    final snapshot = engine().computeSnapshot();
    expect(snapshot.totalTasks, 0);
    expect(snapshot.completionRate, 0.0);
    expect(snapshot.productivityScore, 0.0);
  });

  test('productivityScore is higher when completion rate is higher',
      () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'A', status: TaskStatus.done));
    final highScore = engine().computeSnapshot().productivityScore;

    await taskRepository.saveTaskRecord(Task.create(title: 'B', status: TaskStatus.todo));
    await taskRepository.saveTaskRecord(Task.create(title: 'C', status: TaskStatus.todo));
    final lowerScore = engine().computeSnapshot().productivityScore;

    expect(highScore, greaterThan(lowerScore));
  });
}
