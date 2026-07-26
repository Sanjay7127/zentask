import 'package:zentask/services/logging/app_logger.dart';

/// Abstraction over uncaught-error reporting (Phase 12). Mirrors the
/// interface-plus-swappable-implementation shape used for cloud sync
/// and auth elsewhere in the app: [main] wires [FlutterError.onError]
/// and `PlatformDispatcher.instance.onError` to whichever
/// implementation is configured, so swapping in a real crash-reporting
/// backend later (Sentry, Firebase Crashlytics, ...) never touches the
/// error-hook wiring itself, only which implementation is passed in.
abstract class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  });

  /// Attaches a note to whatever error is reported next — e.g. "user
  /// tapped Export JSON" — for backends that support breadcrumbs.
  void addBreadcrumb(String message);
}

/// Default [CrashReporter]: logs locally via [AppLogger] only, sends
/// nothing anywhere. No crash-reporting backend has credentials
/// configured in this app yet (see `CloudConfig`), so this is what
/// every build uses today — a real backend is a documented future
/// step, not a missing feature users can hit.
class LocalCrashReporter implements CrashReporter {
  const LocalCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    AppLogger.error(
      fatal ? 'Fatal error' : 'Error',
      name: 'crash_reporter',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void addBreadcrumb(String message) => AppLogger.debug(message, name: 'crash_reporter');
}
