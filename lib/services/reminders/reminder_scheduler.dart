/// Abstract contract for scheduling and cancelling task reminders.
///
/// Kept separate from any specific notification package so the rest of
/// the app depends on this interface, not on `flutter_local_notifications`
/// directly — swapping the underlying mechanism later only touches the
/// implementation, not any call site.
abstract class ReminderScheduler {
  /// Prepares the scheduler for use (requests OS permissions, etc.).
  /// Safe to call more than once.
  Future<void> initialize();

  /// Schedules a one-time reminder at [scheduledTime]. If a reminder
  /// with the same [id] already exists, it is replaced.
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  });

  Future<void> cancelReminder(String id);

  Future<void> cancelAll();
}
