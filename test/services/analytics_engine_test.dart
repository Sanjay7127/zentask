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

  group('weeklyActivity / monthlyActivity (Phase 10)', () {
    // Task.create/copyWith always stamp updatedAt as DateTime.now(), so
    // these tests construct Task directly to backdate completions to
    // specific days — the only way to get a deterministic "completed on
    // day X" fixture.
    Task doneTaskAt(String id, DateTime updatedAt) => Task(
          id: id,
          title: id,
          isDone: true,
          status: TaskStatus.done,
          updatedAt: updatedAt,
        );

    test('weeklyActivity counts completions per day, oldest to today',
        () async {
      final now = DateTime(2026, 3, 10, 15);
      await taskRepository.saveTaskRecord(doneTaskAt('a', DateTime(2026, 3, 10, 9)));
      await taskRepository.saveTaskRecord(doneTaskAt('b', DateTime(2026, 3, 10, 11)));
      await taskRepository.saveTaskRecord(doneTaskAt('c', DateTime(2026, 3, 8, 9)));

      final activity = engine().weeklyActivity(now: now);

      expect(activity, hasLength(7));
      expect(activity.last, 2); // today (index 6)
      expect(activity[4], 1); // March 8 is two days before "today"
    });

    test('monthlyActivity counts completions per week, oldest to current',
        () async {
      final now = DateTime(2026, 3, 30);
      await taskRepository.saveTaskRecord(doneTaskAt('a', DateTime(2026, 3, 30)));
      await taskRepository.saveTaskRecord(doneTaskAt('b', DateTime(2026, 3, 2)));

      final activity = engine().monthlyActivity(now: now);

      expect(activity, hasLength(5));
      expect(activity.last, 1); // current week
      expect(activity.first, 1); // 4 weeks prior
    });
  });

  group('currentStreak / longestStreak (Phase 10)', () {
    Task doneTaskAt(String id, DateTime updatedAt) => Task(
          id: id,
          title: id,
          isDone: true,
          status: TaskStatus.done,
          updatedAt: updatedAt,
        );

    test('currentStreak is 0 with no completions', () {
      expect(engine().currentStreak(), 0);
    });

    test('currentStreak counts consecutive days ending today', () async {
      final now = DateTime(2026, 3, 10, 18);
      await taskRepository.saveTaskRecord(doneTaskAt('a', DateTime(2026, 3, 10)));
      await taskRepository.saveTaskRecord(doneTaskAt('b', DateTime(2026, 3, 9)));
      await taskRepository.saveTaskRecord(doneTaskAt('c', DateTime(2026, 3, 8)));
      await taskRepository.saveTaskRecord(doneTaskAt('d', DateTime(2026, 3, 6))); // gap

      expect(engine().currentStreak(now: now), 3);
    });

    test('currentStreak still counts yesterday even if today has no completion yet',
        () async {
      final now = DateTime(2026, 3, 10, 8);
      await taskRepository.saveTaskRecord(doneTaskAt('a', DateTime(2026, 3, 9)));

      expect(engine().currentStreak(now: now), 1);
    });

    test('currentStreak is 0 once the gap is more than a day old', () async {
      final now = DateTime(2026, 3, 10);
      await taskRepository.saveTaskRecord(doneTaskAt('a', DateTime(2026, 3, 5)));

      expect(engine().currentStreak(now: now), 0);
    });

    test('longestStreak finds the longest run across all history', () async {
      await taskRepository.saveTaskRecord(doneTaskAt('a', DateTime(2026, 1, 1)));
      await taskRepository.saveTaskRecord(doneTaskAt('b', DateTime(2026, 1, 2)));
      await taskRepository.saveTaskRecord(doneTaskAt('c', DateTime(2026, 1, 3)));
      await taskRepository.saveTaskRecord(doneTaskAt('d', DateTime(2026, 2, 1)));
      await taskRepository.saveTaskRecord(doneTaskAt('e', DateTime(2026, 2, 2)));

      expect(engine().longestStreak(), 3);
    });
  });
}
