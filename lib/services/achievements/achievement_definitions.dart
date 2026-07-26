/// Live data an [AchievementDefinition]'s [AchievementDefinition.isUnlocked]
/// check runs against — gathered by `AchievementsEngine` from the
/// existing services/repositories each feature already has (nothing new
/// is computed here, just assembled).
class AchievementContext {
  final int totalTasksCompleted;
  final int longestTaskStreak;
  final int finishedProjectCount;
  final int totalFocusSessions;
  final int longestHabitStreak;

  const AchievementContext({
    required this.totalTasksCompleted,
    required this.longestTaskStreak,
    required this.finishedProjectCount,
    required this.totalFocusSessions,
    required this.longestHabitStreak,
  });
}

/// One achievement's definition: display copy plus the criteria that
/// unlocks it. Pure Dart (no Flutter) — [iconKey] is mapped to an actual
/// icon by the UI layer, same split as `Project.iconKey`.
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String iconKey;
  final bool Function(AchievementContext context) isUnlocked;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.isUnlocked,
  });
}

/// The curated, fixed set of achievements this app offers. Adding a new
/// one is additive — existing unlock records in [AchievementRepository]
/// are keyed by [AchievementDefinition.id] and untouched by changes here.
final List<AchievementDefinition> achievementDefinitions = [
  AchievementDefinition(
    id: 'first_task',
    title: 'First Steps',
    description: 'Complete your first task',
    iconKey: 'star',
    isUnlocked: (ctx) => ctx.totalTasksCompleted >= 1,
  ),
  AchievementDefinition(
    id: 'ten_tasks',
    title: 'Getting Things Done',
    description: 'Complete 10 tasks',
    iconKey: 'checklist',
    isUnlocked: (ctx) => ctx.totalTasksCompleted >= 10,
  ),
  AchievementDefinition(
    id: 'fifty_tasks',
    title: 'Productivity Pro',
    description: 'Complete 50 tasks',
    iconKey: 'trophy',
    isUnlocked: (ctx) => ctx.totalTasksCompleted >= 50,
  ),
  AchievementDefinition(
    id: 'week_streak',
    title: 'Week Warrior',
    description: 'Reach a 7-day completion streak',
    iconKey: 'fire',
    isUnlocked: (ctx) => ctx.longestTaskStreak >= 7,
  ),
  AchievementDefinition(
    id: 'month_streak',
    title: 'Consistency Champion',
    description: 'Reach a 30-day completion streak',
    iconKey: 'fire',
    isUnlocked: (ctx) => ctx.longestTaskStreak >= 30,
  ),
  AchievementDefinition(
    id: 'first_project',
    title: 'Project Starter',
    description: 'Finish your first project',
    iconKey: 'folder',
    isUnlocked: (ctx) => ctx.finishedProjectCount >= 1,
  ),
  AchievementDefinition(
    id: 'five_focus_sessions',
    title: 'Focused Mind',
    description: 'Complete 5 focus sessions',
    iconKey: 'timer',
    isUnlocked: (ctx) => ctx.totalFocusSessions >= 5,
  ),
  AchievementDefinition(
    id: 'habit_week',
    title: 'Habit Builder',
    description: 'Reach a 7-day habit streak',
    iconKey: 'habit',
    isUnlocked: (ctx) => ctx.longestHabitStreak >= 7,
  ),
];
