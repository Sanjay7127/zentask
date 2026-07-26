import 'package:flutter/foundation.dart';
import 'package:zentask/config/cloud_config.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/ai/ai_planner.dart';
import 'package:zentask/services/ai/anthropic_ai_planner.dart';

/// Business logic for the AI Planner page: fetches open tasks, asks the
/// configured [AIPlanner] for a focus order and per-task explanations.
///
/// Defaults to [UnavailableAIPlanner] (a real, working local heuristic,
/// not a stub — see its doc comment) unless an Anthropic API key is
/// configured (Phase 11), in which case [AnthropicAIPlanner] is used
/// instead. Swapping providers again later only means changing this one
/// default; nothing in [AIPlannerScreen] needs to change.
class AIPlannerController extends ChangeNotifier {
  final AIPlanner _planner;
  final TaskRepository _taskRepository;

  bool _loading = true;
  List<Task> _focusOrder = [];
  final Map<String, String> _explanations = {};

  AIPlannerController({
    AIPlanner? planner,
    TaskRepository? taskRepository,
  })  : _planner = planner ??
            (CloudConfig.hasAnthropicApiKey
                ? AnthropicAIPlanner()
                : const UnavailableAIPlanner()),
        _taskRepository = taskRepository ?? TaskRepository() {
    _load();
  }

  bool get isLoading => _loading;

  List<Task> get focusOrder => List.unmodifiable(_focusOrder);

  String explanationFor(Task task) => _explanations[task.id] ?? '';

  Future<void> refresh() => _load();

  Future<void> _load() async {
    _loading = true;
    notifyListeners();

    final openTasks =
        _taskRepository.getAllTaskRecords().where((task) => !task.isDone).toList();
    final orderedIds = await _planner.suggestFocusOrder(openTasks);
    final byId = {for (final task in openTasks) task.id: task};
    _focusOrder =
        orderedIds.map((id) => byId[id]).whereType<Task>().toList();

    _explanations.clear();
    for (final task in _focusOrder) {
      _explanations[task.id] = await _planner.explainPriority(task);
    }

    _loading = false;
    notifyListeners();
  }
}
