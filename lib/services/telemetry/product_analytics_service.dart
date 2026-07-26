import 'package:zentask/services/logging/app_logger.dart';

/// Abstraction over product-analytics event tracking (Phase 12) —
/// screen views, feature usage, that kind of thing. Deliberately a
/// distinct concept from `services/analytics/analytics_engine.dart`
/// (Phase 10's `AnalyticsEngine`), which computes *productivity*
/// statistics from the user's own tasks for their own dashboard; this
/// is about product telemetry sent to whoever operates the app.
abstract class ProductAnalyticsService {
  void logEvent(String name, {Map<String, Object?> properties = const {}});

  void setUserProperty(String name, Object? value);
}

/// Default [ProductAnalyticsService]: logs events locally via
/// [AppLogger] only, sends nothing anywhere. Like [LocalCrashReporter],
/// this is what every build uses until a real analytics backend has
/// credentials configured — no telemetry leaves the device today.
class LocalProductAnalyticsService implements ProductAnalyticsService {
  const LocalProductAnalyticsService();

  @override
  void logEvent(String name, {Map<String, Object?> properties = const {}}) {
    AppLogger.info('event: $name $properties', name: 'analytics');
  }

  @override
  void setUserProperty(String name, Object? value) {
    AppLogger.info('user property: $name=$value', name: 'analytics');
  }
}
