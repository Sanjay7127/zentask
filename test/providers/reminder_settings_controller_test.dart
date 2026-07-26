import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/providers/reminder_settings_controller.dart';

import '../test_utils/fake_reminder_scheduler.dart';

void main() {
  late Directory tempDir;
  late Box settingsBox;
  late FakeReminderScheduler scheduler;

  setUp(() async {
    tempDir =
        Directory.systemTemp.createTempSync('zentask_reminder_settings_test');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox('settings_test');
    scheduler = FakeReminderScheduler();
  });

  tearDown(() async {
    await settingsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ReminderSettingsController controller() => ReminderSettingsController(
        scheduler: scheduler,
        settingsBox: settingsBox,
      );

  test('defaults reminders to enabled when nothing is persisted yet', () {
    final c = controller();
    expect(c.remindersEnabled, true);
  });

  test('reads a previously persisted disabled preference', () async {
    await settingsBox.put('notifications_enabled', false);
    final c = controller();
    expect(c.remindersEnabled, false);
  });

  test('setRemindersEnabled(false) persists and cancels all reminders',
      () async {
    final c = controller();
    await c.setRemindersEnabled(false);

    expect(c.remindersEnabled, false);
    expect(settingsBox.get('notifications_enabled'), false);
    expect(scheduler.cancelled, contains('__all__'));
  });

  test('setRemindersEnabled(true) persists and re-initializes the scheduler',
      () async {
    await settingsBox.put('notifications_enabled', false);
    final c = controller();

    await c.setRemindersEnabled(true);

    expect(c.remindersEnabled, true);
    expect(settingsBox.get('notifications_enabled'), true);
  });

  test('permissionGranted reflects the scheduler status', () async {
    scheduler.notificationsEnabledResult = true;
    final c = controller();
    // Constructor kicks off an async permission check; give it a beat.
    await Future<void>.delayed(Duration.zero);
    expect(c.permissionGranted, true);
  });

  test('permissionGranted is null when the platform cannot report status',
      () async {
    scheduler.notificationsEnabledResult = null;
    final c = controller();
    await Future<void>.delayed(Duration.zero);
    expect(c.permissionGranted, isNull);
  });

  test('sendTestNotification schedules through the ReminderScheduler',
      () async {
    final c = controller();
    final when = DateTime.now().add(const Duration(minutes: 5));
    await c.sendTestNotification(when);

    expect(scheduler.scheduled, contains('test_notification'));
  });

  test('requestPermission re-checks status via the scheduler', () async {
    scheduler.notificationsEnabledResult = false;
    final c = controller();
    await Future<void>.delayed(Duration.zero);
    expect(c.permissionGranted, false);

    scheduler.notificationsEnabledResult = true;
    await c.requestPermission();
    expect(c.permissionGranted, true);
  });
}
