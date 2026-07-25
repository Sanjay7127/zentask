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
/// breakdown, focus-order suggestions, and free-text task parsing.
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
}

/// Placeholder [AIPlanner] used until a real provider is wired up.
///
/// Every method returns a safe, deterministic no-op result rather than
/// throwing, so code can depend on [AIPlanner] today without needing to
/// null-check for "no provider configured" everywhere it's used.
class UnavailableAIPlanner implements AIPlanner {
  const UnavailableAIPlanner();

  @override
  Future<List<String>> suggestSubtasks({
    required String taskTitle,
    String? taskDescription,
  }) async =>
      const [];

  @override
  Future<List<String>> suggestFocusOrder(List<Task> openTasks) async =>
      openTasks.map((task) => task.id).toList();

  @override
  Future<AITaskSuggestion> parseTaskFromText(String input) async =>
      AITaskSuggestion(title: input);
}
