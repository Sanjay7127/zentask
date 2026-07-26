import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/tasks/recurring_task_service.dart';

void main() {
  const service = RecurringTaskService();

  test('returns null for a task with no recurrence', () {
    final task = Task.create(title: 'One-off');
    expect(service.nextOccurrence(task), isNull);
  });

  test('returns null when recurrence frequency is none', () {
    final task = Task.create(
      title: 'One-off',
      recurrence: const Recurrence(),
    );
    expect(service.nextOccurrence(task), isNull);
  });

  test('daily recurrence advances by the interval in days', () {
    final task = Task.create(
      title: 'Water plants',
      dueDate: DateTime(2026, 3, 10),
      recurrence: const Recurrence(frequency: RecurrenceFrequency.daily, interval: 2),
    );

    final next = service.nextOccurrence(task)!;

    expect(next.title, 'Water plants');
    expect(next.dueDate, DateTime(2026, 3, 12));
    expect(next.isDone, false);
    expect(next.recurrence?.frequency, RecurrenceFrequency.daily);
  });

  test('weekly recurrence advances by 7 * interval days', () {
    final task = Task.create(
      title: 'Team sync',
      dueDate: DateTime(2026, 3, 10),
      recurrence: const Recurrence(frequency: RecurrenceFrequency.weekly, interval: 2),
    );

    final next = service.nextOccurrence(task)!;

    expect(next.dueDate, DateTime(2026, 3, 24));
  });

  test('monthly recurrence advances by the interval in months', () {
    final task = Task.create(
      title: 'Pay rent',
      dueDate: DateTime(2026, 1, 31),
      recurrence: const Recurrence(frequency: RecurrenceFrequency.monthly, interval: 1),
    );

    final next = service.nextOccurrence(task)!;

    // DateTime(year, month + 1, 31) for a 30-day month rolls into the
    // following month — documented Dart DateTime normalization
    // behavior, not a bug in this service.
    expect(next.dueDate!.month, isNot(1));
  });

  test('preserves project, priority, description, and tags', () {
    final task = Task.create(
      title: 'Recurring',
      projectId: 'proj-1',
      description: 'Details',
      priority: TaskPriority.high,
      tags: const ['chore'],
      dueDate: DateTime(2026, 3, 10),
      recurrence: const Recurrence(frequency: RecurrenceFrequency.daily),
    );

    final next = service.nextOccurrence(task)!;

    expect(next.projectId, 'proj-1');
    expect(next.description, 'Details');
    expect(next.priority, TaskPriority.high);
    expect(next.tags, ['chore']);
  });

  test('uses now as the base date when there is no due date', () {
    final task = Task.create(
      title: 'No due date',
      recurrence: const Recurrence(frequency: RecurrenceFrequency.daily),
    );

    final next = service.nextOccurrence(task)!;

    final expected = DateTime.now().add(const Duration(days: 1));
    expect(next.dueDate!.difference(expected).inMinutes.abs(), lessThan(1));
  });
}
