import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/ai/ai_planner.dart';

void main() {
  group('UnavailableAIPlanner', () {
    const planner = UnavailableAIPlanner();

    test('suggestSubtasks returns an empty list, not an error', () async {
      final result = await planner.suggestSubtasks(taskTitle: 'Plan launch');
      expect(result, isEmpty);
    });

    test('suggestFocusOrder puts overdue tasks first (Phase 9 heuristic)',
        () async {
      final overdue = Task.create(
        title: 'Overdue',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      final notOverdue = Task.create(
        title: 'Not overdue',
        dueDate: DateTime.now().add(const Duration(days: 5)),
      );

      final order = await planner.suggestFocusOrder([notOverdue, overdue]);
      expect(order, [overdue.id, notOverdue.id]);
    });

    test('suggestFocusOrder ranks higher priority above lower, all else equal',
        () async {
      final low = Task.create(title: 'Low', priority: TaskPriority.low);
      final urgent =
          Task.create(title: 'Urgent', priority: TaskPriority.urgent);

      final order = await planner.suggestFocusOrder([low, urgent]);
      expect(order, [urgent.id, low.id]);
    });

    test('suggestFocusOrder breaks priority ties by nearest due date',
        () async {
      final later = Task.create(
        title: 'Later',
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 10)),
      );
      final sooner = Task.create(
        title: 'Sooner',
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      final order = await planner.suggestFocusOrder([later, sooner]);
      expect(order, [sooner.id, later.id]);
    });

    test('parseTaskFromText returns the raw text as the title', () async {
      final suggestion = await planner.parseTaskFromText('Buy milk tomorrow');
      expect(suggestion.title, 'Buy milk tomorrow');
      expect(suggestion.dueDate, isNull);
      expect(suggestion.priority, isNull);
      expect(suggestion.tags, isEmpty);
    });

    test('explainPriority mentions priority level and due-date status',
        () async {
      final overdue = Task.create(
        title: 'A',
        priority: TaskPriority.urgent,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final explanation = await planner.explainPriority(overdue);
      expect(explanation, contains('Urgent'));
      expect(explanation, contains('overdue'));
    });

    test('explainPriority handles a task with no due date', () async {
      final noDueDate = Task.create(title: 'B', priority: TaskPriority.low);
      final explanation = await planner.explainPriority(noDueDate);
      expect(explanation, contains('Low'));
      expect(explanation, contains('no due date'));
    });

    test('generateDailyPlan handles no open tasks', () async {
      final plan = await planner.generateDailyPlan([]);
      expect(plan, contains('clear plate'));
    });

    test('generateDailyPlan lists open tasks in focus order', () async {
      final urgent = Task.create(title: 'Urgent thing', priority: TaskPriority.urgent);
      final low = Task.create(title: 'Low thing', priority: TaskPriority.low);
      final plan = await planner.generateDailyPlan([low, urgent]);
      expect(plan.indexOf('Urgent thing'), lessThan(plan.indexOf('Low thing')));
    });

    test('estimateTaskDuration scales with priority and subtask count',
        () async {
      final simple = Task.create(title: 'A', priority: TaskPriority.low);
      final complex = Task.create(
        title: 'B',
        priority: TaskPriority.urgent,
        subtasks: const [
          Subtask(id: '1', title: 'x'),
          Subtask(id: '2', title: 'y'),
        ],
      );

      final simpleDuration = await planner.estimateTaskDuration(simple);
      final complexDuration = await planner.estimateTaskDuration(complex);

      expect(complexDuration, greaterThan(simpleDuration));
    });

    test('summarizeWorkload reports a clear workload with no open tasks',
        () async {
      final summary = await planner.summarizeWorkload([]);
      expect(summary, contains('No open tasks'));
    });

    test('summarizeWorkload mentions overdue and urgent counts', () async {
      final overdue = Task.create(
        title: 'Overdue',
        priority: TaskPriority.urgent,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final summary = await planner.summarizeWorkload([overdue]);
      expect(summary, contains('1 overdue'));
      expect(summary, contains('1 marked urgent'));
    });

    test('summarizeProject reports 0% for a project with no done tasks',
        () async {
      final project = Project.create(title: 'New Project');
      final tasks = [Task.create(title: 'A'), Task.create(title: 'B')];
      final summary = await planner.summarizeProject(project, tasks);
      expect(summary, contains('New Project'));
      expect(summary, contains('0%'));
    });

    test('summarizeProject handles a project with no tasks at all', () async {
      final project = Project.create(title: 'Empty');
      final summary = await planner.summarizeProject(project, []);
      expect(summary, contains('no tasks yet'));
    });
  });
}
