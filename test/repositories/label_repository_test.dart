import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/label.dart';
import 'package:zentask/repositories/label_repository.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late LabelRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_label_repo_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('labels_test');
    repository = LabelRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('getAll is empty with no labels saved', () {
    expect(repository.getAll(), isEmpty);
  });

  test('save then getAll/getById round-trips a label', () async {
    final label = Label.create(name: 'Urgent', colorValue: 0xFFFF0000);
    await repository.save(label);

    expect(repository.getAll().single.name, 'Urgent');
    expect(repository.getById(label.id)?.colorValue, 0xFFFF0000);
  });

  test('save with the same id overwrites (used by rename/recolor)', () async {
    final label = Label.create(name: 'Work');
    await repository.save(label);

    await repository.save(label.copyWith(name: 'Personal'));

    expect(repository.getAll(), hasLength(1));
    expect(repository.getById(label.id)?.name, 'Personal');
  });

  test('delete removes the label', () async {
    final label = Label.create(name: 'Temp');
    await repository.save(label);

    await repository.delete(label.id);

    expect(repository.getById(label.id), isNull);
  });
}
