import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/services/calendar_sync/unavailable_calendar_sync_service.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';

void main() {
  test('isAvailable is false and displayName is preserved', () {
    const service = UnavailableCalendarSyncService('Google Calendar');
    expect(service.isAvailable, false);
    expect(service.displayName, 'Google Calendar');
  });

  test('exportAll and importFrom throw a clear not-configured message', () {
    const service = UnavailableCalendarSyncService('Apple Calendar');

    expect(() => service.exportAll(), throwsA(isA<CloudUnavailableException>()));
    expect(() => service.importFrom('data'), throwsA(isA<CloudUnavailableException>()));
  });
}
