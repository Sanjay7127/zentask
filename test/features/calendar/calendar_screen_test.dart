import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/features/calendar/screens/calendar_screen.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_calendar_screen_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.tasksBoxName);
    await Hive.openBox(HiveService.taskRecordsBoxName);
    await Hive.openBox(HiveService.projectsBoxName);
    await Hive.openBox(HiveService.eventsBoxName);
    await Hive.openBox(HiveService.settingsBoxName);
    await Hive.openBox(HiveService.bookmarksBoxName);
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

  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

  testWidgets('shows the current month and the Month/Week/Agenda toggle',
      (tester) async {
    await tester.pumpWidget(wrap(const CalendarScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
  });

  testWidgets('switching to Week view shows a 7-day strip', (tester) async {
    await tester.pumpWidget(wrap(const CalendarScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
  });

  testWidgets('switching to Agenda view shows an empty-state message with no data',
      (tester) async {
    await tester.pumpWidget(wrap(const CalendarScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing coming up'), findsOneWidget);
  });

  testWidgets('a task due today shows up in Agenda view', (tester) async {
    await tester.runAsync(() => TaskRepository().saveTaskRecord(
          Task.create(title: 'Ship the release', dueDate: DateTime.now()),
        ));

    await tester.pumpWidget(wrap(const CalendarScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Ship the release'), findsOneWidget);
  });

  testWidgets('tapping Today re-centers the calendar on today', (tester) async {
    await tester.pumpWidget(wrap(const CalendarScreen()));
    await tester.pumpAndSettle();

    // Navigate away first, then confirm "Today" brings the title back.
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Today'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    expect(find.text('${months[now.month - 1]} ${now.year}'), findsOneWidget);
  });
}
