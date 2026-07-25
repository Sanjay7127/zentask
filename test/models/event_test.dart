import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/event.dart';

void main() {
  test('Event.create generates id and timestamps', () {
    final event = Event.create(title: 'Global Hack Week', type: EventType.hackathon);
    expect(event.id, isNotEmpty);
    expect(event.title, 'Global Hack Week');
    expect(event.bookmarked, false);
  });

  test('toMap/fromMap round-trips every field', () {
    final original = Event.create(
      title: 'AI Builders Hackathon',
      platform: 'Devpost',
      type: EventType.hackathon,
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 3),
      registrationDeadline: DateTime(2026, 8, 20),
      submissionDeadline: DateTime(2026, 9, 3, 23, 59),
      eventUrl: 'https://devpost.com/example',
      location: 'Online',
      description: 'Build something with AI',
      logo: 'assets/logo.png',
      colorValue: 0xFF112233,
    ).copyWith(bookmarked: true, linkedProjectId: 'proj-9');

    final restored = Event.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.title, 'AI Builders Hackathon');
    expect(restored.platform, 'Devpost');
    expect(restored.type, EventType.hackathon);
    expect(restored.startDate, DateTime(2026, 9, 1));
    expect(restored.endDate, DateTime(2026, 9, 3));
    expect(restored.registrationDeadline, DateTime(2026, 8, 20));
    expect(restored.submissionDeadline, DateTime(2026, 9, 3, 23, 59));
    expect(restored.eventUrl, 'https://devpost.com/example');
    expect(restored.location, 'Online');
    expect(restored.colorValue, 0xFF112233);
    expect(restored.bookmarked, true);
    expect(restored.linkedProjectId, 'proj-9');
  });

  test('fromMap tolerates missing optional fields', () {
    final minimal = {
      'id': 'e1',
      'title': 'Bare event',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    };

    final event = Event.fromMap(minimal);
    expect(event.title, 'Bare event');
    expect(event.type, EventType.hackathon);
    expect(event.startDate, isNull);
    expect(event.bookmarked, false);
  });
}
