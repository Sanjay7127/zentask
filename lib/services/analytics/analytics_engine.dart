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
