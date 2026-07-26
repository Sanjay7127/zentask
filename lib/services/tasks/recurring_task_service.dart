import 'package:zentask/models/task.dart';

/// Turns [Task.recurrence] (stored since Phase 3 but never acted upon)
/// into a real feature: completing a recurring task generates its next
/// occurrence. Pure logic, no repository access — the caller (
/// [ProjectDetailController]) decides when to invoke it and saves the
/// result, consistent with every other service in this app.
class RecurringTaskService {
  const RecurringTaskService();

  /// The next occurrence of [completedTask], or `null` if it isn't
  /// recurring. The new task is a fresh, not-done [Task] with the same
  /// title/project/description/priority/tags/recurrence, due on the
  /// next date per [Recurrence.frequency]/[Recurrence.interval].
  Task? nextOccurrence(Task completedTask) {
    final recurrence = completedTask.recurrence;
    if (recurrence == null || recurrence.frequency == RecurrenceFrequency.none) {
      return null;
    }

    final baseDate = completedTask.dueDate ?? DateTime.now();
    return Task.create(
      title: completedTask.title,
      projectId: completedTask.projectId,
      description: completedTask.description,
      priority: completedTask.priority,
      dueDate: _advance(baseDate, recurrence),
      tags: completedTask.tags,
      recurrence: recurrence,
    );
  }

  DateTime _advance(DateTime date, Recurrence recurrence) {
    switch (recurrence.frequency) {
      case RecurrenceFrequency.daily:
        return date.add(Duration(days: recurrence.interval));
      case RecurrenceFrequency.weekly:
        return date.add(Duration(days: 7 * recurrence.interval));
      case RecurrenceFrequency.monthly:
        return DateTime(date.year, date.month + recurrence.interval, date.day);
      case RecurrenceFrequency.none:
        return date;
    }
  }
}
