import 'package:flutter/material.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

/// UI-layer mapping from [TimelineEntryType] to icon/label/color —
/// mirrors `project_visuals.dart`'s split between Flutter-light
/// providers/models and this kind of presentation mapping living in the
/// feature's own `utils/`.
IconData iconForEntryType(TimelineEntryType type) {
  switch (type) {
    case TimelineEntryType.taskDue:
      return Icons.task_alt;
    case TimelineEntryType.taskReminder:
      return Icons.notifications_outlined;
    case TimelineEntryType.eventStart:
      return Icons.flag_outlined;
    case TimelineEntryType.eventEnd:
      return Icons.outlined_flag;
    case TimelineEntryType.eventRegistrationDeadline:
      return Icons.how_to_reg_outlined;
    case TimelineEntryType.eventSubmissionDeadline:
      return Icons.upload_file_outlined;
  }
}

String labelForEntryType(TimelineEntryType type) {
  switch (type) {
    case TimelineEntryType.taskDue:
      return 'Task due';
    case TimelineEntryType.taskReminder:
      return 'Reminder';
    case TimelineEntryType.eventStart:
      return 'Event starts';
    case TimelineEntryType.eventEnd:
      return 'Event ends';
    case TimelineEntryType.eventRegistrationDeadline:
      return 'Registration deadline';
    case TimelineEntryType.eventSubmissionDeadline:
      return 'Submission deadline';
  }
}

/// Fallback color for an entry with no project of its own (or an event
/// entry, which never has one) — used whenever
/// `CalendarController.colorValueForEntry` returns `null`.
Color defaultColorForEntryType(TimelineEntryType type, ColorScheme colorScheme) {
  switch (type) {
    case TimelineEntryType.taskDue:
      return colorScheme.primary;
    case TimelineEntryType.taskReminder:
      return colorScheme.tertiary;
    case TimelineEntryType.eventStart:
      return colorScheme.secondary;
    case TimelineEntryType.eventEnd:
      return colorScheme.secondary;
    case TimelineEntryType.eventRegistrationDeadline:
      return Colors.orange.shade700;
    case TimelineEntryType.eventSubmissionDeadline:
      return Colors.deepPurple;
  }
}

const List<String> weekdayAbbreviations = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

const List<String> monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatShortDate(DateTime date) =>
    '${monthAbbreviations[date.month - 1]} ${date.day}';

String formatMonthYear(DateTime date) =>
    '${monthNames[date.month - 1]} ${date.year}';

String formatTimeOfDay(DateTime date) {
  final hour = date.hour == 0
      ? 12
      : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
