import 'package:zentask/services/reminders/reminder_scheduler.dart';

/// Records calls instead of touching any real notification plugin —
/// `LocalNotificationReminderScheduler` talks to platform channels that
/// don't exist in a plain `flutter test` run. Shared across test files
/// that need a `ReminderScheduler` double (avoids duplicating this
/// class per file).
class FakeReminderScheduler implements ReminderScheduler {
  final List<String> scheduled = [];
  final List<String> cancelled = [];
  bool? notificationsEnabledResult = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    scheduled.add(id);
  }

  @override
  Future<void> cancelReminder(String id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelled.add('__all__');
  }

  @override
  Future<bool?> areNotificationsEnabled() async => notificationsEnabledResult;
}
