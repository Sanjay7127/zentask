import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/event.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late Box eventsBox;
  late TaskRepository taskRepository;
  late EventRepository eventRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_timeline_test');
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
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    await eventsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  TimelineEngine engine() => TimelineEngine(
        taskRepository: taskRepository,
        eventRepository: eventRepository,
      );

  test('aggregates task due dates and reminders', () async {
    await taskRepository.saveTaskRecord(Task.create(
      title: 'Submit report',
      dueDate: DateTime(2026, 8, 10),
    ));
    await taskRepository.saveTaskRecord(Task.create(
      title: 'Prep slides',
      reminder: DateTime(2026, 8, 5),
    ));

    final timeline = engine().buildTimeline();

    expect(timeline.length, 2);
    expect(timeline[0].title, 'Prep slides');
    expect(timeline[0].type, TimelineEntryType.taskReminder);
    expect(timeline[1].title, 'Submit report');
    expect(timeline[1].type, TimelineEntryType.taskDue);
  });

  test('aggregates all four event date fields', () async {
    await eventRepository.save(Event.create(
      title: 'Hack Week',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 3),
      registrationDeadline: DateTime(2026, 8, 20),
      submissionDeadline: DateTime(2026, 9, 3, 23),
    ));

    final timeline = engine().buildTimeline();
    expect(timeline.length, 4);
    expect(
      timeline.map((e) => e.type).toSet(),
      {
        TimelineEntryType.eventRegistrationDeadline,
        TimelineEntryType.eventStart,
        TimelineEntryType.eventEnd,
        TimelineEntryType.eventSubmissionDeadline,
      },
    );
  });

  test('is sorted chronologically ascending', () async {
    await taskRepository
        .saveTaskRecord(Task.create(title: 'Later', dueDate: DateTime(2026, 12, 1)));
    await taskRepository
        .saveTaskRecord(Task.create(title: 'Sooner', dueDate: DateTime(2026, 1, 1)));

    final timeline = engine().buildTimeline();
    expect(timeline.first.title, 'Sooner');
    expect(timeline.last.title, 'Later');
  });

  test('filters by from/to window', () async {
    await taskRepository
        .saveTaskRecord(Task.create(title: 'Jan', dueDate: DateTime(2026, 1, 1)));
    await taskRepository
        .saveTaskRecord(Task.create(title: 'June', dueDate: DateTime(2026, 6, 1)));
    await taskRepository
        .saveTaskRecord(Task.create(title: 'Dec', dueDate: DateTime(2026, 12, 1)));

    final windowed = engine().buildTimeline(
      from: DateTime(2026, 3, 1),
      to: DateTime(2026, 9, 1),
    );

    expect(windowed.length, 1);
    expect(windowed.single.title, 'June');
  });

  test('empty repositories produce an empty timeline, no crash', () {
    expect(engine().buildTimeline(), isEmpty);
  });
}
