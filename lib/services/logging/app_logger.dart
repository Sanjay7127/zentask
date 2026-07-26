import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// App-wide structured logging (Phase 12), replacing scattered
/// `debugPrint`/`print` calls with one place that knows how to route a
/// message: `dart:developer`'s `log` (visible in DevTools/IDE consoles,
/// and — unlike `print` — never truncated for long messages) in debug
/// builds, and nothing in release builds beyond what [CrashReporter]
/// separately captures for errors.
///
/// Deliberately a static-method utility, not an instantiated
/// service — logging has no state or configuration to inject, so a
/// singleton/DI wrapper here would just be ceremony.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String name = 'zentask'}) =>
      _log(LogLevel.debug, message, name: name);

  static void info(String message, {String name = 'zentask'}) =>
      _log(LogLevel.info, message, name: name);

  static void warning(String message, {String name = 'zentask'}) =>
      _log(LogLevel.warning, message, name: name);

  static void error(
    String message, {
    String name = 'zentask',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, name: name, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    developer.log(
      message,
      name: name,
      level: _severityFor(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Roughly matches `dart:developer`'s own severity scale (`Level` from
  /// `package:logging`, which `log`'s `level` parameter mirrors) so
  /// filtering by severity in DevTools works as expected.
  static int _severityFor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
