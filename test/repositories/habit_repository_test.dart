import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/habit.dart';
import 'package:zentask/repositories/habit_repository.dart';

void main() {
  late Directory tempDir;
  late Box habitsBox;
  late Box completionsBox;
  late HabitRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_habit_repo_test');
    Hive.init(tempDir.path);
    habitsBox = await Hive.openBox('habits_test');
    completionsBox = await Hive.openBox('habit_completions_test');
    repository = HabitRepository(habitsBox: habitsBox, completionsBox: completionsBox);
  });

  tearDown(() async {
    await habitsBox.deleteFromDisk();
    await completionsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('getAll is empty with no habits saved', () {
    expect(repository.getAll(), isEmpty);
  });

  test('save then getAll round-trips a habit', () async {
    final habit = Habit.create(title: 'Drink water');
    await repository.save(habit);

    expect(repository.getAll().single.title, 'Drink water');
  });

  test('isCompletedOn is false until setCompletedOn(true)', () async {
    final habit = Habit.create(title: 'Read');
    await repository.save(habit);
    final day = DateTime(2026, 3, 10);

    expect(repository.isCompletedOn(habit.id, day), isFalse);

    await repository.setCompletedOn(habit.id, day, true);
    expect(repository.isCompletedOn(habit.id, day), isTrue);
  });

  test('setCompletedOn(false) removes a previously-recorded completion', () async {
    final habit = Habit.create(title: 'Read');
    await repository.save(habit);
    final day = DateTime(2026, 3, 10);

    await repository.setCompletedOn(habit.id, day, true);
    await repository.setCompletedOn(habit.id, day, false);

    expect(repository.isCompletedOn(habit.id, day), isFalse);
  });

  test('delete removes the habit and its completions', () async {
    final habit = Habit.create(title: 'Meditate');
    await repository.save(habit);
    await repository.setCompletedOn(habit.id, DateTime(2026, 3, 10), true);

    await repository.delete(habit.id);

    expect(repository.getAll(), isEmpty);
    expect(repository.completionDatesFor(habit.id), isEmpty);
  });

  test('delete does not touch another habit\'s completions', () async {
    final a = Habit.create(title: 'A');
    final b = Habit.create(title: 'B');
    await repository.save(a);
    await repository.save(b);
    await repository.setCompletedOn(a.id, DateTime(2026, 3, 10), true);
    await repository.setCompletedOn(b.id, DateTime(2026, 3, 10), true);

    await repository.delete(a.id);

    expect(repository.completionDatesFor(b.id), hasLength(1));
  });

  test('currentStreakFor counts consecutive days ending today', () async {
    final habit = Habit.create(title: 'Streak');
    await repository.save(habit);
    final today = DateTime(2026, 3, 10);
    for (var i = 0; i < 3; i++) {
      await repository.setCompletedOn(habit.id, today.subtract(Duration(days: i)), true);
    }

    expect(repository.currentStreakFor(habit.id, now: today), 3);
  });

  test('currentStreakFor still counts if only yesterday is done (today pending)', () async {
    final habit = Habit.create(title: 'Streak');
    await repository.save(habit);
    final today = DateTime(2026, 3, 10);
    await repository.setCompletedOn(habit.id, today.subtract(const Duration(days: 1)), true);

    expect(repository.currentStreakFor(habit.id, now: today), 1);
  });

  test('currentStreakFor is 0 once a day is missed', () async {
    final habit = Habit.create(title: 'Streak');
    await repository.save(habit);
    final today = DateTime(2026, 3, 10);
    await repository.setCompletedOn(habit.id, today.subtract(const Duration(days: 2)), true);

    expect(repository.currentStreakFor(habit.id, now: today), 0);
  });

  test('longestStreakFor finds the longest run even if it isn\'t current', () async {
    final habit = Habit.create(title: 'Streak');
    await repository.save(habit);
    final base = DateTime(2026, 3, 1);
    // A 4-day run, a gap, then a 1-day run.
    for (var i = 0; i < 4; i++) {
      await repository.setCompletedOn(habit.id, base.add(Duration(days: i)), true);
    }
    await repository.setCompletedOn(habit.id, base.add(const Duration(days: 10)), true);

    expect(repository.longestStreakFor(habit.id), 4);
  });
}
