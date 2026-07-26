import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/services/reminders/local_notification_reminder_scheduler.dart';
import 'package:zentask/services/reminders/reminder_scheduler.dart';

/// Business logic for the Reminder Settings screen: the persisted
/// enable/disable toggle, permission status, and test-notification
/// flow, all routed through the existing [ReminderScheduler] interface
/// (Phase 6) — never `flutter_local_notifications` directly.
class ReminderSettingsController extends ChangeNotifier {
  final ReminderScheduler _scheduler;
  final Box _settingsBox;

  static const String _enabledKey = 'notifications_enabled';
  static const String _testNotificationId = 'test_notification';

  late bool _remindersEnabled;
  bool? _permissionGranted;

  ReminderSettingsController({
    ReminderScheduler? scheduler,
    Box? settingsBox,
  })  : _scheduler = scheduler ?? LocalNotificationReminderScheduler(),
        _settingsBox = settingsBox ?? HiveService.settingsBox {
    _remindersEnabled =
        _settingsBox.get(_enabledKey, defaultValue: true) as bool;
    _refreshPermissionStatus();
  }

  bool get remindersEnabled => _remindersEnabled;

  /// `true`/`false` once known; `null` while unchecked or on a platform
  /// that can't report a status (e.g. web).
  bool? get permissionGranted => _permissionGranted;

  Future<void> setRemindersEnabled(bool value) async {
    _remindersEnabled = value;
    await _settingsBox.put(_enabledKey, value);
    if (value) {
      await _scheduler.initialize();
      await _refreshPermissionStatus();
    } else {
      await _scheduler.cancelAll();
    }
    notifyListeners();
  }

  Future<void> requestPermission() async {
    await _scheduler.initialize();
    await _refreshPermissionStatus();
  }

  Future<void> sendTestNotification(DateTime scheduledTime) async {
    await _scheduler.scheduleReminder(
      id: _testNotificationId,
      title: 'ZenTask test reminder',
      body: 'If you can see this, notifications are working.',
      scheduledTime: scheduledTime,
    );
  }

  Future<void> _refreshPermissionStatus() async {
    _permissionGranted = await _scheduler.areNotificationsEnabled();
    notifyListeners();
  }
}
