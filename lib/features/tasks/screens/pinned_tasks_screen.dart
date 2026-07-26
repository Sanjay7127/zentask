import 'package:flutter/material.dart';
import 'package:zentask/features/projects/screens/project_details_screen.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';

/// All pinned tasks across every project (Phase 12) — a cross-project
/// view, unlike [ProjectTaskTile]'s per-project pin toggle which feeds
/// this screen's data.
class PinnedTasksScreen extends StatefulWidget {
  const PinnedTasksScreen({super.key});

  @override
  State<PinnedTasksScreen> createState() => _PinnedTasksScreenState();
}

class _PinnedTasksScreenState extends State<PinnedTasksScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  List<Task> _pinned = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _pinned = _taskRepository
          .getAllTaskRecords()
          .where((task) => task.isPinned)
          .toList()
        ..sort((a, b) => a.isDone == b.isDone ? 0 : (a.isDone ? 1 : -1));
    });
  }

  Future<void> _unpin(Task task) async {
    await _taskRepository.saveTaskRecord(task.copyWith(isPinned: false));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pinned Tasks')),
      body: _pinned.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Pin a task from any project to see it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.builder(
              itemCount: _pinned.length,
              itemBuilder: (context, index) {
                final task = _pinned[index];
                return ListTile(
                  leading: Icon(
                    task.isDone ? Icons.check_circle : Icons.push_pin,
                    color: task.isDone ? Colors.green : colorScheme.primary,
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(labelForPriority(task.priority)),
                  trailing: IconButton(
                    tooltip: 'Unpin',
                    icon: const Icon(Icons.push_pin_outlined),
                    onPressed: () => _unpin(task),
                  ),
                  onTap: task.projectId == null
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProjectDetailsScreen(projectId: task.projectId!),
                            ),
                          );
                          _reload();
                        },
                );
              },
            ),
    );
  }
}
