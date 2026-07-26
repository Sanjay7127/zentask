import 'package:flutter/material.dart';
import 'package:zentask/models/label.dart';
import 'package:zentask/repositories/label_repository.dart';

/// Manage custom Labels (Phase 12) — create, rename/recolor, delete.
/// Labels are attached to tasks via [Task.labelIds] from
/// `TaskFormDialog`; this screen only manages the label set itself.
class LabelsScreen extends StatefulWidget {
  const LabelsScreen({super.key});

  @override
  State<LabelsScreen> createState() => _LabelsScreenState();
}

const List<int> _labelColorPalette = [
  0xFF01D1AF, 0xFF3F51B5, 0xFFE91E63, 0xFFFF9800,
  0xFF8E24AA, 0xFF2196F3, 0xFF43A047, 0xFFE53935,
];

class _LabelsScreenState extends State<LabelsScreen> {
  final LabelRepository _repository = LabelRepository();
  List<Label> _labels = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _labels = _repository.getAll());

  Future<void> _createOrEdit({Label? existing}) async {
    final result = await showDialog<_LabelFormResult>(
      context: context,
      builder: (_) => _LabelFormDialog(existing: existing),
    );
    if (result == null) return;
    final label = existing != null
        ? existing.copyWith(name: result.name, colorValue: result.colorValue)
        : Label.create(name: result.name, colorValue: result.colorValue);
    await _repository.save(label);
    _reload();
  }

  Future<void> _delete(Label label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete label?'),
        content: Text(
            '"${label.name}" will be removed. Tasks keep their other labels.'),
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
      await _repository.delete(label.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Labels')),
      body: _labels.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No labels yet — create one to tag tasks with it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.builder(
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                final label = _labels[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(label.colorValue),
                    radius: 12,
                  ),
                  title: Text(label.name),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _createOrEdit(existing: label);
                      if (value == 'delete') _delete(label);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(),
        tooltip: 'New label',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LabelFormResult {
  final String name;
  final int colorValue;
  const _LabelFormResult(this.name, this.colorValue);
}

class _LabelFormDialog extends StatefulWidget {
  final Label? existing;
  const _LabelFormDialog({this.existing});

  @override
  State<_LabelFormDialog> createState() => _LabelFormDialogState();
}

class _LabelFormDialogState extends State<_LabelFormDialog> {
  late final TextEditingController _nameController;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _colorValue = widget.existing?.colorValue ?? _labelColorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Label' : 'Edit Label'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          const Text('Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _labelColorPalette.map((value) {
              final selected = value == _colorValue;
              return Semantics(
                label: 'Color option',
                selected: selected,
                button: true,
                child: InkWell(
                  onTap: () => setState(() => _colorValue = value),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
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
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(_LabelFormResult(name, _colorValue));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
