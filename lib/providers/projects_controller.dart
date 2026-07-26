import 'package:flutter/foundation.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';

/// Status groupings for the Projects screen's filter chips (Phase 9).
///
/// `completed`/`active` are computed from task completion, not a stored
/// flag — consistent with `Project` never persisting a completion
/// percentage (see the doc comment on `Project`). A project with zero
/// tasks reads as `active` (nothing to call "done" yet), not `completed`.
enum ProjectStatusFilter { all, active, completed, archived }

/// Sort options for the Projects screen (Phase 9).
enum ProjectSortOption { name, dueDate, progress, recentlyUpdated }

/// Business-logic layer for the Projects dashboard: owns the project
/// list and dashboard-level aggregates. Mirrors the existing
/// `TaskController` pattern (`ChangeNotifier` + repositories, no new
/// state-management dependency).
class ProjectsController extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;
  final AnalyticsEngine _analyticsEngine;

  List<Project> _projects = [];

  ProjectsController({
    ProjectRepository? projectRepository,
    TaskRepository? taskRepository,
    AnalyticsEngine? analyticsEngine,
  })  : _projectRepository = projectRepository ?? ProjectRepository(),
        _taskRepository = taskRepository ?? TaskRepository(),
        _analyticsEngine = analyticsEngine ?? AnalyticsEngine() {
    _projects = _projectRepository.getAll();
  }

  List<Project> get projects => List.unmodifiable(_projects);

  List<Project> get activeProjects =>
      _projects.where((p) => !p.isArchived).toList();

  List<Project> get archivedProjects =>
      _projects.where((p) => p.isArchived).toList();

  int get totalProjectCount => _projects.length;

  int get activeProjectCount => activeProjects.length;

  int get archivedProjectCount => archivedProjects.length;

  /// Non-archived projects whose tasks are all done (and have at least
  /// one task) — same "finished" definition as
  /// [ProjectStatusFilter.completed] below, exposed as a count for the
  /// Analytics dashboard (Phase 10).
  int get finishedProjectCount =>
      activeProjects.where(_isCompleted).length;

  /// Average completion rate across active (non-archived) projects.
  /// 0.0 if there are none — not an error, just nothing to average.
  double get averageActiveCompletion {
    final active = activeProjects;
    if (active.isEmpty) return 0.0;
    final sum = active.fold<double>(
      0.0,
      (acc, p) => acc + _analyticsEngine.projectCompletionRate(p.id),
    );
    return sum / active.length;
  }

  double completionRateFor(String projectId) =>
      _analyticsEngine.projectCompletionRate(projectId);

  int completedTaskCountFor(String projectId) => _taskRepository
      .getTaskRecordsByProject(projectId)
      .where((t) => t.isDone)
      .length;

  int totalTaskCountFor(String projectId) =>
      _taskRepository.getTaskRecordsByProject(projectId).length;

  /// The soonest not-yet-done task with a due date in this project, or
  /// `null` if none has one.
  Task? nextUpcomingTaskFor(String projectId) {
    final candidates = _taskRepository
        .getTaskRecordsByProject(projectId)
        .where((t) => !t.isDone && t.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Not-yet-done tasks (across every project) due within [withinDays]
  /// days from now, soonest first.
  List<Task> upcomingDeadlines({int withinDays = 7}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));
    final tasks = _taskRepository
        .getAllTaskRecords()
        .where((t) =>
            !t.isDone &&
            t.dueDate != null &&
            !t.dueDate!.isBefore(now) &&
            !t.dueDate!.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return tasks;
  }

  /// Projects to display on screen: filtered by [searchQuery] (title,
  /// case-insensitive) and [filter], then ordered by [sort]. Pure query
  /// logic over the already-loaded project list — no persistence, no
  /// side effects, safe to call from `build()`.
  List<Project> visibleProjects({
    String searchQuery = '',
    ProjectStatusFilter filter = ProjectStatusFilter.all,
    ProjectSortOption sort = ProjectSortOption.recentlyUpdated,
  }) {
    var result = List<Project>.from(_projects);

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result =
          result.where((p) => p.title.toLowerCase().contains(query)).toList();
    }

    result = result.where((p) => _matchesFilter(p, filter)).toList();

    switch (sort) {
      case ProjectSortOption.name:
        result.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case ProjectSortOption.dueDate:
        result.sort((a, b) {
          final aDate = nextUpcomingTaskFor(a.id)?.dueDate;
          final bDate = nextUpcomingTaskFor(b.id)?.dueDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        break;
      case ProjectSortOption.progress:
        result.sort((a, b) =>
            completionRateFor(b.id).compareTo(completionRateFor(a.id)));
        break;
      case ProjectSortOption.recentlyUpdated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    return result;
  }

  bool _matchesFilter(Project project, ProjectStatusFilter filter) {
    switch (filter) {
      case ProjectStatusFilter.all:
        return true;
      case ProjectStatusFilter.active:
        return !project.isArchived &&
            !_isCompleted(project);
      case ProjectStatusFilter.completed:
        return !project.isArchived && _isCompleted(project);
      case ProjectStatusFilter.archived:
        return project.isArchived;
    }
  }

  bool _isCompleted(Project project) =>
      totalTaskCountFor(project.id) > 0 &&
      completionRateFor(project.id) >= 1.0;

  Future<void> createProject({
    required String title,
    String description = '',
    int colorValue = 0xFF01D1AF,
    String iconKey = 'folder',
    ProjectCategory category = ProjectCategory.other,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final project = Project.create(
      title: title,
      description: description,
      colorValue: colorValue,
      iconKey: iconKey,
      category: category,
      priority: priority,
    );
    await _projectRepository.save(project);
    _reload();
  }

  Future<void> updateProject(Project updated) async {
    await _projectRepository.save(updated);
    _reload();
  }

  Future<void> archiveProject(String id) async {
    final project = _projectRepository.getById(id);
    if (project == null) return;
    await _projectRepository.save(project.copyWith(isArchived: true));
    _reload();
  }

  Future<void> restoreProject(String id) async {
    final project = _projectRepository.getById(id);
    if (project == null) return;
    await _projectRepository.save(project.copyWith(isArchived: false));
    _reload();
  }

  /// Deletes the project. Its tasks are unassigned (`projectId` cleared),
  /// not deleted — no task data is lost when a project goes away.
  Future<void> deleteProject(String id) async {
    final tasks = _taskRepository.getTaskRecordsByProject(id);
    for (final task in tasks) {
      await _taskRepository.saveTaskRecord(task.unassignFromProject());
    }
    await _projectRepository.delete(id);
    _reload();
  }

  void _reload() {
    _projects = _projectRepository.getAll();
    notifyListeners();
  }
}
