import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/event.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/cloud/entity_row_mappers.dart';

void main() {
  group('Project row mapping', () {
    test('round-trips through toRow/rowToMap without losing fields', () {
      final project = Project.create(
        title: 'Launch',
        description: 'Ship it',
        colorValue: 0xFF123456,
        iconKey: 'rocket',
        category: ProjectCategory.work,
        priority: TaskPriority.high,
      ).copyWith(isArchived: true, isFavorite: true);

      final row = EntityRowMappers.projectToRow(project, 'owner-1');
      expect(row['owner_id'], 'owner-1');
      expect(row['color_value'], 0xFF123456);
      expect(row['icon_key'], 'rocket');
      expect(row['is_archived'], true);
      expect(row['is_favorite'], true);

      final roundTripped = Project.fromMap(EntityRowMappers.rowToProjectMap(row));
      expect(roundTripped.id, project.id);
      expect(roundTripped.title, project.title);
      expect(roundTripped.colorValue, project.colorValue);
      expect(roundTripped.iconKey, project.iconKey);
      expect(roundTripped.category, project.category);
      expect(roundTripped.priority, project.priority);
      expect(roundTripped.isArchived, true);
      expect(roundTripped.isFavorite, true);
    });
  });

  group('Task row mapping', () {
    test('round-trips through toRow/rowToMap, including nested subtasks', () {
      final task = Task.create(
        title: 'Write report',
        projectId: 'proj-1',
        priority: TaskPriority.urgent,
        dueDate: DateTime(2026, 5, 1),
        subtasks: const [Subtask(id: 's1', title: 'Draft', completed: true)],
        tags: const ['work', 'urgent'],
      );

      final row = EntityRowMappers.taskToRow(task, 'owner-1');
      expect(row['owner_id'], 'owner-1');
      expect(row['project_id'], 'proj-1');
      expect(row['due_date'], DateTime(2026, 5, 1).toIso8601String());
      expect(row['tags'], ['work', 'urgent']);

      final roundTripped = Task.fromMap(EntityRowMappers.rowToTaskMap(row));
      expect(roundTripped.id, task.id);
      expect(roundTripped.title, task.title);
      expect(roundTripped.projectId, 'proj-1');
      expect(roundTripped.dueDate, DateTime(2026, 5, 1));
      expect(roundTripped.subtasks, hasLength(1));
      expect(roundTripped.subtasks.first.title, 'Draft');
      expect(roundTripped.subtasks.first.completed, true);
      expect(roundTripped.tags, ['work', 'urgent']);
    });
  });

  group('Event row mapping', () {
    test('round-trips through toRow/rowToMap', () {
      final event = Event.create(
        title: 'Hack Week',
        type: EventType.hackathon,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 3),
        colorValue: 0xFF00FF00,
      );

      final row = EntityRowMappers.eventToRow(event, 'owner-1');
      expect(row['owner_id'], 'owner-1');
      expect(row['type'], 'hackathon');
      expect(row['start_date'], DateTime(2026, 6, 1).toIso8601String());

      final roundTripped = Event.fromMap(EntityRowMappers.rowToEventMap(row));
      expect(roundTripped.id, event.id);
      expect(roundTripped.title, event.title);
      expect(roundTripped.type, EventType.hackathon);
      expect(roundTripped.startDate, DateTime(2026, 6, 1));
      expect(roundTripped.endDate, DateTime(2026, 6, 3));
      expect(roundTripped.colorValue, 0xFF00FF00);
    });
  });
}
