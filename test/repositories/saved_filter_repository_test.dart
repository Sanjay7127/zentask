import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/saved_filter.dart';
import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/repositories/saved_filter_repository.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late SavedFilterRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_saved_filter_repo_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('saved_filters_test');
    repository = SavedFilterRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('getAll is empty with no filters saved', () {
    expect(repository.getAll(), isEmpty);
  });

  test('save then getAll round-trips a filter', () async {
    final filter = SavedFilter.create(
      name: 'Overdue active',
      searchQuery: 'urgent',
      filter: ProjectStatusFilter.active,
      sort: ProjectSortOption.dueDate,
    );
    await repository.save(filter);

    final saved = repository.getAll().single;
    expect(saved.name, 'Overdue active');
    expect(saved.searchQuery, 'urgent');
    expect(saved.filter, ProjectStatusFilter.active);
    expect(saved.sort, ProjectSortOption.dueDate);
  });

  test('getAll returns filters ordered by createdAt ascending', () async {
    final older = SavedFilter(
      id: 'a',
      name: 'Older',
      searchQuery: '',
      filter: ProjectStatusFilter.all,
      sort: ProjectSortOption.name,
      createdAt: DateTime(2026, 1, 1),
    );
    final newer = SavedFilter(
      id: 'b',
      name: 'Newer',
      searchQuery: '',
      filter: ProjectStatusFilter.all,
      sort: ProjectSortOption.name,
      createdAt: DateTime(2026, 2, 1),
    );
    await repository.save(newer);
    await repository.save(older);

    expect(repository.getAll().map((f) => f.name), ['Older', 'Newer']);
  });

  test('delete removes the filter', () async {
    final filter = SavedFilter.create(
      name: 'Temp',
      searchQuery: '',
      filter: ProjectStatusFilter.archived,
      sort: ProjectSortOption.progress,
    );
    await repository.save(filter);

    await repository.delete(filter.id);

    expect(repository.getAll(), isEmpty);
  });
}
