import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/core/root_shell.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_root_shell_test');
    Hive.init(tempDir.path);
    // Screens under RootShell use their controllers' default (no-arg)
    // constructors, which resolve through HiveService's box names — so
    // the test has to open boxes under those exact names, not
    // arbitrary ones, for the widget tree to build without a HiveError.
    await Hive.openBox(HiveService.tasksBoxName);
    await Hive.openBox(HiveService.taskRecordsBoxName);
    await Hive.openBox(HiveService.projectsBoxName);
    await Hive.openBox(HiveService.eventsBoxName);
    await Hive.openBox(HiveService.settingsBoxName);
    await Hive.openBox(HiveService.bookmarksBoxName);
    await Hive.openBox(HiveService.savedFiltersBoxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveService.tasksBoxName);
    await Hive.deleteBoxFromDisk(HiveService.taskRecordsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.projectsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.eventsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.settingsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.bookmarksBoxName);
    await Hive.deleteBoxFromDisk(HiveService.savedFiltersBoxName);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

  // The Settings screen is taller than the test binding's default
  // viewport now that it has an Appearance + About section — see the
  // comment on the equivalent helper in settings_screen_test.dart for
  // why this is needed (Flutter's sliver lists only mount elements near
  // the visible viewport).
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows all 5 destinations and starts on Tasks', (tester) async {
    await tester.pumpWidget(wrap(const RootShell()));
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Analytics'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Tasks tab (HomeScreen) is the initial tab — its app bar title.
    expect(find.text('\nZenTask'), findsOneWidget);
  });

  testWidgets('tapping Projects destination switches to the Projects tab',
      (tester) async {
    await tester.pumpWidget(wrap(const RootShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Projects'));
    await tester.pumpAndSettle();

    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('tapping Analytics destination shows the real Analytics screen',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const RootShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Analytics'));
    await tester.pumpAndSettle();

    expect(find.text('Total Tasks'), findsOneWidget);
    expect(find.text('Weekly Activity'), findsOneWidget);
  });

  testWidgets('tapping Calendar destination shows the real Calendar screen',
      (tester) async {
    await tester.pumpWidget(wrap(const RootShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
  });

  testWidgets('tapping Settings destination shows the real Settings screen',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const RootShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Reminder Settings'), findsOneWidget);
  });
}
