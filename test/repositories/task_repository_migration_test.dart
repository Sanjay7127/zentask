import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_hive_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('mybox_test');
    recordsBox = await Hive.openBox('task_records_test');
    settingsBox = await Hive.openBox('settings_test');
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  TaskRepository repo() => TaskRepository(
        box: legacyBox,
        recordsBox: recordsBox,
        settingsBox: settingsBox,
      );

  test('migrates legacy [title, isDone] pairs into rich Task records', () async {
    legacyBox.put('TODOLIST', [
      ['Buy milk', false],
      ['Submit assignment', true],
    ]);

    await repo().migrateLegacyTasksIfNeeded();

    final migrated = repo().getAllTaskRecords()
      ..sort((a, b) => a.order.compareTo(b.order));

    expect(migrated.length, 2);
    expect(migrated[0].title, 'Buy milk');
    expect(migrated[0].isDone, false);
    expect(migrated[0].status, TaskStatus.todo);
    expect(migrated[0].order, 0);
    expect(migrated[1].title, 'Submit assignment');
    expect(migrated[1].isDone, true);
    expect(migrated[1].status, TaskStatus.done);
    expect(migrated[1].order, 1);

    // The legacy box itself is untouched — no data loss, no rewrite.
    expect(legacyBox.get('TODOLIST'), [
      ['Buy milk', false],
      ['Submit assignment', true],
    ]);
  });

  test('is idempotent: running it twice does not duplicate records', () async {
    legacyBox.put('TODOLIST', [
      ['One task', false],
    ]);

    await repo().migrateLegacyTasksIfNeeded();
    await repo().migrateLegacyTasksIfNeeded();

    expect(repo().getAllTaskRecords().length, 1);
  });

  test('does nothing when there is no legacy data', () async {
    await repo().migrateLegacyTasksIfNeeded();
    expect(repo().getAllTaskRecords(), isEmpty);
  });

  test('the migration flag lives in settings, not in the records box',
      () async {
    legacyBox.put('TODOLIST', [
      ['A task', false],
    ]);

    await repo().migrateLegacyTasksIfNeeded();

    // getAllTaskRecords must only ever see actual Task maps — if the
    // flag leaked into the records box, this would throw while trying
    // to parse `true` as a Task map.
    expect(() => repo().getAllTaskRecords(), returnsNormally);
    expect(settingsBox.get('legacy_tasks_migrated'), true);
  });

  test('saveTaskRecord/deleteTaskRecord/getTaskRecordsByProject work',
      () async {
    final r = repo();
    final t1 = Task.create(title: 'In project', projectId: 'p1');
    final t2 = Task.create(title: 'No project');

    await r.saveTaskRecord(t1);
    await r.saveTaskRecord(t2);

    expect(r.getAllTaskRecords().length, 2);
    expect(r.getTaskRecordsByProject('p1').single.title, 'In project');

    await r.deleteTaskRecord(t1.id);
    expect(r.getAllTaskRecords().length, 1);
  });
}
