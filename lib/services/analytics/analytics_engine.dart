import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';

/// A snapshot of overall productivity metrics at a point in time.
class ProductivitySnapshot {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final int tasksCompletedThisWeek;
  final int tasksCreatedThisWeek;
  final double productivityScore;

  const ProductivitySnapshot({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.tasksCompletedThisWeek,
    required this.tasksCreatedThisWeek,
    required this.productivityScore,
  });
}

/// Computes productivity metrics from the existing rich-task storage.
///
/// This is the engine [Project] deliberately deferred to (see the doc
/// comment on `Project` in Phase 3.1): completion percentages and
/// productivity scores are computed here, on demand, from live task
/// data — never persisted as a separate field that could drift out of
/// sync with the tasks it describes.
class AnalyticsEngine {
  final TaskRepository _taskRepository;

  AnalyticsEngine({TaskRepository? taskRepository})
      : _taskRepository = taskRepository ?? TaskRepository();

  /// Fraction (0.0–1.0) of a project's tasks that are complete.
  /// Returns 0.0 for a project with no tasks.
  double projectCompletionRate(String projectId) {
    final tasks = _taskRepository.getTaskRecordsByProject(projectId);
    if (tasks.isEmpty) return 0.0;
    final done = tasks.where((task) => task.isDone).length;
    return done / tasks.length;
  }

  /// Overall productivity snapshot across every rich task record.
  ProductivitySnapshot computeSnapshot({DateTime? now}) {
    final tasks = _taskRepository.getAllTaskRecords();
    final effectiveNow = now ?? DateTime.now();
    final weekStart = _startOfWeek(effectiveNow);

    final total = tasks.length;
    final completed = tasks.where((task) => task.isDone).length;
    final completionRate = total == 0 ? 0.0 : completed / total;

    final completedThisWeek = tasks
        .where((task) =>
            task.isDone &&
            task.updatedAt != null &&
            !task.updatedAt!.isBefore(weekStart))
        .length;
    final createdThisWeek = tasks
        .where((task) =>
            task.createdAt != null && !task.createdAt!.isBefore(weekStart))
        .length;

    return ProductivitySnapshot(
      totalTasks: total,
      completedTasks: completed,
      completionRate: completionRate,
      tasksCompletedThisWeek: completedThisWeek,
      tasksCreatedThisWeek: createdThisWeek,
      productivityScore: _computeProductivityScore(
        completionRate: completionRate,
        completedThisWeek: completedThisWeek,
      ),
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final daysFromMonday = startOfDay.weekday - DateTime.monday;
    return startOfDay.subtract(Duration(days: daysFromMonday));
  }

  /// Tasks completed per day for the last 7 days (oldest first, today
  /// last) — the Analytics dashboard's Weekly Activity chart (Phase 10).
  ///
  /// Uses `updatedAt` as the completion timestamp, same proxy
  /// `computeSnapshot`'s `tasksCompletedThisWeek` already relies on
  /// (`Task` has no dedicated `completedAt` field) — so a task edited
  /// after completion (without changing `isDone`) would double-count on
  /// the day of that later edit and not the original completion day.
  /// Documented limitation, not fixed here: adding `completedAt` is a
  /// model change beyond this phase's scope.
  List<int> weeklyActivity({DateTime? now}) {
    final effectiveNow = _dateOnly(now ?? DateTime.now());
    final tasks = _taskRepository.getAllTaskRecords();
    return List<int>.generate(7, (i) {
      final day = effectiveNow.subtract(Duration(days: 6 - i));
      return _countCompletedOn(tasks, day);
    });
  }

  /// Tasks completed per week for the last 5 weeks (oldest first,
  /// current week last) — the Analytics dashboard's Monthly Activity
  /// chart (Phase 10).
  List<int> monthlyActivity({DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final currentWeekStart = _startOfWeek(effectiveNow);
    final tasks = _taskRepository.getAllTaskRecords();
    return List<int>.generate(5, (i) {
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * (4 - i)));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return tasks
          .where((task) =>
              task.isDone &&
              task.updatedAt != null &&
              !task.updatedAt!.isBefore(weekStart) &&
              task.updatedAt!.isBefore(weekEnd))
          .length;
    });
  }

  /// Consecutive days with at least one completed task, counting
  /// backward from today. If neither today nor yesterday has a
  /// completion, the streak is broken (0) — today not yet having one
  /// doesn't break it, since the day isn't over.
  int currentStreak({DateTime? now}) {
    final activeDays = _distinctCompletionDays();
    if (activeDays.isEmpty) return 0;

    final today = _dateOnly(now ?? DateTime.now());
    var cursor = today;
    if (!activeDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!activeDays.contains(cursor)) return 0;
    }

    var streak = 0;
    while (activeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The longest run of consecutive days with at least one completed
  /// task, over the entire task history.
  int longestStreak() {
    final activeDays = _distinctCompletionDays().toList()..sort();
    if (activeDays.isEmpty) return 0;

    var longest = 1;
    var current = 1;
    for (var i = 1; i < activeDays.length; i++) {
      final gap = activeDays[i].difference(activeDays[i - 1]).inDays;
      current = gap == 1 ? current + 1 : 1;
      if (current > longest) longest = current;
    }
    return longest;
  }

  Set<DateTime> _distinctCompletionDays() {
    return _taskRepository
        .getAllTaskRecords()
        .where((task) => task.isDone && task.updatedAt != null)
        .map((task) => _dateOnly(task.updatedAt!))
        .toSet();
  }

  int _countCompletedOn(List<Task> tasks, DateTime day) {
    final next = day.add(const Duration(days: 1));
    return tasks
        .where((task) =>
            task.isDone &&
            task.updatedAt != null &&
            !task.updatedAt!.isBefore(day) &&
            task.updatedAt!.isBefore(next))
        .length;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Simple, transparent heuristic: 70% weight on overall completion
  /// rate, 30% weight on a weekly-volume signal capped at 10
  /// completions/week. This is a documented placeholder — refine once
  /// there's real usage data to calibrate against, not a claim of a
  /// scientifically-derived score.
  double _computeProductivityScore({
    required double completionRate,
    required int completedThisWeek,
  }) {
    final volumeSignal = (completedThisWeek / 10).clamp(0.0, 1.0);
    return ((completionRate * 0.7) + (volumeSignal * 0.3)) * 100;
  }
}
