import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/services/cloud/sync_metadata_store.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late SyncMetadataStore store;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_sync_meta_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('sync_meta_test');
    store = SyncMetadataStore(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('lastPushedAt/lastPulledAt are null before anything is recorded', () {
    expect(store.lastPushedAt('project'), isNull);
    expect(store.lastPulledAt('project'), isNull);
  });

  test('setLastPushedAt/setLastPulledAt persist and round-trip', () async {
    final time = DateTime(2026, 3, 1, 12, 30);
    await store.setLastPushedAt('project', time);
    await store.setLastPulledAt('task', time);

    expect(store.lastPushedAt('project'), time);
    expect(store.lastPulledAt('task'), time);
    expect(store.lastPushedAt('task'), isNull); // different entity type
  });

  test('knownIds defaults to empty and round-trips after being set', () async {
    expect(store.knownIds('project'), isEmpty);

    await store.setKnownIds('project', {'a', 'b', 'c'});
    expect(store.knownIds('project'), {'a', 'b', 'c'});
  });

  test('inferring deletions: knownIds minus current ids gives the deleted set',
      () async {
    await store.setKnownIds('project', {'a', 'b', 'c'});
    final current = {'a', 'c'}; // 'b' was deleted locally
    final deleted = store.knownIds('project').difference(current);
    expect(deleted, {'b'});
  });
}
