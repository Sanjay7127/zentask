import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/features/settings/screens/settings_screen.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/providers/app_settings_controller.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/accent_color.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_settings_screen_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.tasksBoxName);
    await Hive.openBox(HiveService.taskRecordsBoxName);
    await Hive.openBox(HiveService.projectsBoxName);
    await Hive.openBox(HiveService.eventsBoxName);
    await Hive.openBox(HiveService.settingsBoxName);
    await Hive.openBox(HiveService.bookmarksBoxName);
    // AppSettingsController.instance is a lazily-created singleton shared
    // by every screen that reads it — each test opens its own fresh Hive
    // box, so the singleton must be discarded too, or a later test would
    // still hold a reference to an earlier test's already-deleted box.
    AppSettingsController.resetInstanceForTesting();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveService.tasksBoxName);
    await Hive.deleteBoxFromDisk(HiveService.taskRecordsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.projectsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.eventsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.settingsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.bookmarksBoxName);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: child);

  // The Settings screen (Appearance + Data + Notifications + About) is
  // taller than the test binding's default ~600-logical-pixel viewport.
  // Flutter's sliver-based ListView only mounts elements near the
  // visible viewport — content further down genuinely isn't in the
  // Element tree until scrolled into view, so `find.text()` on a
  // section near the bottom (Notifications, About) would find nothing
  // without this. Widening the virtual viewport is simpler and more
  // robust here than scrolling before every assertion.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows Appearance, Data, Notifications, and About sections',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Copy JSON'), findsOneWidget);
    expect(find.text('Import JSON'), findsOneWidget);
    expect(find.text('Paste JSON'), findsOneWidget);
    expect(find.text('Reminder Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Accent color'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Licenses'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Report Issue'), findsOneWidget);
    expect(find.text('Account & Cloud Sync'), findsOneWidget);
    expect(find.text('Export Calendar (.ics)'), findsOneWidget);
    expect(find.text('Import Calendar (.ics)'), findsOneWidget);
  });

  testWidgets('Export JSON shows a dialog containing the exported data',
      (tester) async {
    useTallViewport(tester);
    await tester.runAsync(() =>
        ProjectRepository().save(Project.create(title: 'Exported project')));

    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export JSON'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Exported project'), findsOneWidget);
    expect(find.widgetWithText(AlertDialog, 'Export JSON'), findsOneWidget);
  });

  testWidgets('Import JSON dialog accepts pasted text and imports it',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import JSON'));
    await tester.pumpAndSettle();

    const payload =
        '{"version":1,"projects":[],"tasks":[],"events":[]}';
    await tester.enterText(find.byType(TextField), payload);

    // The internal service call performs real Hive writes, which don't
    // resolve on the fake clock pumpAndSettle() drives — wrap the tap in
    // runAsync, plus a short real delay so onTap's own async
    // continuation (which tap() doesn't wait for) gets a chance to run
    // on the real event loop runAsync activates before control returns
    // to the fake-async zone (see projects_dashboard_screen_test.dart
    // for the full explanation of this pattern).
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Import complete'), findsOneWidget);
  });

  testWidgets('Import JSON shows an error for malformed input', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import JSON'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'not valid json at all');

    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Import failed'), findsOneWidget);
  });

  testWidgets('Paste JSON reports an empty clipboard gracefully',
      (tester) async {
    useTallViewport(tester);
    // The test environment's clipboard has some ambient default value
    // unless explicitly set — pin it to empty so this test is
    // deterministic rather than relying on that default.
    await tester.runAsync(
        () => Clipboard.setData(const ClipboardData(text: '')));

    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Paste JSON'));
      // tester.tap() only dispatches the pointer event and returns —
      // it doesn't wait for onTap's own async continuation (the
      // Clipboard.getData platform-channel round-trip) to finish. That
      // continuation keeps running on the real event loop that
      // runAsync activates, so give it a moment here before returning
      // to the fake-async zone for pumpAndSettle.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Clipboard is empty'), findsOneWidget);
  });

  testWidgets('switching theme mode persists and updates the segmented button',
      (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // AppSettingsController.setThemeMode awaits a real Hive write, which
    // never resolves inside a testWidgets callback's FakeAsync zone
    // unless escaped via runAsync — and tester.tap() doesn't wait for
    // onSelectionChanged's own async continuation either, so this needs
    // the same runAsync + delay escape used elsewhere in this file (see
    // "Import JSON dialog accepts pasted text" above for the full
    // explanation). Without it, this hangs intermittently rather than
    // failing outright, since Hive's write sometimes completes within a
    // microtask and sometimes doesn't.
    await tester.runAsync(() async {
      await tester.tap(find.text('Dark'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(AppSettingsController.instance.themeMode, ThemeMode.dark);
    expect(
      Hive.box(HiveService.settingsBoxName).get('app_theme_mode'),
      'dark',
    );
  });

  testWidgets('picking an accent color persists and marks it selected',
      (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Same real-Hive-write-needs-runAsync reasoning as the theme mode
    // test above.
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Purple'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(AppSettingsController.instance.accentColor, AccentColor.purple);
    expect(
      Hive.box(HiveService.settingsBoxName).get('app_accent_color'),
      'purple',
    );
  });

  // Export/Import Calendar (.ics) dialog interactions are deliberately
  // NOT covered here by a widget test — see the Phase 11 report's Known
  // Limitations section. Root cause understood precisely: google_fonts'
  // `googleFontsTextStyle` kicks off font loading as a fire-and-forget
  // Future (no `.catchError`, only a cleanup `.then`), and once this
  // app depends on `http`/`supabase_flutter`, Flutter's test binding
  // detects an HttpClient in the process and forces every HTTP call —
  // including that unrelated font fetch — to return 400. The resulting
  // unhandled rejection surfaces later as a failure attributed to
  // whatever test happens to be running at that moment, not necessarily
  // the one that triggered the font load. This is a pre-existing
  // google_fonts/flutter_test interaction, not a bug in the ICS feature
  // itself — see `ics_calendar_sync_service_test.dart` for thorough,
  // reliable coverage of the actual import/export logic against real
  // Hive storage, and the "shows Appearance..." test above for
  // confirmation the two ListTiles are wired up.

  testWidgets('Privacy shows a dialog describing local-only storage',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    expect(find.textContaining('locally on this device'), findsOneWidget);
  });

  testWidgets('Licenses opens the built-in license page', (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();

    expect(find.text('ZenTask'), findsWidgets);
  });

  testWidgets('GitHub shows a not-configured message when no URL is set',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GitHub'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not configured yet'), findsOneWidget);
  });
}
