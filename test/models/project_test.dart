import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/project.dart';

void main() {
  test('Project.create generates id and timestamps', () {
    final project = Project.create(title: 'ZenTask Hackathon');
    expect(project.id, isNotEmpty);
    expect(project.title, 'ZenTask Hackathon');
    expect(project.category, ProjectCategory.other);
    expect(project.isArchived, false);
    expect(project.isFavorite, false);
  });

  test('toMap/fromMap round-trips every field', () {
    final original = Project.create(
      title: 'Devpost Submission',
      description: 'Build the demo',
      colorValue: 0xFF224466,
      iconKey: 'code',
      category: ProjectCategory.hackathon,
      linkedEventId: 'event-1',
    ).copyWith(isFavorite: true);

    final restored = Project.fromMap(original.toMap());

    expect(restored.id, original.id);
    expect(restored.title, 'Devpost Submission');
    expect(restored.description, 'Build the demo');
    expect(restored.colorValue, 0xFF224466);
    expect(restored.iconKey, 'code');
    expect(restored.category, ProjectCategory.hackathon);
    expect(restored.linkedEventId, 'event-1');
    expect(restored.isFavorite, true);
    expect(restored.isArchived, false);
  });

  test('copyWith(isArchived:) toggles archive state', () {
    final project = Project.create(title: 'Old project');
    final archived = project.copyWith(isArchived: true);
    expect(archived.isArchived, true);
    expect(archived.id, project.id);
  });
}
