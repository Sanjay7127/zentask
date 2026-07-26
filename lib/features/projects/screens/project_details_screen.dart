import 'package:flutter/material.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/features/projects/widgets/project_task_tile.dart';
import 'package:zentask/features/projects/widgets/task_form_dialog.dart';
import 'package:zentask/models/label.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/project_detail_controller.dart';
import 'package:zentask/repositories/label_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late final ProjectDetailController _controller;
  final ProjectRepository _projectRepository = ProjectRepository();
  final LabelRepository _labelRepository = LabelRepository();

  @override
  void initState() {
    super.initState();
    _controller = ProjectDetailController(projectId: widget.projectId);
    _controller.addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  List<Label> _labelsFor(Task task) {
    if (task.labelIds.isEmpty) return const [];
    final all = _labelRepository.getAll();
    return all.where((label) => task.labelIds.contains(label.id)).toList();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    final result = await showTaskFormDialog(context);
    if (result == null) return;
    await _controller.createTask(
      title: result.title,
      description: result.description,
      priority: result.priority,
      dueDate: result.dueDate,
      reminder: result.reminder,
      tags: result.tags,
      recurrence: result.recurrence,
      labelIds: result.labelIds,
    );
  }

  Future<void> _editTask(Task task) async {
    final result = await showTaskFormDialog(context, existing: task);
    if (result == null) return;
    await _controller.updateTask(
      task,
      title: result.title,
      description: result.description,
      priority: result.priority,
      dueDate: result.dueDate,
      clearDueDate: result.dueDate == null,
      reminder: result.reminder,
      clearReminder: result.reminder == null,
      tags: result.tags,
      recurrence: result.recurrence,
      labelIds: result.labelIds,
    );
  }

  Future<void> _moveTask(Task task) async {
    final others = _projectRepository
        .getAll()
        .where((p) => p.id != widget.projectId)
        .toList();

    final choice = await showDialog<String?>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Move task to...'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('No project (unassign)'),
          ),
          ...others.map((p) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(p.id),
                child: Text(p.title),
              )),
        ],
      ),
    );

    if (choice == null) return;
    await _controller.moveTask(task, choice.isEmpty ? null : choice);
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteTask(task);
    }
  }

  Future<void> _editProjectInfo(Project project) async {
    // Reuses the same info the Projects dashboard edits — kept minimal
    // here (title/description only) since color/icon/category editing
    // already has a full dialog on the dashboard; jumping there avoids
    // building a second, near-identical form.
    final titleController = TextEditingController(text: project.title);
    final descriptionController =
        TextEditingController(text: project.description);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Project Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _controller.updateProjectInfo(project.copyWith(
        title: titleController.text.trim().isEmpty
            ? project.title
            : titleController.text.trim(),
        description: descriptionController.text.trim(),
      ));
    }
  }

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete project?'),
        content: const Text(
          'This project will be removed. Its tasks are kept, unassigned from any project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteProject();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _controller.project;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(child: Text('This project no longer exists.')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final projectColor = colorForValue(project.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editProjectInfo(project);
                  break;
                case 'archive':
                  _controller.archiveProject();
                  break;
                case 'restore':
                  _controller.restoreProject();
                  break;
                case 'delete':
                  _deleteProject();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Info')),
              PopupMenuItem(
                value: project.isArchived ? 'restore' : 'archive',
                child: Text(project.isArchived ? 'Restore Project' : 'Archive Project'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete Project')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Hero(
                tag: 'project-avatar-${project.id}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: projectColor.withValues(alpha: 0.15),
                  foregroundColor: projectColor,
                  child: Icon(iconForKey(project.iconKey), size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title, style: textTheme.headlineSmall),
                    if (project.isArchived)
                      Text('Archived',
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorForPriority(project.priority, colorScheme)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  labelForPriority(project.priority),
                  style: TextStyle(
                    color: colorForPriority(project.priority, colorScheme),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _controller.completionRate,
              minHeight: 10,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(projectColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_controller.completedTaskCount} / ${_controller.totalTaskCount} tasks completed '
            '(${(_controller.completionRate * 100).round()}%)',
            style:
                textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _StatisticsRow(controller: _controller),
          const SizedBox(height: 24),
          Text('Notes', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            project.description.isEmpty
                ? 'No notes yet. Use Edit Info to add some.'
                : project.description,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Timeline', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_controller.projectTimeline.isEmpty)
            Text('Nothing scheduled yet.',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant))
          else
            ..._controller.projectTimeline.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconForTimelineEntry(entry.type)),
                  title: Text(entry.title),
                  subtitle: Text(_formatDateTime(entry.date)),
                )),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tasks', style: textTheme.titleMedium),
              TextButton.icon(
                onPressed: _createTask,
                icon: const Icon(Icons.add),
                label: const Text('Add task'),
              ),
            ],
          ),
          if (_controller.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No tasks in this project yet.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            )
          else
            ..._controller.tasks.map((task) => ProjectTaskTile(
                  task: task,
                  labels: _labelsFor(task),
                  onToggle: (value) => _controller.updateTask(
                    task,
                    isDone: value ?? false,
                  ),
                  onAction: (action) {
                    switch (action) {
                      case ProjectTaskAction.edit:
                        _editTask(task);
                        break;
                      case ProjectTaskAction.move:
                        _moveTask(task);
                        break;
                      case ProjectTaskAction.delete:
                        _deleteTask(task);
                        break;
                      case ProjectTaskAction.togglePin:
                        _controller.togglePin(task);
                        break;
                    }
                  },
                )),
        ],
      ),
    );
  }

  IconData _iconForTimelineEntry(TimelineEntryType type) {
    switch (type) {
      case TimelineEntryType.taskDue:
        return Icons.event;
      case TimelineEntryType.taskReminder:
        return Icons.notifications_active_outlined;
      case TimelineEntryType.eventStart:
      case TimelineEntryType.eventEnd:
      case TimelineEntryType.eventRegistrationDeadline:
      case TimelineEntryType.eventSubmissionDeadline:
        return Icons.event_note;
    }
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatisticsRow extends StatelessWidget {
  final ProjectDetailController controller;
  const _StatisticsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget stat(String label, String value, {Color? color}) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color ?? colorScheme.primary,
                  ),
                ),
                Text(
                  label,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        stat('Total', '${controller.totalTaskCount}'),
        const SizedBox(width: 8),
        stat('Completed', '${controller.completedTaskCount}'),
        const SizedBox(width: 8),
        stat('Overdue', '${controller.overdueTaskCount}',
            color: controller.overdueTaskCount > 0 ? colorScheme.error : null),
      ],
    );
  }
}
