import 'package:zentask/models/event.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';

/// Pure camelCase-Dart-map <-> snake_case-SQL-row conversions for
/// [CloudSyncEngine], split into their own file (rather than staying
/// private methods on the engine) specifically so they're directly
/// testable without needing a Supabase client at all — the part of the
/// sync engine most worth covering with tests, since a wrong key name
/// here silently drops a field rather than throwing.
class EntityRowMappers {
  EntityRowMappers._();

  static Map<String, dynamic> projectToRow(Project p, String ownerId) => {
        'id': p.id,
        'owner_id': ownerId,
        'title': p.title,
        'description': p.description,
        'color_value': p.colorValue,
        'icon_key': p.iconKey,
        'category': p.category.name,
        'priority': p.priority.name,
        'is_archived': p.isArchived,
        'is_favorite': p.isFavorite,
        'linked_event_id': p.linkedEventId,
        'created_at': p.createdAt.toIso8601String(),
        'updated_at': p.updatedAt.toIso8601String(),
        'deleted_at': null,
      };

  static Map<String, dynamic> rowToProjectMap(Map<String, dynamic> row) => {
        'id': row['id'],
        'title': row['title'],
        'description': row['description'],
        'colorValue': row['color_value'],
        'iconKey': row['icon_key'],
        'category': row['category'],
        'priority': row['priority'],
        'isArchived': row['is_archived'],
        'isFavorite': row['is_favorite'],
        'linkedEventId': row['linked_event_id'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };

  static Map<String, dynamic> taskToRow(Task t, String ownerId) => {
        'id': t.id,
        'owner_id': ownerId,
        'project_id': t.projectId,
        'title': t.title,
        'description': t.description,
        'priority': t.priority.name,
        'due_date': t.dueDate?.toIso8601String(),
        'reminder': t.reminder?.toIso8601String(),
        'status': t.status.name,
        'tags': t.tags,
        'subtasks': t.subtasks.map((s) => s.toMap()).toList(),
        'recurrence': t.recurrence?.toMap(),
        'order': t.order,
        'created_at': t.createdAt?.toIso8601String(),
        'updated_at': (t.updatedAt ?? DateTime.now()).toIso8601String(),
        'deleted_at': null,
      };

  static Map<String, dynamic> rowToTaskMap(Map<String, dynamic> row) => {
        'id': row['id'],
        'projectId': row['project_id'],
        'title': row['title'],
        'description': row['description'],
        'priority': row['priority'],
        'dueDate': row['due_date'],
        'reminder': row['reminder'],
        'status': row['status'],
        'tags': row['tags'],
        'subtasks': row['subtasks'],
        'recurrence': row['recurrence'],
        'order': row['order'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };

  static Map<String, dynamic> eventToRow(Event e, String ownerId) => {
        'id': e.id,
        'owner_id': ownerId,
        'title': e.title,
        'platform': e.platform,
        'type': e.type.name,
        'start_date': e.startDate?.toIso8601String(),
        'end_date': e.endDate?.toIso8601String(),
        'registration_deadline': e.registrationDeadline?.toIso8601String(),
        'submission_deadline': e.submissionDeadline?.toIso8601String(),
        'event_url': e.eventUrl,
        'location': e.location,
        'description': e.description,
        'logo': e.logo,
        'color_value': e.colorValue,
        'bookmarked': e.bookmarked,
        'linked_project_id': e.linkedProjectId,
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.updatedAt.toIso8601String(),
        'deleted_at': null,
      };

  static Map<String, dynamic> rowToEventMap(Map<String, dynamic> row) => {
        'id': row['id'],
        'title': row['title'],
        'platform': row['platform'],
        'type': row['type'],
        'startDate': row['start_date'],
        'endDate': row['end_date'],
        'registrationDeadline': row['registration_deadline'],
        'submissionDeadline': row['submission_deadline'],
        'eventUrl': row['event_url'],
        'location': row['location'],
        'description': row['description'],
        'logo': row['logo'],
        'colorValue': row['color_value'],
        'bookmarked': row['bookmarked'],
        'linkedProjectId': row['linked_project_id'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };
}
