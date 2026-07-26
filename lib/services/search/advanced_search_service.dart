import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/event_repository.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';

enum SearchResultType { task, project, event }

/// One unified search hit, wrapping whichever underlying model matched
/// so [AdvancedSearchScreen] can render (and navigate from) any type
/// through one list.
class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final Object entity;

  const SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.entity,
  });
}

/// Cross-entity search across Tasks/Projects/Events (Phase 12) — plain
/// substring matching on title/description/tags, no external index.
/// Reasonable for a single-user local app's data volumes; a proper
/// search index is a documented non-goal at this scale.
class AdvancedSearchService {
  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final EventRepository _eventRepository;

  AdvancedSearchService({
    TaskRepository? taskRepository,
    ProjectRepository? projectRepository,
    EventRepository? eventRepository,
  })  : _taskRepository = taskRepository ?? TaskRepository(),
        _projectRepository = projectRepository ?? ProjectRepository(),
        _eventRepository = eventRepository ?? EventRepository();

  List<SearchResult> search(
    String query, {
    TaskPriority? priority,
    DateTime? dueAfter,
    DateTime? dueBefore,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final results = <SearchResult>[];

    for (final task in _taskRepository.getAllTaskRecords()) {
      if (!_matchesText(normalized, [task.title, task.description, ...task.tags])) {
        continue;
      }
      if (priority != null && task.priority != priority) continue;
      if (dueAfter != null && (task.dueDate == null || task.dueDate!.isBefore(dueAfter))) {
        continue;
      }
      if (dueBefore != null && (task.dueDate == null || task.dueDate!.isAfter(dueBefore))) {
        continue;
      }
      results.add(SearchResult(
        type: SearchResultType.task,
        title: task.title,
        subtitle: task.description.isNotEmpty ? task.description : 'Task',
        entity: task,
      ));
    }

    for (final project in _projectRepository.getAll()) {
      if (!_matchesText(normalized, [project.title, project.description])) continue;
      results.add(SearchResult(
        type: SearchResultType.project,
        title: project.title,
        subtitle: project.description.isNotEmpty ? project.description : 'Project',
        entity: project,
      ));
    }

    for (final event in _eventRepository.getAll()) {
      if (!_matchesText(normalized, [event.title, event.description, event.platform])) {
        continue;
      }
      results.add(SearchResult(
        type: SearchResultType.event,
        title: event.title,
        subtitle: event.description.isNotEmpty ? event.description : 'Event',
        entity: event,
      ));
    }

    return results;
  }

  bool _matchesText(String normalizedQuery, List<String> fields) {
    return fields.any((field) => field.toLowerCase().contains(normalizedQuery));
  }
}
