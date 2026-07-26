import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/services/telemetry/product_analytics_service.dart';

void main() {
  const analytics = LocalProductAnalyticsService();

  test('logEvent does not throw with no properties', () {
    expect(() => analytics.logEvent('app_opened'), returnsNormally);
  });

  test('logEvent does not throw with properties', () {
    expect(
      () => analytics.logEvent('task_completed', properties: {'priority': 'high'}),
      returnsNormally,
    );
  });

  test('setUserProperty does not throw', () {
    expect(() => analytics.setUserProperty('theme', 'dark'), returnsNormally);
  });
}
