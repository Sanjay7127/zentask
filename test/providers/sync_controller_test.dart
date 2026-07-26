import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/providers/sync_controller.dart';
import 'package:zentask/services/cloud/sync_service.dart';

import '../test_utils/fake_sync_service.dart';

void main() {
  late FakeSyncService fakeSync;
  late SyncController controller;

  setUp(() {
    fakeSync = FakeSyncService();
    controller = SyncController(syncService: fakeSync);
  });

  test('reflects the underlying service\'s initial status', () {
    expect(controller.status, SyncStatus.idle);
  });

  test('syncNow delegates to the service and updates status', () async {
    await controller.syncNow();

    expect(fakeSync.syncCallCount, 1);
    expect(controller.status, SyncStatus.idle);
  });

  test('a failed sync surfaces lastError and an error status', () async {
    fakeSync.failNextSync = true;

    await controller.syncNow();

    expect(controller.status, SyncStatus.error);
    expect(controller.lastError, isNotNull);
  });

  test('startRealtime/stopRealtime delegate to the service', () {
    controller.startRealtime();
    expect(fakeSync.realtimeStarted, true);

    controller.stopRealtime();
    expect(fakeSync.realtimeStarted, false);
  });

  test('notifies listeners when the status stream emits', () async {
    var notifyCount = 0;
    controller.addListener(() => notifyCount++);

    await controller.syncNow();

    expect(notifyCount, greaterThan(0));
  });
}
