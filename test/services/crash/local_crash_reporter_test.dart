import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/services/crash/crash_reporter.dart';

void main() {
  const reporter = LocalCrashReporter();

  test('recordError completes without throwing for a fatal error', () async {
    await expectLater(
      reporter.recordError(Exception('boom'), StackTrace.current, fatal: true),
      completes,
    );
  });

  test('recordError completes without throwing for a non-fatal error', () async {
    await expectLater(
      reporter.recordError(Exception('minor'), StackTrace.current),
      completes,
    );
  });

  test('addBreadcrumb does not throw', () {
    expect(() => reporter.addBreadcrumb('user tapped Export JSON'), returnsNormally);
  });
}
