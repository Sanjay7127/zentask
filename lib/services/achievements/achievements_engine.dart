import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/repositories/achievement_repository.dart';
import 'package:zentask/repositories/focus_session_repository.dart';
import 'package:zentask/repositories/habit_repository.dart';
import 'package:zentask/services/achievements/achievement_definitions.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';

/// One achievement definition plus its current unlock state — what
/// [AchievementsScreen] actually renders.
class AchievementStatus {
  final AchievementDefinition definition;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementStatus({
    required this.definition,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

/// Evaluates [achievementDefinitions] against live data gathered from
/// the existing services each feature already has — no duplicated
/// streak/counting logic, just reuse (`AnalyticsEngine` for task
/// streaks, `ProjectsController` for finished projects, and this
/// phase's own `FocusSessionRepository`/`HabitRepository`).
class AchievementsEngine {
  final AnalyticsEngine _analyticsEngine;
  final ProjectsController _projectsController;
  final FocusSessionRepository _focusSessionRepository;
  final HabitRepository _habitRepository;
  final AchievementRepository _achievementRepository;

  AchievementsEngine({
    AnalyticsEngine? analyticsEngine,
    ProjectsController? projectsController,
    FocusSessionRepository? focusSessionRepository,
    HabitRepository? habitRepository,
    AchievementRepository? achievementRepository,
  })  : _analyticsEngine = analyticsEngine ?? AnalyticsEngine(),
        _projectsController = projectsController ?? ProjectsController(),
        _focusSessionRepository = focusSessionRepository ?? FocusSessionRepository(),
        _habitRepository = habitRepository ?? HabitRepository(),
        _achievementRepository = achievementRepository ?? AchievementRepository();

  AchievementContext _buildContext() {
    final habitIds = _habitRepository.getAll().map((h) => h.id);
    final longestHabitStreak = habitIds.isEmpty
        ? 0
        : habitIds.map(_habitRepository.longestStreakFor).reduce((a, b) => a > b ? a : b);

    return AchievementContext(
      totalTasksCompleted: _analyticsEngine.computeSnapshot().completedTasks,
      longestTaskStreak: _analyticsEngine.longestStreak(),
      finishedProjectCount: _projectsController.finishedProjectCount,
      totalFocusSessions:
          _focusSessionRepository.getAll().where((s) => s.completed).length,
      longestHabitStreak: longestHabitStreak,
    );
  }

  /// Evaluates every definition, persisting newly-earned unlocks, and
  /// returns the full status list (unlocked and locked alike) for
  /// display.
  List<AchievementStatus> evaluate() {
    final context = _buildContext();
    final statuses = <AchievementStatus>[];

    for (final definition in achievementDefinitions) {
      final alreadyUnlocked = _achievementRepository.isUnlocked(definition.id);
      if (!alreadyUnlocked && definition.isUnlocked(context)) {
        _achievementRepository.markUnlocked(definition.id);
      }
      final unlocked = alreadyUnlocked || definition.isUnlocked(context);
      statuses.add(AchievementStatus(
        definition: definition,
        isUnlocked: unlocked,
        unlockedAt: _achievementRepository.unlockedAt(definition.id),
      ));
    }

    return statuses;
  }
}
