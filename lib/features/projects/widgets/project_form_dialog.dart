import 'package:flutter/material.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';

/// Fields collected by [showProjectFormDialog]. Deliberately decoupled
/// from any controller — the caller decides whether this becomes a
/// `createProject` or `updateProject` call.
class ProjectFormResult {
  final String title;
  final String description;
  final int colorValue;
  final String iconKey;
  final ProjectCategory category;
  final TaskPriority priority;

  const ProjectFormResult({
    required this.title,
    required this.description,
    required this.colorValue,
    required this.iconKey,
    required this.category,
    required this.priority,
  });
}

/// Shows the create/edit project dialog. Pass [existing] to prefill for
/// editing; omit it to create a new project. Returns `null` if
/// cancelled.
Future<ProjectFormResult?> showProjectFormDialog(
  BuildContext context, {
  Project? existing,
}) {
  return showDialog<ProjectFormResult>(
    context: context,
    builder: (_) => _ProjectFormDialog(existing: existing),
  );
}

class _ProjectFormDialog extends StatefulWidget {
  final Project? existing;
  const _ProjectFormDialog({this.existing});

  @override
  State<_ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<_ProjectFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _colorValue;
  late String _iconKey;
  late ProjectCategory _category;
  late TaskPriority _priority;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _colorValue = existing?.colorValue ?? projectColorPalette.first;
    _iconKey = existing?.iconKey ?? 'folder';
    _category = existing?.category ?? ProjectCategory.other;
    _priority = existing?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    Navigator.of(context).pop(ProjectFormResult(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      colorValue: _colorValue,
      iconKey: _iconKey,
      category: _category,
      priority: _priority,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Project' : 'New Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: projectColorPalette.map((value) {
                final selected = value == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = value),
                  child: CircleAvatar(
                    backgroundColor: colorForValue(value),
                    radius: selected ? 18 : 14,
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: projectIconsByKey.entries.map((entry) {
                final selected = entry.key == _iconKey;
                final colorScheme = Theme.of(context).colorScheme;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _iconKey = entry.key),
                  child: CircleAvatar(
                    backgroundColor: selected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor:
                        selected ? colorScheme.onPrimary : colorScheme.onSurface,
                    child: Icon(entry.value),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProjectCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ProjectCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(_categoryLabel(c)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            const Text('Priority'),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: TaskPriority.values
                  .map((p) => ButtonSegment(
                        value: p,
                        label: Text(labelForPriority(p)),
                      ))
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (selection) =>
                  setState(() => _priority = selection.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  String _categoryLabel(ProjectCategory category) {
    switch (category) {
      case ProjectCategory.work:
        return 'Work';
      case ProjectCategory.personal:
        return 'Personal';
      case ProjectCategory.hackathon:
        return 'Hackathon';
      case ProjectCategory.study:
        return 'Study';
      case ProjectCategory.other:
        return 'Other';
    }
  }
}
