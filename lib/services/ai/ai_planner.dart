import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';

/// Structured result of parsing free text into task fields — the shape
/// a future "smart task creation" feature would consume.
class AITaskSuggestion {
  final String title;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final List<String> tags;

  const AITaskSuggestion({
    required this.title,
    this.dueDate,
    this.priority,
    this.tags = const [],
  });
}

/// Abstract contract for AI-powered planning capabilities: subtask
/// breakdown, focus-order suggestions, free-text task parsing, and
/// priority explanations.
///
/// No implementation calling a real AI provider exists yet — this phase
/// is architecture-only, per "no external API connections." A future
/// phase plugs in a real implementation (e.g. one that calls an LLM
/// through a backend proxy) behind this same interface, so nothing that
/// depends on [AIPlanner] needs to change when that happens.
abstract class AIPlanner {
  /// Suggests an ordered breakdown of subtasks for a task or goal.
  Future<List<String>> suggestSubtasks({
    required String taskTitle,
    String? taskDescription,
  });

  /// Suggests a focus order (most important first) for a set of open
  /// tasks. Returns task ids in the suggested order.
  Future<List<String>> suggestFocusOrder(List<Task> openTasks);

  /// Parses free text into structured task fields.
  Future<AITaskSuggestion> parseTaskFromText(String input);

  /// Human-readable explanation of why [task] sits where it does in a
  /// suggested focus order (Phase 9's AI Planner page).
  Future<String> explainPriority(Task task);

  /// A short, human-readable plan for today given the current open
  /// tasks (Phase 11: "daily planning").
  Future<String> generateDailyPlan(List<Task> openTasks);

  /// Estimated time to complete [task] (Phase 11: "task estimation").
  Future<Duration> estimateTaskDuration(Task task);

  /// A short assessment of whether [openTasks] represents a
  /// manageable, light, or heavy workload, with a suggestion if it's
  /// unbalanced (Phase 11: "workload balancing").
  Future<String> summarizeWorkload(List<Task> openTasks);

  /// A short natural-language summary of a project's status given its
  /// tasks (Phase 11: "project summaries").
  Future<String> summarizeProject(Project project, List<Task> tasks);
}

/// Default [AIPlanner] used until a real AI provider is wired up.
///
/// Not a no-op stub: [suggestFocusOrder] applies a real, deterministic
/// local heuristic (overdue first, then priority, then nearest due
/// date) and [explainPriority] describes that same reasoning in words —
/// both fully functional without any external API. A future AI-backed
/// implementation replaces the *reasoning*, not the interface, so no UI
/// that depends on [AIPlanner] needs to change when that happens.
class UnavailableAIPlanner implements AIPlanner {
  const UnavailableAIPlanner();

  @override
  Future<List<String>> suggestSubtasks({
    required String taskTitle,
    String? taskDescription,
  }) async =>
      const [];

  @override
  Future<List<String>> suggestFocusOrder(List<Task> openTasks) async {
    final sorted = [...openTasks]..sort(_compareByFocusPriority);
    return sorted.map((task) => task.id).toList();
  }

  @override
  Future<AITaskSuggestion> parseTaskFromText(String input) async =>
      AITaskSuggestion(title: input);

  @override
  Future<String> explainPriority(Task task) async {
    final parts = <String>['${task.priority.label} priority'];

    final dueDate = task.dueDate;
    if (dueDate != null) {
      final days = _daysUntil(dueDate);
      if (days < 0) {
        final overdueBy = -days;
        parts.add('overdue by $overdueBy day${overdueBy == 1 ? '' : 's'}');
      } else if (days == 0) {
        parts.add('due today');
      } else {
        parts.add('due in $days day${days == 1 ? '' : 's'}');
      }
    } else {
      parts.add('no due date set');
    }

    return parts.join(', ');
  }

  @override
  Future<String> generateDailyPlan(List<Task> openTasks) async {
    if (openTasks.isEmpty) {
      return 'Nothing open today — enjoy the clear plate.';
    }
    final sorted = [...openTasks]..sort(_compareByFocusPriority);
    final top = sorted.take(5);
    final buffer = StringBuffer('Suggested order for today:\n');
    for (final task in top) {
      buffer.writeln('- ${task.title}');
    }
    if (sorted.length > 5) {
      buffer.writeln('...and ${sorted.length - 5} more after that.');
    }
    return buffer.toString().trim();
  }

  @override
  Future<Duration> estimateTaskDuration(Task task) async {
    // Documented placeholder heuristic (like `_computeProductivityScore`
    // in AnalyticsEngine): 20 minutes per subtask (minimum 1), plus a
    // priority-scaled base. Not a claim of measured accuracy.
    final base = switch (task.priority) {
      TaskPriority.low => 15,
      TaskPriority.medium => 30,
      TaskPriority.high => 45,
      TaskPriority.urgent => 60,
    };
    final subtaskMinutes = task.subtasks.isEmpty ? 0 : task.subtasks.length * 20;
    return Duration(minutes: base + subtaskMinutes);
  }

  @override
  Future<String> summarizeWorkload(List<Task> openTasks) async {
    if (openTasks.isEmpty) return 'No open tasks — workload is clear.';
    final overdue = openTasks.where(_isOverdue).length;
    final urgent =
        openTasks.where((t) => t.priority == TaskPriority.urgent).length;
    final total = openTasks.length;
    final level = total <= 3
        ? 'light'
        : total <= 8
            ? 'manageable'
            : 'heavy';
    final buffer = StringBuffer(
        '$total open task${total == 1 ? '' : 's'} — $level workload.');
    if (overdue > 0) {
      buffer.write(' $overdue overdue.');
    }
    if (urgent > 0) {
      buffer.write(' $urgent marked urgent.');
    }
    if (total > 8) {
      buffer.write(' Consider rescheduling lower-priority items.');
    }
    return buffer.toString();
  }

  @override
  Future<String> summarizeProject(Project project, List<Task> tasks) async {
    if (tasks.isEmpty) {
      return '${project.title} has no tasks yet.';
    }
    final done = tasks.where((t) => t.isDone).length;
    final rate = (done / tasks.length * 100).round();
    final remaining = tasks.length - done;
    return '${project.title} is $rate% complete '
        '($done of ${tasks.length} tasks done, $remaining remaining).';
  }

  int _compareByFocusPriority(Task a, Task b) {
    final overdueA = _isOverdue(a);
    final overdueB = _isOverdue(b);
    if (overdueA != overdueB) return overdueA ? -1 : 1;

    final priorityCompare = b.priority.index.compareTo(a.priority.index);
    if (priorityCompare != 0) return priorityCompare;

    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  bool _isOverdue(Task task) =>
      !task.isDone && task.dueDate != null && _daysUntil(task.dueDate!) < 0;

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    return dueDay.difference(today).inDays;
  }
}
