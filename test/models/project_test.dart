import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';

void main() {
  test('Project.create generates id and timestamps', () {
    final project = Project.create(title: 'ZenTask Hackathon');
    expect(project.id, isNotEmpty);
    expect(project.title, 'ZenTask Hackathon');
    expect(project.category, ProjectCategory.other);
    expect(project.priority, TaskPriority.medium);
    expect(project.isArchived, false);
    expect(project.isFavorite, false);
  });

  test('toMap/fromMap round-trips every field, including priority (Phase 7)',
      () {
    final original = Project.create(
      title: 'Devpost Submission',
      description: 'Build the demo',
      colorValue: 0xFF224466,
      iconKey: 'code',
      category: ProjectCategory.hackathon,
      priority: TaskPriority.urgent,
      linkedEventId: 'event-1',
    ).copyWith(isFavorite: true);

    final restored = Project.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.title, 'Devpost Submission');
    expect(restored.description, 'Build the demo');
    expect(restored.colorValue, 0xFF224466);
    expect(restored.iconKey, 'code');
    expect(restored.category, ProjectCategory.hackathon);
    expect(restored.priority, TaskPriority.urgent);
    expect(restored.linkedEventId, 'event-1');
    expect(restored.isFavorite, true);
    expect(restored.isArchived, false);
  });

  test('fromMap defaults priority to medium when absent (pre-Phase-7 data)',
      () {
    final legacyShapeMap = {
      'id': 'p1',
      'title': 'Old project',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    };
    final restored = Project.fromMap(legacyShapeMap);
    expect(restored.priority, TaskPriority.medium);
  });

  test('copyWith(priority:) updates only the priority', () {
    final project = Project.create(title: 'P');
    final updated = project.copyWith(priority: TaskPriority.high);
    expect(updated.priority, TaskPriority.high);
    expect(updated.title, 'P');
  });

  test('copyWith(isArchived:) toggles archive state', () {
    final project = Project.create(title: 'Old project');
    final archived = project.copyWith(isArchived: true);
    expect(archived.isArchived, true);
    expect(archived.id, project.id);
  });
}
