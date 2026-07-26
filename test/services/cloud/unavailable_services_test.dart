import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';
import 'package:zentask/services/cloud/sync_service.dart';
import 'package:zentask/services/cloud/unavailable_auth_service.dart';
import 'package:zentask/services/cloud/unavailable_sync_service.dart';

void main() {
  group('UnavailableAuthService', () {
    const service = UnavailableAuthService();

    test('currentUser is always null', () {
      expect(service.currentUser, isNull);
    });

    test('every sign-in method throws CloudUnavailableException', () async {
      // Each method's body is `=> throw ...` — not marked `async` — so
      // it throws synchronously when called rather than returning a
      // rejected Future. Wrapping the call in a closure (rather than
      // invoking it directly as expectLater's argument) lets `throwsA`
      // catch either a synchronous throw or an async rejection.
      expect(() => service.signInWithEmail(email: 'a@b.com', password: 'x'),
          throwsA(isA<CloudUnavailableException>()));
      expect(() => service.signUpWithEmail(email: 'a@b.com', password: 'x'),
          throwsA(isA<CloudUnavailableException>()));
      expect(() => service.signInAnonymously(),
          throwsA(isA<CloudUnavailableException>()));
      expect(() => service.signInWithGoogle(),
          throwsA(isA<CloudUnavailableException>()));
      expect(() => service.signInWithApple(),
          throwsA(isA<CloudUnavailableException>()));
    });

    test('signOut is a harmless no-op', () async {
      await service.signOut();
    });
  });

  group('UnavailableSyncService', () {
    const service = UnavailableSyncService();

    test('reports SyncStatus.unavailable', () {
      expect(service.currentStatus, SyncStatus.unavailable);
    });

    test('syncNow is a harmless no-op', () async {
      await service.syncNow();
    });
  });
}
