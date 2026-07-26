import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/features/settings/screens/reminder_settings_screen.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  late Directory tempDir;
  const channel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() async {
    tempDir =
        Directory.systemTemp.createTempSync('zentask_reminder_screen_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.settingsBoxName);

    // ReminderSettingsScreen builds its own controller with the real
    // LocalNotificationReminderScheduler (same pattern every other
    // screen in this app follows — no test-only injection points on
    // screens). Mocking the plugin's platform channel here is the
    // standard, idiomatic way to test code that calls a plugin, without
    // compromising the screen's constructor for testability.
    //
    // Mocking the channel alone isn't enough: outside a real app,
    // nothing ever calls the plugin's native-side registration, so
    // `FlutterLocalNotificationsPlatform.instance` (which
    // `resolvePlatformSpecificImplementation` reads) is never set and
    // throws a LateInitializationError. Registering the Android
    // implementation here stands in for that — it's still a
    // MethodChannel-based implementation, so it talks to the same mock
    // handler below.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
        case 'requestNotificationsPermission':
        case 'areNotificationsEnabled':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await Hive.deleteBoxFromDisk(HiveService.settingsBoxName);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: child);

  testWidgets('shows the reminders toggle and test-notification controls',
      (tester) async {
    await tester.pumpWidget(wrap(const ReminderSettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Enable Reminders'), findsOneWidget);
    expect(find.text('Send Test Notification'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('toggling reminders off persists the preference', (tester) async {
    await tester.pumpWidget(wrap(const ReminderSettingsScreen()));
    await tester.pumpAndSettle();

    final switchTile =
        tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(switchTile.value, true);

    // setRemindersEnabled(false) awaits the real scheduler's cancelAll()
    // (real platform-channel I/O) before calling notifyListeners(), so
    // this needs the same runAsync + delay escape as the other real
    // async interactions in this file.
    await tester.runAsync(() async {
      await tester.tap(find.byType(SwitchListTile));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final updatedSwitchTile =
        tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(updatedSwitchTile.value, false);
    expect(
      Hive.box(HiveService.settingsBoxName).get('notifications_enabled'),
      false,
    );
  });

  testWidgets('sending a test notification shows a confirmation snackbar',
      (tester) async {
    await tester.pumpWidget(wrap(const ReminderSettingsScreen()));
    await tester.pumpAndSettle();

    // _sendTestNotification awaits the real LocalNotificationReminderScheduler,
    // which performs real platform-channel calls (plugin initialize,
    // zonedSchedule) — real async work that never resolves inside a
    // testWidgets callback's FakeAsync zone unless escaped via runAsync,
    // and tester.tap() doesn't wait for onTap's own async continuation
    // either, so give it a moment on the real event loop before
    // returning to the fake-async zone for pumpAndSettle (see
    // projects_dashboard_screen_test.dart for the full explanation).
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Send Test Notification'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Test reminder scheduled for'), findsOneWidget);
  });
}
