import 'package:flutter/material.dart';
import 'package:zentask/models/goal.dart';
import 'package:zentask/repositories/goal_repository.dart';

/// Goal tracking (Phase 12): a target value, current progress, and a
/// progress bar. Increment progress inline or edit the goal outright.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalRepository _repository = GoalRepository();
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _goals = _repository.getAll());

  Future<void> _createOrEdit({Goal? existing}) async {
    final result = await showDialog<_GoalFormResult>(
      context: context,
      builder: (_) => _GoalFormDialog(existing: existing),
    );
    if (result == null) return;
    final goal = existing != null
        ? existing.copyWith(
            title: result.title,
            description: result.description,
            targetValue: result.targetValue,
          )
        : Goal.create(
            title: result.title,
            description: result.description,
            targetValue: result.targetValue,
          );
    await _repository.save(goal);
    _reload();
  }

  Future<void> _incrementProgress(Goal goal) async {
    await _repository.save(goal.copyWith(
      currentValue: (goal.currentValue + 1).clamp(0, goal.targetValue),
    ));
    _reload();
  }

  Future<void> _deleteGoal(Goal goal) async {
    await _repository.delete(goal.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: _goals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No goals yet — set a target to track progress toward.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(goal.title,
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                            if (goal.isComplete)
                              Icon(Icons.emoji_events, color: colorScheme.primary),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _createOrEdit(existing: goal);
                                if (value == 'delete') _deleteGoal(goal);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                        if (goal.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(goal.description,
                                style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ),
                        Semantics(
                          label:
                              '${goal.title} progress: ${goal.currentValue.toStringAsFixed(0)} of ${goal.targetValue.toStringAsFixed(0)}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: goal.progress,
                              minHeight: 8,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${goal.currentValue.toStringAsFixed(0)} / ${goal.targetValue.toStringAsFixed(0)}',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                            if (!goal.isComplete)
                              TextButton(
                                onPressed: () => _incrementProgress(goal),
                                child: const Text('+1'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(),
        tooltip: 'New goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalFormResult {
  final String title;
  final String description;
  final double targetValue;
  const _GoalFormResult(this.title, this.description, this.targetValue);
}

class _GoalFormDialog extends StatefulWidget {
  final Goal? existing;
  const _GoalFormDialog({this.existing});

  @override
  State<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends State<_GoalFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _targetController = TextEditingController(
        text: widget.existing?.targetValue.toStringAsFixed(0) ?? '10');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Goal' : 'Edit Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Target value'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            final target = double.tryParse(_targetController.text.trim());
            if (title.isEmpty || target == null || target <= 0) return;
            Navigator.of(context).pop(
              _GoalFormResult(title, _descriptionController.text.trim(), target),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
