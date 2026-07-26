import 'package:flutter/material.dart';
import 'package:zentask/models/habit.dart';
import 'package:zentask/repositories/habit_repository.dart';

/// Habit tracking (Phase 12): daily/weekly check-ins with a streak
/// counter, reusing the same streak rule as `AnalyticsEngine` (Phase 10).
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final HabitRepository _repository = HabitRepository();
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _habits = _repository.getAll());

  Future<void> _createHabit() async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Habit'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (title == null || title.isEmpty) return;
    await _repository.save(Habit.create(title: title));
    _reload();
  }

  Future<void> _deleteHabit(Habit habit) async {
    await _repository.delete(habit.id);
    _reload();
  }

  Future<void> _toggleToday(Habit habit) async {
    final today = DateTime.now();
    final isDone = _repository.isCompletedOn(habit.id, today);
    await _repository.setCompletedOn(habit.id, today, !isDone);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: _habits.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No habits yet — add one to start building a streak.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.builder(
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                final doneToday =
                    _repository.isCompletedOn(habit.id, DateTime.now());
                final streak = _repository.currentStreakFor(habit.id);
                return ListTile(
                  leading: Semantics(
                    label: '${habit.title}, ${doneToday ? 'done' : 'not done'} today',
                    child: Checkbox(
                      value: doneToday,
                      onChanged: (_) => _toggleToday(habit),
                    ),
                  ),
                  title: Text(habit.title),
                  subtitle: Text(streak > 0
                      ? '$streak day${streak == 1 ? '' : 's'} streak'
                      : 'No current streak'),
                  trailing: IconButton(
                    tooltip: 'Delete habit',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteHabit(habit),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createHabit,
        tooltip: 'New habit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
