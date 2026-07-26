import 'package:zentask/utils/id_generator.dart';

enum EventType {
  hackathon,
  competition,
  workshop,
  conference,
  meetup,
  internship,
  certification,

  /// Catch-all for events that don't fit the categories above — notably
  /// ICS imports (Phase 11), which have no equivalent concept to map to.
  other,
}

/// A Competition, Hackathon, Event, or similar opportunity that a
/// [Project] can optionally link to (see [Project.linkedEventId] /
/// [linkedProjectId]).
///
/// Deliberately does **not** store a computed `status` (upcoming/
/// ongoing/ended, registration open/closed) — that's derived from the
/// date fields below by the Events module (Phase 3.4), for the same
/// stale-cache reason [Project] doesn't store its completion
/// percentage.
///
/// `bookmarked` is intentionally simple this phase: a plain field on the
/// event's own record. Phase 3 also asks for a dedicated `bookmarks`
/// Hive box; `BookmarksRepository` exists as a generic bookmark store
/// for future entity types, but nothing cross-references it against
/// this field yet — that reconciliation is deferred to the Events
/// module (3.4) and documented here as a known overlap, not fixed now.
class Event {
  final String id;
  final String title;
  final String platform;
  final EventType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationDeadline;
  final DateTime? submissionDeadline;
  final String? eventUrl;
  final String? location;
  final String description;
  final String? logo;
  final int colorValue;
  final bool bookmarked;
  final String? linkedProjectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.platform = '',
    this.type = EventType.hackathon,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.submissionDeadline,
    this.eventUrl,
    this.location,
    this.description = '',
    this.logo,
    this.colorValue = 0xFF01D1AF,
    this.bookmarked = false,
    this.linkedProjectId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.create({
    required String title,
    String platform = '',
    EventType type = EventType.hackathon,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    DateTime? submissionDeadline,
    String? eventUrl,
    String? location,
    String description = '',
    String? logo,
    int colorValue = 0xFF01D1AF,
  }) {
    final now = DateTime.now();
    return Event(
      id: generateId(),
      title: title,
      platform: platform,
      type: type,
      startDate: startDate,
      endDate: endDate,
      registrationDeadline: registrationDeadline,
      submissionDeadline: submissionDeadline,
      eventUrl: eventUrl,
      location: location,
      description: description,
      logo: logo,
      colorValue: colorValue,
      createdAt: now,
      updatedAt: now,
    );
  }

  Event copyWith({
    String? title,
    String? platform,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    DateTime? submissionDeadline,
    String? eventUrl,
    String? location,
    String? description,
    String? logo,
    int? colorValue,
    bool? bookmarked,
    String? linkedProjectId,
  }) =>
      Event(
        id: id,
        title: title ?? this.title,
        platform: platform ?? this.platform,
        type: type ?? this.type,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        registrationDeadline:
            registrationDeadline ?? this.registrationDeadline,
        submissionDeadline: submissionDeadline ?? this.submissionDeadline,
        eventUrl: eventUrl ?? this.eventUrl,
        location: location ?? this.location,
        description: description ?? this.description,
        logo: logo ?? this.logo,
        colorValue: colorValue ?? this.colorValue,
        bookmarked: bookmarked ?? this.bookmarked,
        linkedProjectId: linkedProjectId ?? this.linkedProjectId,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'platform': platform,
        'type': type.name,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'registrationDeadline': registrationDeadline?.toIso8601String(),
        'submissionDeadline': submissionDeadline?.toIso8601String(),
        'eventUrl': eventUrl,
        'location': location,
        'description': description,
        'logo': logo,
        'colorValue': colorValue,
        'bookmarked': bookmarked,
        'linkedProjectId': linkedProjectId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Event.fromMap(Map<dynamic, dynamic> map) => Event(
        id: map['id'] as String,
        title: map['title'] as String,
        platform: map['platform'] as String? ?? '',
        type: EventType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => EventType.hackathon,
        ),
        startDate: map['startDate'] != null
            ? DateTime.parse(map['startDate'] as String)
            : null,
        endDate: map['endDate'] != null
            ? DateTime.parse(map['endDate'] as String)
            : null,
        registrationDeadline: map['registrationDeadline'] != null
            ? DateTime.parse(map['registrationDeadline'] as String)
            : null,
        submissionDeadline: map['submissionDeadline'] != null
            ? DateTime.parse(map['submissionDeadline'] as String)
            : null,
        eventUrl: map['eventUrl'] as String?,
        location: map['location'] as String?,
        description: map['description'] as String? ?? '',
        logo: map['logo'] as String?,
        colorValue: map['colorValue'] as int? ?? 0xFF01D1AF,
        bookmarked: map['bookmarked'] as bool? ?? false,
        linkedProjectId: map['linkedProjectId'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
