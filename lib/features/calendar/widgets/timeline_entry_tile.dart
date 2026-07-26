import 'package:flutter/material.dart';
import 'package:zentask/features/calendar/utils/calendar_visuals.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

/// A single row for a [TimelineEntry], shared by the Calendar's Week and
/// Agenda views so the "how does one entry look" logic lives in one
/// reusable widget instead of being duplicated per view.
class TimelineEntryTile extends StatelessWidget {
  final TimelineEntry entry;
  final Color color;
  final bool completed;
  final bool overdue;

  const TimelineEntryTile({
    super.key,
    required this.entry,
    required this.color,
    required this.completed,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusSuffix = completed
        ? ', completed'
        : overdue
            ? ', overdue'
            : '';

    return Semantics(
      label:
          '${labelForEntryType(entry.type)}: ${entry.title}, ${formatTimeOfDay(entry.date)}$statusSuffix',
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Icon(iconForEntryType(entry.type), size: 18),
        ),
        title: Text(
          entry.title,
          style: completed
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle:
            Text('${labelForEntryType(entry.type)} • ${formatTimeOfDay(entry.date)}'),
        trailing: overdue
            ? Icon(Icons.warning_amber_rounded, color: colorScheme.error)
            : completed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
      ),
    );
  }
}
