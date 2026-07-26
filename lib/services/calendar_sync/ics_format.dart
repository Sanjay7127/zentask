/// Minimal RFC 5545 (iCalendar) VEVENT reader/writer — just enough to
/// round-trip ZenTask's timeline through the handful of properties
/// every calendar app reads: UID, SUMMARY, DESCRIPTION, DTSTART, DTEND.
/// Deliberately not a full RFC 5545 implementation (recurrence rules,
/// alarms, timezone components, etc. are out of scope) — real-world
/// .ics files from Google/Apple Calendar carry plenty this doesn't
/// touch, which is preserved as ignored rather than corrupted.
class IcsEvent {
  final String uid;
  final String summary;
  final String description;
  final DateTime start;
  final DateTime? end;
  final bool isAllDay;

  const IcsEvent({
    required this.uid,
    required this.summary,
    this.description = '',
    required this.start,
    this.end,
    this.isAllDay = false,
  });
}

class IcsFormat {
  IcsFormat._();

  static String build(String calendarName, List<IcsEvent> events) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//ZenTask//ZenTask Calendar//EN')
      ..writeln('X-WR-CALNAME:${_escape(calendarName)}');

    for (final event in events) {
      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${event.uid}')
        ..writeln(_dateLine('DTSTART', event.start, event.isAllDay))
        ..writeln('SUMMARY:${_escape(event.summary)}');
      if (event.end != null) {
        buffer.writeln(_dateLine('DTEND', event.end!, event.isAllDay));
      }
      if (event.description.isNotEmpty) {
        buffer.writeln('DESCRIPTION:${_escape(event.description)}');
      }
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static List<IcsEvent> parse(String icsContent) {
    final lines = _unfold(icsContent);
    final events = <IcsEvent>[];

    Map<String, String>? current;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'BEGIN:VEVENT') {
        current = {};
      } else if (trimmed == 'END:VEVENT') {
        if (current != null) {
          final event = _toEvent(current);
          if (event != null) events.add(event);
        }
        current = null;
      } else if (current != null) {
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex == -1) continue;
        final rawKey = trimmed.substring(0, colonIndex);
        final value = trimmed.substring(colonIndex + 1);
        final key = rawKey.split(';').first.toUpperCase();
        current[key] = value;
        if (rawKey.contains('VALUE=DATE')) current['${key}_ALLDAY'] = 'true';
      }
    }

    return events;
  }

  static IcsEvent? _toEvent(Map<String, String> props) {
    final dtStart = props['DTSTART'];
    if (dtStart == null) return null;
    final isAllDay = props['DTSTART_ALLDAY'] == 'true';
    final start = _parseDate(dtStart);
    if (start == null) return null;
    final dtEnd = props['DTEND'];

    return IcsEvent(
      uid: props['UID'] ?? '${start.microsecondsSinceEpoch}',
      summary: _unescape(props['SUMMARY'] ?? 'Untitled'),
      description: _unescape(props['DESCRIPTION'] ?? ''),
      start: start,
      end: dtEnd != null ? _parseDate(dtEnd) : null,
      isAllDay: isAllDay,
    );
  }

  /// Un-does RFC 5545 line folding: a line beginning with a space or tab
  /// is a continuation of the previous line, not a new property.
  static List<String> _unfold(String content) {
    final rawLines = content.split(RegExp(r'\r\n|\n|\r'));
    final unfolded = <String>[];
    for (final line in rawLines) {
      if (line.startsWith(' ') || line.startsWith('\t')) {
        if (unfolded.isNotEmpty) {
          unfolded[unfolded.length - 1] += line.substring(1);
        }
      } else {
        unfolded.add(line);
      }
    }
    return unfolded;
  }

  static String _dateLine(String property, DateTime date, bool allDay) {
    if (allDay) {
      return '$property;VALUE=DATE:${_formatDateOnly(date)}';
    }
    return '$property:${_formatDateTimeUtc(date)}';
  }

  static String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTimeUtc(DateTime date) {
    final utc = date.toUtc();
    return '${_formatDateOnly(utc)}T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  static DateTime? _parseDate(String value) {
    try {
      if (RegExp(r'^\d{8}$').hasMatch(value)) {
        return DateTime(
          int.parse(value.substring(0, 4)),
          int.parse(value.substring(4, 6)),
          int.parse(value.substring(6, 8)),
        );
      }
      final cleaned = value.replaceAll('Z', '');
      final year = int.parse(cleaned.substring(0, 4));
      final month = int.parse(cleaned.substring(4, 6));
      final day = int.parse(cleaned.substring(6, 8));
      final hour = int.parse(cleaned.substring(9, 11));
      final minute = int.parse(cleaned.substring(11, 13));
      final second = int.parse(cleaned.substring(13, 15));
      final utc = DateTime.utc(year, month, day, hour, minute, second);
      return value.endsWith('Z') ? utc : utc.toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _escape(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');

  static String _unescape(String text) => text
      .replaceAll('\\n', '\n')
      .replaceAll('\\,', ',')
      .replaceAll('\\;', ';')
      .replaceAll('\\\\', '\\');
}
