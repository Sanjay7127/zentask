import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zentask/config/cloud_config.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/ai/ai_planner.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';

/// Real [AIPlanner] backed by Anthropic's Claude API (direct HTTPS
/// calls via `package:http` — there's no official Anthropic Dart SDK,
/// and the Messages API is simple enough not to need one).
///
/// **Not build-verified against a live API key in this environment** —
/// `CloudConfig.anthropicApiKey` was empty throughout this phase's
/// development, so every method below is implemented against
/// Anthropic's documented Messages API shape but has not actually been
/// exercised against a real response. Verify end to end once a key is
/// in place.
class AnthropicAIPlanner implements AIPlanner {
  final http.Client _httpClient;
  final String _apiKey;
  final String _model;

  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _anthropicVersion = '2023-06-01';

  AnthropicAIPlanner({
    http.Client? httpClient,
    String? apiKey,
    String model = 'claude-3-5-sonnet-latest',
  })  : _httpClient = httpClient ?? http.Client(),
        _apiKey = apiKey ?? CloudConfig.anthropicApiKey,
        _model = model;

  Future<String> _complete(String prompt, {int maxTokens = 512}) async {
    if (_apiKey.isEmpty) {
      throw const CloudUnavailableException(
          'No Anthropic API key configured — set ANTHROPIC_API_KEY in config/cloud_config.json.');
    }

    final response = await _httpClient.post(
      Uri.parse(_apiUrl),
      headers: {
        'x-api-key': _apiKey,
        'anthropic-version': _anthropicVersion,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw CloudUnavailableException(
          'Anthropic API request failed (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) return '';
    final first = content.first as Map<String, dynamic>;
    return (first['text'] as String?)?.trim() ?? '';
  }

  /// Strips a ```json ... ``` (or plain ``` ... ```) fence Claude
  /// sometimes wraps structured responses in, so `jsonDecode` doesn't
  /// choke on the surrounding markdown.
  String _stripCodeFence(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('```')) return trimmed;
    final withoutOpeningFence =
        trimmed.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
    return withoutOpeningFence.replaceFirst(RegExp(r'```\s*$'), '').trim();
  }

  @override
  Future<List<String>> suggestSubtasks({
    required String taskTitle,
    String? taskDescription,
  }) async {
    final prompt = 'Break the following task into 3-6 concrete subtasks. '
        'Reply with one subtask per line, no numbering or bullets.\n\n'
        'Task: $taskTitle'
        '${taskDescription != null && taskDescription.isNotEmpty ? '\nDetails: $taskDescription' : ''}';
    final response = await _complete(prompt);
    return response
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Future<List<String>> suggestFocusOrder(List<Task> openTasks) async {
    if (openTasks.isEmpty) return [];
    final taskLines = openTasks.map((t) => jsonEncode({
          'id': t.id,
          'title': t.title,
          'priority': t.priority.name,
          'dueDate': t.dueDate?.toIso8601String(),
        }));
    final prompt = 'Given these open tasks (one JSON object per line), '
        'return a JSON array of their "id" values in the order they '
        'should be tackled, most important first. Reply with only the '
        'JSON array, nothing else.\n\n${taskLines.join('\n')}';
    final response = await _complete(prompt);
    try {
      final decoded = jsonDecode(_stripCodeFence(response)) as List<dynamic>;
      final ids = decoded.cast<String>();
      final validIds = openTasks.map((t) => t.id).toSet();
      final filtered = ids.where(validIds.contains).toList();
      // Anything the model dropped still needs to show up somewhere.
      final missing = openTasks.map((t) => t.id).where((id) => !filtered.contains(id));
      return [...filtered, ...missing];
    } catch (_) {
      return openTasks.map((t) => t.id).toList();
    }
  }

  @override
  Future<AITaskSuggestion> parseTaskFromText(String input) async {
    final prompt = 'Extract a task from this text. Reply with only a JSON '
        'object shaped like '
        '{"title": string, "dueDate": string|null (ISO 8601), '
        '"priority": "low"|"medium"|"high"|"urgent"|null, "tags": string[]}.'
        '\n\nText: $input';
    final response = await _complete(prompt, maxTokens: 256);
    try {
      final decoded = jsonDecode(_stripCodeFence(response)) as Map<String, dynamic>;
      final priorityName = decoded['priority'] as String?;
      return AITaskSuggestion(
        title: (decoded['title'] as String?)?.trim().isNotEmpty == true
            ? decoded['title'] as String
            : input,
        dueDate: decoded['dueDate'] != null
            ? DateTime.tryParse(decoded['dueDate'] as String)
            : null,
        priority: priorityName != null
            ? TaskPriority.values
                .firstWhere((p) => p.name == priorityName, orElse: () => TaskPriority.medium)
            : null,
        tags: (decoded['tags'] as List?)?.cast<String>() ?? const [],
      );
    } catch (_) {
      return AITaskSuggestion(title: input);
    }
  }

  @override
  Future<String> explainPriority(Task task) async {
    final prompt = 'In one short sentence, explain why a task titled '
        '"${task.title}" with ${task.priority.name} priority'
        '${task.dueDate != null ? ' and due date ${task.dueDate!.toIso8601String()}' : ' and no due date'} '
        'deserves its place in a focus-ordered task list.';
    final response = await _complete(prompt, maxTokens: 128);
    return response.isNotEmpty ? response : '${task.priority.name} priority';
  }

  @override
  Future<String> generateDailyPlan(List<Task> openTasks) async {
    if (openTasks.isEmpty) return 'Nothing open today — enjoy the clear plate.';
    final titles = openTasks.map((t) => '- ${t.title} (${t.priority.name})').join('\n');
    final prompt = 'Given these open tasks, write a short (3-5 sentence) '
        'plan for today: what to tackle first and why, and how to pace '
        'the rest.\n\n$titles';
    return _complete(prompt, maxTokens: 256);
  }

  @override
  Future<Duration> estimateTaskDuration(Task task) async {
    final prompt = 'Estimate how many minutes a task titled "${task.title}" '
        '${task.description.isNotEmpty ? 'described as "${task.description}" ' : ''}'
        'with ${task.subtasks.length} subtasks would realistically take. '
        'Reply with only an integer number of minutes.';
    final response = await _complete(prompt, maxTokens: 16);
    final minutes = int.tryParse(response.replaceAll(RegExp(r'[^0-9]'), ''));
    return Duration(minutes: minutes != null && minutes > 0 ? minutes : 30);
  }

  @override
  Future<String> summarizeWorkload(List<Task> openTasks) async {
    if (openTasks.isEmpty) return 'No open tasks — workload is clear.';
    final summary = openTasks
        .map((t) => '${t.title} (${t.priority.name}${t.dueDate != null ? ', due ${t.dueDate!.toIso8601String()}' : ''})')
        .join('\n');
    final prompt = 'Given this list of open tasks, write a short (2-3 '
        'sentence) assessment of whether this workload is light, '
        'manageable, or heavy, and a suggestion if it looks unbalanced.'
        '\n\n$summary';
    return _complete(prompt, maxTokens: 200);
  }

  @override
  Future<String> summarizeProject(Project project, List<Task> tasks) async {
    final done = tasks.where((t) => t.isDone).length;
    final prompt = 'Write a short (2-3 sentence) status summary for a '
        'project called "${project.title}" '
        '(${project.description.isNotEmpty ? '${project.description}, ' : ''}'
        '$done of ${tasks.length} tasks done).';
    return _complete(prompt, maxTokens: 200);
  }
}
