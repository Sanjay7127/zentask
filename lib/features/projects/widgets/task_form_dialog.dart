import 'package:flutter/material.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/models/label.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/label_repository.dart';

/// Fields collected by [showTaskFormDialog]. Decoupled from any
/// controller, same reasoning as [ProjectFormResult].
class TaskFormResult {
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminder;
  final List<String> tags;
  final Recurrence recurrence;
  final List<String> labelIds;

  const TaskFormResult({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.reminder,
    required this.tags,
    this.recurrence = const Recurrence(),
    this.labelIds = const [],
  });
}

Future<TaskFormResult?> showTaskFormDialog(
  BuildContext context, {
  Task? existing,
}) {
  return showDialog<TaskFormResult>(
    context: context,
    builder: (_) => _TaskFormDialog(existing: existing),
  );
}

class _TaskFormDialog extends StatefulWidget {
  final Task? existing;
  const _TaskFormDialog({this.existing});

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  late TaskPriority _priority;
  DateTime? _dueDate;
  DateTime? _reminder;
  late RecurrenceFrequency _recurrenceFrequency;
  late int _recurrenceInterval;
  late List<String> _labelIds;
  late final List<Label> _availableLabels;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _tagsController =
        TextEditingController(text: (existing?.tags ?? const []).join(', '));
    _priority = existing?.priority ?? TaskPriority.medium;
    _dueDate = existing?.dueDate;
    _reminder = existing?.reminder;
    _recurrenceFrequency =
        existing?.recurrence?.frequency ?? RecurrenceFrequency.none;
    _recurrenceInterval = existing?.recurrence?.interval ?? 1;
    _labelIds = List.of(existing?.labelIds ?? const []);
    _availableLabels = LabelRepository().getAll();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminder ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminder ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _reminder =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    Navigator.of(context).pop(TaskFormResult(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      reminder: _reminder,
      tags: tags,
      recurrence: Recurrence(
        frequency: _recurrenceFrequency,
        interval: _recurrenceInterval,
      ),
      labelIds: _labelIds,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Task' : 'New Task'),
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
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
              ),
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
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_dueDate == null
                  ? 'No due date'
                  : 'Due ${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'),
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear due date',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
              onTap: _pickDueDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(_reminder == null
                  ? 'No reminder'
                  : 'Remind at ${_reminder!.year}-${_reminder!.month.toString().padLeft(2, '0')}-${_reminder!.day.toString().padLeft(2, '0')} ${_reminder!.hour.toString().padLeft(2, '0')}:${_reminder!.minute.toString().padLeft(2, '0')}'),
              trailing: _reminder == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear reminder',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _reminder = null),
                    ),
              onTap: _pickReminder,
            ),
            const SizedBox(height: 16),
            const Text('Repeat'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: RecurrenceFrequency.values.map((frequency) {
                return ChoiceChip(
                  label: Text(_recurrenceLabel(frequency)),
                  selected: _recurrenceFrequency == frequency,
                  onSelected: (_) =>
                      setState(() => _recurrenceFrequency = frequency),
                );
              }).toList(),
            ),
            if (_recurrenceFrequency != RecurrenceFrequency.none) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Every'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      initialValue: '$_recurrenceInterval',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          setState(() => _recurrenceInterval = parsed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_recurrenceUnit(_recurrenceFrequency)),
                ],
              ),
            ],
            if (_availableLabels.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Labels'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableLabels.map((label) {
                  final selected = _labelIds.contains(label.id);
                  return FilterChip(
                    label: Text(label.name),
                    selected: selected,
                    onSelected: (isSelected) => setState(() {
                      if (isSelected) {
                        _labelIds.add(label.id);
                      } else {
                        _labelIds.remove(label.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
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

  String _recurrenceLabel(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.none:
        return 'Never';
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
    }
  }

  String _recurrenceUnit(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _recurrenceInterval == 1 ? 'day' : 'days';
      case RecurrenceFrequency.weekly:
        return _recurrenceInterval == 1 ? 'week' : 'weeks';
      case RecurrenceFrequency.monthly:
        return _recurrenceInterval == 1 ? 'month' : 'months';
      case RecurrenceFrequency.none:
        return '';
    }
  }
}
