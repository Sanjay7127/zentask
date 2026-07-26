import 'package:flutter/material.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/models/label.dart';
import 'package:zentask/models/task.dart';

enum ProjectTaskAction { edit, move, delete, togglePin }

/// A single rich task row within a Project Details screen. Distinct
/// from the existing `TaskTile` (used by the legacy Tasks tab list) —
/// this shows priority/due date/reminder and supports edit/move/delete
/// rather than just complete/swipe-delete, which don't map cleanly onto
/// `TaskTile`'s simpler contract.
class ProjectTaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<ProjectTaskAction> onAction;
  final List<Label> labels;

  const ProjectTaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onAction,
    this.labels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final overdue = !task.isDone &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: onToggle,
        ),
        title: Row(
          children: [
            if (task.isPinned) ...[
              Icon(Icons.push_pin, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colorForPriority(task.priority, colorScheme)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labelForPriority(task.priority),
                style: TextStyle(
                  fontSize: 11,
                  color: colorForPriority(task.priority, colorScheme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (task.dueDate != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event,
                      size: 12,
                      color: overdue ? colorScheme.error : colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(
                    _formatDate(task.dueDate!),
                    style: textTheme.bodySmall?.copyWith(
                      color: overdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            if (task.reminder != null)
              Icon(Icons.notifications_active_outlined,
                  size: 12, color: colorScheme.onSurfaceVariant),
            if (task.recurrence != null &&
                task.recurrence!.frequency != RecurrenceFrequency.none)
              Icon(Icons.repeat, size: 12, color: colorScheme.onSurfaceVariant),
            for (final label in labels)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Color(label.colorValue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label.name,
                  style: TextStyle(fontSize: 11, color: Color(label.colorValue)),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<ProjectTaskAction>(
          onSelected: onAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ProjectTaskAction.togglePin,
              child: Text(task.isPinned ? 'Unpin' : 'Pin'),
            ),
            const PopupMenuItem(value: ProjectTaskAction.edit, child: Text('Edit')),
            const PopupMenuItem(value: ProjectTaskAction.move, child: Text('Move')),
            const PopupMenuItem(
                value: ProjectTaskAction.delete, child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
