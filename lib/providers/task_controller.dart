import 'package:flutter/foundation.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';

/// Business-logic layer for the task list.
///
/// Owns the in-memory list and delegates persistence to [TaskRepository];
/// the UI (`HomeScreen`) talks only to this controller, never to Hive or
/// the repository directly. A plain [ChangeNotifier] (Flutter SDK, no new
/// dependency) — not the `provider` package.
///
/// Mirrors the exact mutation logic the UI used to perform inline in
/// `home.dart`'s `checkboxchanged`/`savenewtask`/`deletetask` methods.
class TaskController extends ChangeNotifier {
  final TaskRepository _repository;
  List<Task> _tasks = [];

  TaskController({TaskRepository? repository})
      : _repository = repository ?? TaskRepository();

  List<Task> get tasks => List.unmodifiable(_tasks);

  void addTask(String title) {
    if (title.isEmpty) return;
    _tasks = [..._tasks, Task(title: title, isDone: false)];
    _repository.saveTasks(_tasks);
    notifyListeners();
  }

  void toggleTask(int index) {
    final updated = [..._tasks];
    updated[index] = updated[index].copyWith(isDone: !updated[index].isDone);
    _tasks = updated;
    _repository.saveTasks(_tasks);
    notifyListeners();
  }

  void deleteTask(int index) {
    final updated = [..._tasks]..removeAt(index);
    _tasks = updated;
    _repository.saveTasks(_tasks);
    notifyListeners();
  }
}
