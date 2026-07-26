import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/ai/anthropic_ai_planner.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';

http.Response _anthropicResponse(String text) => http.Response(
      jsonEncode({
        'content': [
          {'type': 'text', 'text': text},
        ],
      }),
      200,
    );

void main() {
  test('throws CloudUnavailableException when no API key is configured', () async {
    final planner = AnthropicAIPlanner(
      apiKey: '',
      httpClient: MockClient((request) async => _anthropicResponse('x')),
    );

    await expectLater(
      planner.suggestSubtasks(taskTitle: 'Plan launch'),
      throwsA(isA<CloudUnavailableException>()),
    );
  });

  test('suggestSubtasks sends the task title/description and splits the reply by line',
      () async {
    late http.Request captured;
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async {
        captured = request;
        return _anthropicResponse('Draft outline\nWrite intro\nReview');
      }),
    );

    final subtasks = await planner.suggestSubtasks(
      taskTitle: 'Write blog post',
      taskDescription: 'About Flutter',
    );

    expect(subtasks, ['Draft outline', 'Write intro', 'Review']);
    expect(captured.headers['x-api-key'], 'test-key');
    expect(captured.body, contains('Write blog post'));
    expect(captured.body, contains('About Flutter'));
  });

  test('suggestFocusOrder parses a JSON array of ids from the reply', () async {
    final tasks = [
      Task.create(title: 'A'),
      Task.create(title: 'B'),
    ];
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async =>
          _anthropicResponse(jsonEncode([tasks[1].id, tasks[0].id]))),
    );

    final order = await planner.suggestFocusOrder(tasks);

    expect(order, [tasks[1].id, tasks[0].id]);
  });

  test('suggestFocusOrder falls back to input order if the reply is not valid JSON',
      () async {
    final tasks = [Task.create(title: 'A'), Task.create(title: 'B')];
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async => _anthropicResponse('not json')),
    );

    final order = await planner.suggestFocusOrder(tasks);

    expect(order, [tasks[0].id, tasks[1].id]);
  });

  test('suggestFocusOrder still returns every id even if the model drops one',
      () async {
    final tasks = [Task.create(title: 'A'), Task.create(title: 'B')];
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async =>
          _anthropicResponse(jsonEncode([tasks[0].id]))),
    );

    final order = await planner.suggestFocusOrder(tasks);

    expect(order.toSet(), tasks.map((t) => t.id).toSet());
  });

  test('parseTaskFromText parses a structured JSON reply', () async {
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async => _anthropicResponse(jsonEncode({
            'title': 'Buy milk',
            'dueDate': '2026-05-01T00:00:00.000',
            'priority': 'high',
            'tags': ['errand'],
          }))),
    );

    final suggestion = await planner.parseTaskFromText('buy milk tomorrow, high priority');

    expect(suggestion.title, 'Buy milk');
    expect(suggestion.dueDate, DateTime.parse('2026-05-01T00:00:00.000'));
    expect(suggestion.priority, TaskPriority.high);
    expect(suggestion.tags, ['errand']);
  });

  test('parseTaskFromText falls back to the raw input if the reply is malformed',
      () async {
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async => _anthropicResponse('nonsense')),
    );

    final suggestion = await planner.parseTaskFromText('buy milk');

    expect(suggestion.title, 'buy milk');
    expect(suggestion.priority, isNull);
  });

  test('parseTaskFromText handles a ```json fenced reply', () async {
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async => _anthropicResponse(
          '```json\n${jsonEncode({'title': 'Fenced', 'tags': []})}\n```')),
    );

    final suggestion = await planner.parseTaskFromText('fenced');

    expect(suggestion.title, 'Fenced');
  });

  test('estimateTaskDuration parses an integer minute reply', () async {
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async => _anthropicResponse('45')),
    );

    final duration = await planner.estimateTaskDuration(Task.create(title: 'X'));

    expect(duration, const Duration(minutes: 45));
  });

  test('estimateTaskDuration falls back to 30 minutes on an unparseable reply',
      () async {
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async => _anthropicResponse('who knows')),
    );

    final duration = await planner.estimateTaskDuration(Task.create(title: 'X'));

    expect(duration, const Duration(minutes: 30));
  });

  test('summarizeProject includes the project title in the prompt', () async {
    late http.Request captured;
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async {
        captured = request;
        return _anthropicResponse('Looking good.');
      }),
    );

    final summary = await planner.summarizeProject(
      Project.create(title: 'Launch Week'),
      [Task.create(title: 'A', status: TaskStatus.done)],
    );

    expect(summary, 'Looking good.');
    expect(captured.body, contains('Launch Week'));
  });

  test('a non-200 response throws CloudUnavailableException', () async {
    final planner = AnthropicAIPlanner(
      apiKey: 'test-key',
      httpClient: MockClient((request) async => http.Response('server error', 500)),
    );

    await expectLater(
      planner.explainPriority(Task.create(title: 'X')),
      throwsA(isA<CloudUnavailableException>()),
    );
  });
}
