import 'package:flutter/material.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';

enum ProjectCardAction { edit, archive, restore, delete }

/// A single project summary card for the Projects dashboard: icon,
/// name, progress bar, completed/total tasks, nearest due date, and
/// priority.
class ProjectCard extends StatelessWidget {
  final Project project;
  final int completedTaskCount;
  final int totalTaskCount;
  final double completionRate;
  final Task? nextUpcomingTask;
  final VoidCallback onTap;
  final ValueChanged<ProjectCardAction> onAction;

  const ProjectCard({
    super.key,
    required this.project,
    required this.completedTaskCount,
    required this.totalTaskCount,
    required this.completionRate,
    required this.nextUpcomingTask,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final projectColor = colorForValue(project.colorValue);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'project-avatar-${project.id}',
                    child: CircleAvatar(
                      backgroundColor: projectColor.withValues(alpha: 0.15),
                      foregroundColor: projectColor,
                      child: Icon(iconForKey(project.iconKey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project.isArchived)
                          Text(
                            'Archived',
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<ProjectCardAction>(
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: ProjectCardAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: project.isArchived
                            ? ProjectCardAction.restore
                            : ProjectCardAction.archive,
                        child: Text(project.isArchived ? 'Restore' : 'Archive'),
                      ),
                      const PopupMenuItem(
                        value: ProjectCardAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completionRate,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(projectColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedTaskCount / $totalTaskCount tasks',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  _PriorityChip(priority: project.priority),
                ],
              ),
              if (nextUpcomingTask?.dueDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Due ${_formatDate(nextUpcomingTask!.dueDate!)}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
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

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorForPriority(priority, colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labelForPriority(priority),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
