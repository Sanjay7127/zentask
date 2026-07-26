import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/task.dart';

void main() {
  group('Task legacy storage (unchanged since before Phase 3)', () {
    test('toStorage/fromStorage round-trips [title, isDone]', () {
      const task = Task(title: 'Buy milk', isDone: true);
      final stored = task.toStorage();

      expect(stored, ['Buy milk', true]);

      final restored = Task.fromStorage(stored);
      expect(restored.title, 'Buy milk');
      expect(restored.isDone, true);
    });

    test('legacy constructor still works with only title/isDone', () {
      const task = Task(title: 'Legacy task', isDone: false);
      expect(task.title, 'Legacy task');
      expect(task.isDone, false);
      expect(task.completed, false);
      expect(task.status, TaskStatus.todo);
      expect(task.tags, isEmpty);
      expect(task.subtasks, isEmpty);
    });

    test('copyWith(isDone:) keeps the legacy call site working', () {
      const task = Task(title: 'Legacy task', isDone: false);
      final toggled = task.copyWith(isDone: true);

      expect(toggled.isDone, true);
      expect(toggled.completed, true);
      // status stays in sync even though only isDone was passed
      expect(toggled.status, TaskStatus.done);
    });
  });

  group('Task rich storage (Phase 3)', () {
    test('Task.create generates an id and timestamps', () {
      final task = Task.create(title: 'Design the icon', projectId: 'p1');

      expect(task.id, isNotEmpty);
      expect(task.projectId, 'p1');
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
      expect(task.status, TaskStatus.todo);
      expect(task.isDone, false);
    });

    test('toMap/fromMap round-trips every field', () {
      final original = Task.create(
        title: 'Submit hackathon project',
        projectId: 'proj-1',
        description: 'Final submission',
        priority: TaskPriority.urgent,
        dueDate: DateTime(2026, 8, 1, 17),
        reminder: DateTime(2026, 8, 1, 9),
        status: TaskStatus.inProgress,
        tags: const ['hackathon', 'urgent'],
        subtasks: const [
          Subtask(id: 's1', title: 'Write README', completed: true),
          Subtask(id: 's2', title: 'Record demo'),
        ],
        recurrence: const Recurrence(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        ),
        order: 3,
      );

      final restored = Task.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.projectId, original.projectId);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.priority, TaskPriority.urgent);
      expect(restored.dueDate, original.dueDate);
      expect(restored.reminder, original.reminder);
      expect(restored.status, TaskStatus.inProgress);
      expect(restored.isDone, false);
      expect(restored.tags, ['hackathon', 'urgent']);
      expect(restored.subtasks.length, 2);
      expect(restored.subtasks[0].title, 'Write README');
      expect(restored.subtasks[0].completed, true);
      expect(restored.recurrence?.frequency, RecurrenceFrequency.weekly);
      expect(restored.recurrence?.interval, 2);
      expect(restored.order, 3);
    });

    test('fromMap tolerates missing optional fields', () {
      final minimal = {
        'id': 'x1',
        'title': 'Bare task',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
      };

      final task = Task.fromMap(minimal);
      expect(task.title, 'Bare task');
      expect(task.priority, TaskPriority.medium);
      expect(task.status, TaskStatus.todo);
      expect(task.tags, isEmpty);
      expect(task.subtasks, isEmpty);
      expect(task.recurrence, isNull);
    });

    test('copyWith(status:) keeps isDone in sync', () {
      final task = Task.create(title: 'A task');
      final done = task.copyWith(status: TaskStatus.done);

      expect(done.status, TaskStatus.done);
      expect(done.isDone, true);
      expect(done.completed, true);
    });

    test('copyWith(projectId: null) leaves projectId unchanged (documented '
        'null-coalescing convention)', () {
      final task = Task.create(title: 'A task', projectId: 'p1');
      final copy = task.copyWith(projectId: null);
      expect(copy.projectId, 'p1');
    });

    test('unassignFromProject clears projectId (Phase 7)', () {
      final task = Task.create(title: 'A task', projectId: 'p1');
      final unassigned = task.unassignFromProject();

      expect(unassigned.projectId, isNull);
      expect(unassigned.id, task.id);
      expect(unassigned.title, task.title);
    });

    test('withoutDueDate clears dueDate (Phase 7)', () {
      final task = Task.create(title: 'A task', dueDate: DateTime(2026, 1, 1));
      final cleared = task.withoutDueDate();
      expect(cleared.dueDate, isNull);
      expect(cleared.id, task.id);
    });

    test('withoutReminder clears reminder (Phase 7)', () {
      final task =
          Task.create(title: 'A task', reminder: DateTime(2026, 1, 1));
      final cleared = task.withoutReminder();
      expect(cleared.reminder, isNull);
      expect(cleared.id, task.id);
    });
  });
}
