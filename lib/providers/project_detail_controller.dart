import 'package:flutter/foundation.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';
import 'package:zentask/services/reminders/local_notification_reminder_scheduler.dart';
import 'package:zentask/services/reminders/reminder_scheduler.dart';
import 'package:zentask/services/tasks/recurring_task_service.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

/// Business-logic layer for one project's detail screen: the project
/// record itself, its tasks, and the actions available on both.
///
/// Integrates two Phase 6 services directly, per this phase's brief to
/// "integrate the existing services" rather than duplicate them:
/// - [ReminderScheduler] — scheduling/cancelling a task's OS reminder
///   whenever its `reminder` field is set/cleared/the task is deleted.
/// - [TimelineEngine] — [projectTimeline] reuses it as-is and filters
///   the result to this project's own tasks (TimelineEngine has no
///   project-filtering built in, and didn't need one added just for
///   this — filtering its output here avoids touching that engine at
///   all).
class ProjectDetailController extends ChangeNotifier {
  final String projectId;
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;
  final AnalyticsEngine _analyticsEngine;
  final TimelineEngine _timelineEngine;
  final ReminderScheduler _reminderScheduler;
  final RecurringTaskService _recurringTaskService;

  Project? _project;
  List<Task> _tasks = [];

  ProjectDetailController({
    required this.projectId,
    ProjectRepository? projectRepository,
    TaskRepository? taskRepository,
    AnalyticsEngine? analyticsEngine,
    TimelineEngine? timelineEngine,
    ReminderScheduler? reminderScheduler,
    RecurringTaskService? recurringTaskService,
  })  : _projectRepository = projectRepository ?? ProjectRepository(),
        _taskRepository = taskRepository ?? TaskRepository(),
        _analyticsEngine = analyticsEngine ?? AnalyticsEngine(),
        _timelineEngine = timelineEngine ?? TimelineEngine(),
        _reminderScheduler =
            reminderScheduler ?? LocalNotificationReminderScheduler(),
        _recurringTaskService = recurringTaskService ?? const RecurringTaskService() {
    _reload();
  }

  Project? get project => _project;

  List<Task> get tasks => List.unmodifiable(_tasks);

  int get totalTaskCount => _tasks.length;

  int get completedTaskCount => _tasks.where((t) => t.isDone).length;

  int get overdueTaskCount {
    final now = DateTime.now();
    return _tasks
        .where((t) => !t.isDone && t.dueDate != null && t.dueDate!.isBefore(now))
        .length;
  }

  double get completionRate => _analyticsEngine.projectCompletionRate(projectId);

  /// This project's tasks, positioned on the app-wide timeline (due
  /// dates + reminders), soonest first.
  List<TimelineEntry> get projectTimeline {
    final taskIds = _tasks.map((t) => t.id).toSet();
    return _timelineEngine
        .buildTimeline()
        .where((entry) => taskIds.contains(entry.sourceId))
        .toList();
  }

  Future<void> createTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? reminder,
    List<String> tags = const [],
    Recurrence? recurrence,
    List<String> labelIds = const [],
  }) async {
    final task = Task.create(
      title: title,
      projectId: projectId,
      description: description,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      tags: tags,
      recurrence: recurrence,
      labelIds: labelIds,
    );
    await _taskRepository.saveTaskRecord(task);
    await _syncReminder(task);
    _reload();
  }

  Future<void> updateTask(
    Task task, {
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? reminder,
    bool clearReminder = false,
    List<String>? tags,
    bool? isDone,
    Recurrence? recurrence,
    List<String>? labelIds,
    bool? isPinned,
  }) async {
    var updated = task.copyWith(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      tags: tags,
      isDone: isDone,
      recurrence: recurrence,
      labelIds: labelIds,
      isPinned: isPinned,
    );
    // copyWith's null-coalescing convention can't clear dueDate/reminder
    // (null there means "leave unchanged") — the dedicated methods can.
    if (clearDueDate) updated = updated.withoutDueDate();
    if (clearReminder) updated = updated.withoutReminder();
    await _taskRepository.saveTaskRecord(updated);
    await _syncReminder(updated);

    // Recurring Templates (Phase 12): completing a recurring task spawns
    // its next occurrence. Gated on the done-transition (not already
    // done) so re-saving an already-completed recurring task doesn't
    // spawn duplicates.
    if (isDone == true && !task.isDone) {
      final next = _recurringTaskService.nextOccurrence(updated);
      if (next != null) {
        await _taskRepository.saveTaskRecord(next);
        await _syncReminder(next);
      }
    }

    _reload();
  }

  /// Toggles [task]'s pinned state (Phase 12's Pinned Tasks).
  Future<void> togglePin(Task task) async {
    await _taskRepository.saveTaskRecord(task.copyWith(isPinned: !task.isPinned));
    _reload();
  }

  Future<void> deleteTask(Task task) async {
    await _reminderScheduler.cancelReminder(task.id);
    await _taskRepository.deleteTaskRecord(task.id);
    _reload();
  }

  /// Moves [task] to a different project (or removes it from any
  /// project if [newProjectId] is `null`).
  Future<void> moveTask(Task task, String? newProjectId) async {
    final moved = newProjectId == null
        ? task.unassignFromProject()
        : task.copyWith(projectId: newProjectId);
    await _taskRepository.saveTaskRecord(moved);
    _reload();
  }

  Future<void> archiveProject() async {
    if (_project == null) return;
    await _projectRepository.save(_project!.copyWith(isArchived: true));
    _reload();
  }

  Future<void> restoreProject() async {
    if (_project == null) return;
    await _projectRepository.save(_project!.copyWith(isArchived: false));
    _reload();
  }

  Future<void> updateProjectInfo(Project updated) async {
    await _projectRepository.save(updated);
    _reload();
  }

  /// Deletes the project itself. Its tasks are unassigned, not deleted
  /// — same data-preserving behavior as `ProjectsController.deleteProject`.
  Future<void> deleteProject() async {
    for (final task in _tasks) {
      await _reminderScheduler.cancelReminder(task.id);
      await _taskRepository.saveTaskRecord(task.unassignFromProject());
    }
    await _projectRepository.delete(projectId);
    _project = null;
    _tasks = [];
    notifyListeners();
  }

  Future<void> _syncReminder(Task task) async {
    if (task.reminder != null && !task.isDone) {
      await _reminderScheduler.scheduleReminder(
        id: task.id,
        title: task.title,
        body: task.description.isEmpty ? 'Task reminder' : task.description,
        scheduledTime: task.reminder!,
      );
    } else {
      await _reminderScheduler.cancelReminder(task.id);
    }
  }

  void _reload() {
    _project = _projectRepository.getById(projectId);
    _tasks = _taskRepository.getTaskRecordsByProject(projectId);
    notifyListeners();
  }
}
