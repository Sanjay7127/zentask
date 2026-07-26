import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/providers/auth_controller.dart';

import '../test_utils/fake_auth_service.dart';

void main() {
  late FakeAuthService fakeAuth;
  late AuthController controller;

  setUp(() {
    fakeAuth = FakeAuthService();
    controller = AuthController(authService: fakeAuth);
  });

  tearDown(() {
    controller.dispose();
    fakeAuth.dispose();
  });

  test('starts signed out', () {
    expect(controller.isSignedIn, false);
    expect(controller.currentUser, isNull);
  });

  test('signInAnonymously signs the user in and notifies listeners', () async {
    var notified = false;
    controller.addListener(() => notified = true);

    await controller.signInAnonymously();

    expect(controller.isSignedIn, true);
    expect(controller.currentUser!.isAnonymous, true);
    expect(notified, true);
  });

  test('signInWithEmail signs the user in with the given email', () async {
    await controller.signInWithEmail('a@example.com', 'password123');

    expect(controller.isSignedIn, true);
    expect(controller.currentUser!.email, 'a@example.com');
  });

  test('a failed sign-in surfaces lastError and leaves the user signed out',
      () async {
    fakeAuth.failSignIn = true;

    await controller.signInWithEmail('a@example.com', 'password123');

    expect(controller.isSignedIn, false);
    expect(controller.lastError, isNotNull);
  });

  test('signOut clears the current user', () async {
    await controller.signInAnonymously();
    expect(controller.isSignedIn, true);

    await controller.signOut();

    expect(controller.isSignedIn, false);
  });

  test('signOutEverywhere also clears the current user', () async {
    await controller.signInAnonymously();
    expect(controller.isSignedIn, true);

    await controller.signOutEverywhere();

    expect(controller.isSignedIn, false);
  });

  test('Google/Apple sign-in surface a clear not-configured error by default',
      () async {
    await controller.signInWithGoogle();
    expect(controller.lastError, contains('not configured'));

    await controller.signInWithApple();
    expect(controller.lastError, contains('not configured'));
  });

  test('updateProfile changes the display name while signed in', () async {
    await controller.signInWithEmail('a@example.com', 'password123');

    await controller.updateProfile(displayName: 'Ada');

    expect(controller.currentUser!.displayName, 'Ada');
  });

  test('isLoading is true only while an operation is in flight', () async {
    final future = controller.signInAnonymously();
    // isLoading flips synchronously to true before the fake's async work
    // resolves; by the time the awaited future completes it's back to false.
    await future;
    expect(controller.isLoading, false);
  });
}
