import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/features/settings/screens/account_screen.dart';
import 'package:zentask/providers/auth_controller.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/app_theme.dart';

import '../../test_utils/fake_auth_service.dart';

void main() {
  late Directory tempDir;
  late FakeAuthService fakeAuth;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_account_screen_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.settingsBoxName);
    AuthController.resetInstanceForTesting();
    fakeAuth = FakeAuthService();
    AuthController.setInstanceForTesting(AuthController(authService: fakeAuth));
  });

  tearDown(() async {
    fakeAuth.dispose();
    AuthController.resetInstanceForTesting();
    await Hive.deleteBoxFromDisk(HiveService.settingsBoxName);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

  testWidgets('signed out: shows email/password fields and anonymous option',
      (tester) async {
    await tester.pumpWidget(wrap(const AccountScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue without an account'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('signing in anonymously shows the signed-in view', (tester) async {
    await tester.pumpWidget(wrap(const AccountScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();

    expect(find.text('Anonymous account'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('signing out returns to the signed-out view', (tester) async {
    await tester.pumpWidget(wrap(const AccountScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('a failed sign-in shows the error message', (tester) async {
    fakeAuth.failSignIn = true;
    await tester.pumpWidget(wrap(const AccountScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'a@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.textContaining('sign in failed'), findsOneWidget);
  });
}
