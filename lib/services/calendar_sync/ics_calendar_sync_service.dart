import 'package:zentask/models/event.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/services/calendar_sync/calendar_sync_service.dart';
import 'package:zentask/services/calendar_sync/ics_format.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

/// Real [CalendarSyncService]: exports the existing timeline (task due
/// dates/reminders, event dates) as a standard .ics file any calendar
/// app can import, and imports a .ics file's VEVENTs as new [Event]
/// records. Fully local — no account or network needed, unlike the
/// Google/Apple providers.
///
/// **Known limitation**: import always creates new events rather than
/// updating previously-imported ones (no de-duplication against a
/// VEVENT's UID) — re-importing the same file creates duplicates. A
/// dedup pass keyed on UID is a reasonable follow-up once this sees
/// real use.
class IcsCalendarSyncService implements CalendarSyncService {
  final TimelineEngine _timelineEngine;
  final EventRepository _eventRepository;

  IcsCalendarSyncService({
    TimelineEngine? timelineEngine,
    EventRepository? eventRepository,
  })  : _timelineEngine = timelineEngine ?? TimelineEngine(),
        _eventRepository = eventRepository ?? EventRepository();

  @override
  String get displayName => 'ICS file';

  @override
  bool get isAvailable => true;

  @override
  Future<String> exportAll() async {
    final entries = _timelineEngine.buildTimeline();
    final events = entries
        .map((entry) => IcsEvent(
              uid: '${entry.id}@zentask',
              summary: entry.title,
              description: _labelForType(entry.type),
              start: entry.date,
            ))
        .toList();
    return IcsFormat.build('ZenTask', events);
  }

  @override
  Future<int> importFrom(String data) async {
    final icsEvents = IcsFormat.parse(data);
    for (final icsEvent in icsEvents) {
      final event = Event.create(
        title: icsEvent.summary,
        description: icsEvent.description,
        type: EventType.other,
        startDate: icsEvent.start,
        endDate: icsEvent.end,
      );
      await _eventRepository.save(event);
    }
    return icsEvents.length;
  }

  String _labelForType(TimelineEntryType type) {
    switch (type) {
      case TimelineEntryType.taskDue:
        return 'Task due date';
      case TimelineEntryType.taskReminder:
        return 'Task reminder';
      case TimelineEntryType.eventStart:
        return 'Event start';
      case TimelineEntryType.eventEnd:
        return 'Event end';
      case TimelineEntryType.eventRegistrationDeadline:
        return 'Registration deadline';
      case TimelineEntryType.eventSubmissionDeadline:
        return 'Submission deadline';
    }
  }
}
