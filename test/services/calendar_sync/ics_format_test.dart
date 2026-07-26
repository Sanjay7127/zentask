import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/services/calendar_sync/ics_format.dart';

void main() {
  test('build produces a VCALENDAR with one VEVENT per entry', () {
    final ics = IcsFormat.build('ZenTask', [
      IcsEvent(
        uid: 'abc@zentask',
        summary: 'Submit report',
        description: 'Task due date',
        start: DateTime.utc(2026, 5, 1, 9),
      ),
    ]);

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('UID:abc@zentask'));
    expect(ics, contains('SUMMARY:Submit report'));
    expect(ics, contains('DTSTART:20260501T090000Z'));
    expect(ics, contains('END:VEVENT'));
    expect(ics, contains('END:VCALENDAR'));
  });

  test('escapes commas, semicolons, and newlines in text fields', () {
    // RFC 5545 only requires escaping backslash, comma, semicolon, and
    // newline within a TEXT value — a bare colon is not special there
    // (it only separates the property name from its value), so it's
    // deliberately left unescaped.
    final ics = IcsFormat.build('Cal', [
      IcsEvent(
        uid: 'x',
        summary: 'Buy: milk, eggs; bread\nand cheese',
        start: DateTime.utc(2026, 1, 1),
      ),
    ]);
    expect(ics, contains(r'SUMMARY:Buy: milk\, eggs\; bread\nand cheese'));
  });

  test('parse reads UID/SUMMARY/DESCRIPTION/DTSTART/DTEND back out', () {
    const raw = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:event-1@example.com
DTSTART:20260610T140000Z
DTEND:20260610T150000Z
SUMMARY:Team sync
DESCRIPTION:Weekly check-in
END:VEVENT
END:VCALENDAR
''';

    final events = IcsFormat.parse(raw);

    expect(events, hasLength(1));
    final event = events.single;
    expect(event.uid, 'event-1@example.com');
    expect(event.summary, 'Team sync');
    expect(event.description, 'Weekly check-in');
    expect(event.start, DateTime.utc(2026, 6, 10, 14));
    expect(event.end, DateTime.utc(2026, 6, 10, 15));
    expect(event.isAllDay, false);
  });

  test('parse handles folded (continuation) lines per RFC 5545', () {
    const raw = 'BEGIN:VCALENDAR\r\n'
        'BEGIN:VEVENT\r\n'
        'UID:folded@example.com\r\n'
        'DTSTART:20260101T000000Z\r\n'
        'SUMMARY:This is a long summary that got\r\n'
        ' folded across multiple lines\r\n'
        'END:VEVENT\r\n'
        'END:VCALENDAR\r\n';

    final events = IcsFormat.parse(raw);

    expect(events.single.summary, 'This is a long summary that gotfolded across multiple lines');
  });

  test('parse handles all-day (VALUE=DATE) events', () {
    const raw = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:allday@example.com
DTSTART;VALUE=DATE:20260704
SUMMARY:Holiday
END:VEVENT
END:VCALENDAR
''';

    final events = IcsFormat.parse(raw);

    expect(events.single.isAllDay, true);
    expect(events.single.start, DateTime(2026, 7, 4));
  });

  test('a full build/parse round-trip preserves the event', () {
    final original = IcsEvent(
      uid: 'roundtrip@zentask',
      summary: 'Design review',
      description: 'Bring mockups',
      start: DateTime.utc(2026, 8, 15, 10, 30),
      end: DateTime.utc(2026, 8, 15, 11, 30),
    );

    final ics = IcsFormat.build('ZenTask', [original]);
    final parsed = IcsFormat.parse(ics).single;

    expect(parsed.uid, original.uid);
    expect(parsed.summary, original.summary);
    expect(parsed.description, original.description);
    expect(parsed.start, original.start);
    expect(parsed.end, original.end);
  });
}
