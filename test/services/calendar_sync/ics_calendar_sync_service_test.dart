import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/event.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/calendar_sync/ics_calendar_sync_service.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late Box eventsBox;
  late TaskRepository taskRepository;
  late EventRepository eventRepository;
  late IcsCalendarSyncService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_ics_service_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    eventsBox = await Hive.openBox('events_test');
    taskRepository = TaskRepository(
      box: legacyBox,
      recordsBox: recordsBox,
      settingsBox: settingsBox,
    );
    eventRepository = EventRepository(box: eventsBox);
    service = IcsCalendarSyncService(
      timelineEngine: TimelineEngine(
        taskRepository: taskRepository,
        eventRepository: eventRepository,
      ),
      eventRepository: eventRepository,
    );
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await eventsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('isAvailable is always true — no credentials needed', () {
    expect(service.isAvailable, true);
  });

  test('exportAll includes a task\'s due date as a VEVENT', () async {
    await taskRepository.saveTaskRecord(
      Task.create(title: 'Submit report', dueDate: DateTime(2026, 5, 1, 9)),
    );

    final ics = await service.exportAll();

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('SUMMARY:Submit report'));
  });

  test('exportAll on an empty timeline still produces a valid empty calendar',
      () async {
    final ics = await service.exportAll();
    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('END:VCALENDAR'));
    expect(ics, isNot(contains('BEGIN:VEVENT')));
  });

  test('importFrom creates one Event per VEVENT and returns the count',
      () async {
    const ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:e1@example.com
DTSTART:20260610T140000Z
DTEND:20260610T150000Z
SUMMARY:Team sync
END:VEVENT
BEGIN:VEVENT
UID:e2@example.com
DTSTART:20260611T140000Z
SUMMARY:Follow-up
END:VEVENT
END:VCALENDAR
''';

    final count = await service.importFrom(ics);

    expect(count, 2);
    final events = eventRepository.getAll();
    expect(events, hasLength(2));
    expect(events.map((e) => e.title), containsAll(['Team sync', 'Follow-up']));
    expect(events.every((e) => e.type == EventType.other), true);
  });
}
