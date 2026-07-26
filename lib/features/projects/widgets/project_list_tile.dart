import 'package:flutter/material.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/features/projects/widgets/project_card.dart';
import 'package:zentask/models/project.dart';

/// Compact horizontal row for the Projects screen's list view — the
/// same information as [ProjectCard] (icon, progress, task counts,
/// priority), laid out for a dense list rather than a grid. Reuses
/// [ProjectCardAction] rather than a second action enum.
class ProjectListTile extends StatelessWidget {
  final Project project;
  final int completedTaskCount;
  final int totalTaskCount;
  final double completionRate;
  final VoidCallback onTap;
  final ValueChanged<ProjectCardAction> onAction;

  const ProjectListTile({
    super.key,
    required this.project,
    required this.completedTaskCount,
    required this.totalTaskCount,
    required this.completionRate,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final projectColor = colorForValue(project.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Hero(
          tag: 'project-avatar-${project.id}',
          child: CircleAvatar(
            backgroundColor: projectColor.withValues(alpha: 0.15),
            foregroundColor: projectColor,
            child: Icon(iconForKey(project.iconKey)),
          ),
        ),
        title: Text(
          project.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completionRate,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(projectColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedTaskCount / $totalTaskCount tasks'
                '${project.isArchived ? ' • Archived' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<ProjectCardAction>(
          onSelected: onAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: ProjectCardAction.edit, child: Text('Edit')),
            PopupMenuItem(
              value: project.isArchived
                  ? ProjectCardAction.restore
                  : ProjectCardAction.archive,
              child: Text(project.isArchived ? 'Restore' : 'Archive'),
            ),
            const PopupMenuItem(
                value: ProjectCardAction.delete, child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
