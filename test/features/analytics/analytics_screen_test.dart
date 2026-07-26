import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/features/analytics/screens/analytics_screen.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_analytics_screen_test');
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

  // The stat grid + two 180px charts are taller than the test binding's
  // default viewport — see the equivalent helper in
  // settings_screen_test.dart for why this is needed.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows all stat cards and both activity charts with no data',
      (tester) async {
    useTallViewport(tester);
    await tester.pumpWidget(wrap(const AnalyticsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Total Tasks'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Completion %'), findsOneWidget);
    expect(find.text('Productivity Score'), findsOneWidget);
    expect(find.text('Active Projects'), findsOneWidget);
    expect(find.text('Finished Projects'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('Longest Streak'), findsOneWidget);
    expect(find.text('Weekly Activity'), findsOneWidget);
    expect(find.text('Monthly Activity'), findsOneWidget);
  });

  testWidgets('reflects a completed task in the stat cards', (tester) async {
    useTallViewport(tester);
    await tester.runAsync(() => TaskRepository().saveTaskRecord(
          Task.create(title: 'Done thing', status: TaskStatus.done),
        ));

    await tester.pumpWidget(wrap(const AnalyticsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets); // Total Tasks and Completed both read 1
    expect(find.text('100%'), findsOneWidget);
  });
}
