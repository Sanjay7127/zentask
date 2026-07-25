import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:zentask/services/reminders/reminder_scheduler.dart';

/// [ReminderScheduler] backed by `flutter_local_notifications`.
///
/// **Not build-verified in this environment** — this sandbox has no
/// Android SDK and an incomplete Xcode install, so `flutter build apk` /
/// `flutter build ios` / `flutter build macos` could not be run here.
/// The Dart-level API calls below were checked against the exact
/// resolved package version (18.0.1) by reading its source in
/// `.pub-cache`, and `flutter analyze` passes, but the native platform
/// wiring (manifest permissions, AppDelegate changes) has not been
/// exercised on a real build. Verify with a real build before relying
/// on this in production.
///
/// Uses **inexact** scheduling (`AndroidScheduleMode.inexactAllowWhileIdle`)
/// deliberately: exact alarms need the `SCHEDULE_EXACT_ALARM`/
/// `USE_EXACT_ALARM` permission, which needs user-facing context to
/// request sensibly (why does this app need exact alarms?) — that
/// context doesn't exist until there's a real reminder-setting UI.
/// Reminders may fire a few minutes late as a result; revisit once that
/// UI exists.
class LocalNotificationReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'zentask_reminders';
  static const String _channelName = 'Task Reminders';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Falls back to UTC (the `timezone` package's own default) if the
      // platform can't report its timezone. Reminders would then be
      // interpreted as UTC — noted as a known limitation, not silently
      // hidden.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  @override
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders for your ZenTask tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _notificationIdFor(id),
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancelReminder(String id) async {
    await _plugin.cancel(_notificationIdFor(id));
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// `flutter_local_notifications` needs an `int` id; our task ids are
  /// strings, so this derives one via `hashCode`. Collisions are
  /// possible in theory (two ids hashing to the same int) but
  /// astronomically unlikely for a single-user local app — documented
  /// here rather than solved with a dependency-heavy id-mapping scheme.
  int _notificationIdFor(String id) => id.hashCode;
}
