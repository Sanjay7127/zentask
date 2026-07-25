import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/ai/ai_planner.dart';

void main() {
  group('UnavailableAIPlanner', () {
    const planner = UnavailableAIPlanner();

    test('suggestSubtasks returns an empty list, not an error', () async {
      final result = await planner.suggestSubtasks(taskTitle: 'Plan launch');
      expect(result, isEmpty);
    });

    test('suggestFocusOrder returns tasks in their original order', () async {
      final tasks = [
        Task.create(title: 'A'),
        Task.create(title: 'B'),
        Task.create(title: 'C'),
      ];

      final order = await planner.suggestFocusOrder(tasks);
      expect(order, tasks.map((t) => t.id).toList());
    });

    test('parseTaskFromText returns the raw text as the title', () async {
      final suggestion = await planner.parseTaskFromText('Buy milk tomorrow');
      expect(suggestion.title, 'Buy milk tomorrow');
      expect(suggestion.dueDate, isNull);
      expect(suggestion.priority, isNull);
      expect(suggestion.tags, isEmpty);
    });
  });
}
