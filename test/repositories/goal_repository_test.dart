import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/goal.dart';
import 'package:zentask/repositories/goal_repository.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late GoalRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_goal_repo_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('goals_test');
    repository = GoalRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('getAll is empty with no goals saved', () {
    expect(repository.getAll(), isEmpty);
  });

  test('save then getAll/getById round-trips a goal', () async {
    final goal = Goal.create(title: 'Read 12 books', targetValue: 12);
    await repository.save(goal);

    expect(repository.getAll().single.title, 'Read 12 books');
    expect(repository.getById(goal.id)?.targetValue, 12);
  });

  test('save with the same id overwrites (used by incrementing progress)', () async {
    final goal = Goal.create(title: 'Run 100km', targetValue: 100);
    await repository.save(goal);

    await repository.save(goal.copyWith(currentValue: 25));

    expect(repository.getAll(), hasLength(1));
    expect(repository.getById(goal.id)?.currentValue, 25);
  });

  test('delete removes the goal', () async {
    final goal = Goal.create(title: 'Temp', targetValue: 1);
    await repository.save(goal);

    await repository.delete(goal.id);

    expect(repository.getById(goal.id), isNull);
  });

  test('Goal.progress clamps to [0, 1] and isComplete flips at the target', () {
    final createdAt = DateTime(2026, 1, 1);
    final partial = Goal(id: 'a', title: 'x', targetValue: 10, currentValue: 4, createdAt: createdAt);
    final over = Goal(id: 'b', title: 'x', targetValue: 10, currentValue: 15, createdAt: createdAt);
    final zeroTarget = Goal(id: 'c', title: 'x', targetValue: 0, currentValue: 0, createdAt: createdAt);

    expect(partial.progress, 0.4);
    expect(partial.isComplete, isFalse);
    expect(over.progress, 1.0);
    expect(over.isComplete, isTrue);
    expect(zeroTarget.progress, 0.0);
  });
}
