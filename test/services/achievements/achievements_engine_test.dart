import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/focus_session.dart';
import 'package:zentask/models/habit.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/repositories/achievement_repository.dart';
import 'package:zentask/repositories/focus_session_repository.dart';
import 'package:zentask/repositories/habit_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/achievements/achievements_engine.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late Box projectsBox;
  late Box focusSessionsBox;
  late Box habitsBox;
  late Box habitCompletionsBox;
  late Box achievementsBox;

  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;
  late FocusSessionRepository focusSessionRepository;
  late HabitRepository habitRepository;
  late AchievementRepository achievementRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_achievements_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    projectsBox = await Hive.openBox('projects_test');
    focusSessionsBox = await Hive.openBox('focus_sessions_test');
    habitsBox = await Hive.openBox('habits_test');
    habitCompletionsBox = await Hive.openBox('habit_completions_test');
    achievementsBox = await Hive.openBox('achievements_test');

    taskRepository = TaskRepository(box: legacyBox, recordsBox: recordsBox, settingsBox: settingsBox);
    projectRepository = ProjectRepository(box: projectsBox);
    focusSessionRepository = FocusSessionRepository(box: focusSessionsBox);
    habitRepository = HabitRepository(habitsBox: habitsBox, completionsBox: habitCompletionsBox);
    achievementRepository = AchievementRepository(box: achievementsBox);
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await projectsBox.deleteFromDisk();
    await focusSessionsBox.deleteFromDisk();
    await habitsBox.deleteFromDisk();
    await habitCompletionsBox.deleteFromDisk();
    await achievementsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AchievementsEngine engine() => AchievementsEngine(
        analyticsEngine: AnalyticsEngine(taskRepository: taskRepository),
        projectsController: ProjectsController(
          projectRepository: projectRepository,
          taskRepository: taskRepository,
          analyticsEngine: AnalyticsEngine(taskRepository: taskRepository),
        ),
        focusSessionRepository: focusSessionRepository,
        habitRepository: habitRepository,
        achievementRepository: achievementRepository,
      );

  test('everything is locked with no data at all', () {
    final statuses = engine().evaluate();

    expect(statuses, hasLength(8));
    expect(statuses.every((s) => !s.isUnlocked), isTrue);
  });

  test('completing one task unlocks first_task but not ten_tasks', () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'Only task', status: TaskStatus.done));

    final statuses = engine().evaluate();

    final firstTask = statuses.firstWhere((s) => s.definition.id == 'first_task');
    final tenTasks = statuses.firstWhere((s) => s.definition.id == 'ten_tasks');
    expect(firstTask.isUnlocked, isTrue);
    expect(tenTasks.isUnlocked, isFalse);
  });

  test('a 7-day completion streak unlocks week_streak', () async {
    final base = DateTime(2026, 3, 1);
    for (var i = 0; i < 7; i++) {
      await taskRepository.saveTaskRecord(Task(
        id: 'task-$i',
        title: 'Day $i',
        isDone: true,
        updatedAt: base.add(Duration(days: i)),
      ));
    }

    final statuses = engine().evaluate();

    expect(statuses.firstWhere((s) => s.definition.id == 'week_streak').isUnlocked, isTrue);
    expect(statuses.firstWhere((s) => s.definition.id == 'month_streak').isUnlocked, isFalse);
  });

  test('finishing a project (all tasks done) unlocks first_project', () async {
    final project = Project.create(title: 'Solo project');
    await projectRepository.save(project);
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Only task', projectId: project.id, status: TaskStatus.done),
    );

    final statuses = engine().evaluate();

    expect(statuses.firstWhere((s) => s.definition.id == 'first_project').isUnlocked, isTrue);
  });

  test('5 completed focus sessions unlock five_focus_sessions', () async {
    final now = DateTime(2026, 3, 1);
    for (var i = 0; i < 5; i++) {
      await focusSessionRepository.save(FocusSession.create(
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 25)),
        completed: true,
      ));
    }

    final statuses = engine().evaluate();

    expect(statuses.firstWhere((s) => s.definition.id == 'five_focus_sessions').isUnlocked, isTrue);
  });

  test('a 7-day habit streak unlocks habit_week', () async {
    final habit = Habit.create(title: 'Streak habit');
    await habitRepository.save(habit);
    final base = DateTime(2026, 3, 1);
    for (var i = 0; i < 7; i++) {
      await habitRepository.setCompletedOn(habit.id, base.add(Duration(days: i)), true);
    }

    final statuses = engine().evaluate();

    expect(statuses.firstWhere((s) => s.definition.id == 'habit_week').isUnlocked, isTrue);
  });

  test('an unlock is persisted and stays unlocked even if the earning data disappears', () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'Only task', status: TaskStatus.done));
    engine().evaluate();

    // A fresh TaskRepository backed by an empty box: no completed tasks
    // anymore, but the achievement should still read as unlocked.
    final freshLegacyBox = await Hive.openBox('fresh_legacy');
    final freshRecordsBox = await Hive.openBox('fresh_records');
    final freshSettingsBox = await Hive.openBox('fresh_settings');
    final freshTaskRepository = TaskRepository(
      box: freshLegacyBox,
      recordsBox: freshRecordsBox,
      settingsBox: freshSettingsBox,
    );

    final laterStatuses = AchievementsEngine(
      analyticsEngine: AnalyticsEngine(taskRepository: freshTaskRepository),
      projectsController: ProjectsController(
        projectRepository: projectRepository,
        taskRepository: freshTaskRepository,
        analyticsEngine: AnalyticsEngine(taskRepository: freshTaskRepository),
      ),
      focusSessionRepository: focusSessionRepository,
      habitRepository: habitRepository,
      achievementRepository: achievementRepository,
    ).evaluate();

    expect(laterStatuses.firstWhere((s) => s.definition.id == 'first_task').isUnlocked, isTrue);

    await freshLegacyBox.deleteFromDisk();
    await freshRecordsBox.deleteFromDisk();
    await freshSettingsBox.deleteFromDisk();
  });
}
