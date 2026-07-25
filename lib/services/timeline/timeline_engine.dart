import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/task_repository.dart';

enum TimelineEntryType {
  taskDue,
  taskReminder,
  eventStart,
  eventEnd,
  eventRegistrationDeadline,
  eventSubmissionDeadline,
}

/// One dated point on the aggregated timeline — a task due date, a task
/// reminder, or one of an event's several dates.
class TimelineEntry {
  final String id;
  final String title;
  final DateTime date;
  final TimelineEntryType type;
  final String sourceId;

  const TimelineEntry({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.sourceId,
  });
}

/// Aggregates tasks and events into one chronologically-sorted timeline.
///
/// **Known gap:** "Project Milestones" (mentioned in the original
/// Calendar spec) are not included — there is no milestone concept
/// modeled on [Project] yet. Extend this once that's added rather than
/// inventing an ad hoc placeholder field now.
class TimelineEngine {
  final TaskRepository _taskRepository;
  final EventRepository _eventRepository;

  TimelineEngine({
    TaskRepository? taskRepository,
    EventRepository? eventRepository,
  })  : _taskRepository = taskRepository ?? TaskRepository(),
        _eventRepository = eventRepository ?? EventRepository();

  /// Builds the full timeline, optionally windowed to `[from, to]`
  /// (inclusive), sorted ascending by date.
  List<TimelineEntry> buildTimeline({DateTime? from, DateTime? to}) {
    final entries = <TimelineEntry>[
      ..._taskEntries(),
      ..._eventEntries(),
    ];

    var filtered = entries;
    if (from != null) {
      filtered = filtered.where((e) => !e.date.isBefore(from)).toList();
    }
    if (to != null) {
      filtered = filtered.where((e) => !e.date.isAfter(to)).toList();
    }

    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  List<TimelineEntry> _taskEntries() {
    final entries = <TimelineEntry>[];
    for (final task in _taskRepository.getAllTaskRecords()) {
      if (task.dueDate != null) {
        entries.add(TimelineEntry(
          id: '${task.id}_due',
          title: task.title,
          date: task.dueDate!,
          type: TimelineEntryType.taskDue,
          sourceId: task.id,
        ));
      }
      if (task.reminder != null) {
        entries.add(TimelineEntry(
          id: '${task.id}_reminder',
          title: task.title,
          date: task.reminder!,
          type: TimelineEntryType.taskReminder,
          sourceId: task.id,
        ));
      }
    }
    return entries;
  }

  List<TimelineEntry> _eventEntries() {
    final entries = <TimelineEntry>[];
    for (final event in _eventRepository.getAll()) {
      if (event.startDate != null) {
        entries.add(TimelineEntry(
          id: '${event.id}_start',
          title: event.title,
          date: event.startDate!,
          type: TimelineEntryType.eventStart,
          sourceId: event.id,
        ));
      }
      if (event.endDate != null) {
        entries.add(TimelineEntry(
          id: '${event.id}_end',
          title: event.title,
          date: event.endDate!,
          type: TimelineEntryType.eventEnd,
          sourceId: event.id,
        ));
      }
      if (event.registrationDeadline != null) {
        entries.add(TimelineEntry(
          id: '${event.id}_reg',
          title: event.title,
          date: event.registrationDeadline!,
          type: TimelineEntryType.eventRegistrationDeadline,
          sourceId: event.id,
        ));
      }
      if (event.submissionDeadline != null) {
        entries.add(TimelineEntry(
          id: '${event.id}_sub',
          title: event.title,
          date: event.submissionDeadline!,
          type: TimelineEntryType.eventSubmissionDeadline,
          sourceId: event.id,
        ));
      }
    }
    return entries;
  }
}
