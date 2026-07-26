import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/features/ai_planner/screens/ai_planner_screen.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_ai_planner_screen_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveService.tasksBoxName);
    await Hive.openBox(HiveService.taskRecordsBoxName);
    await Hive.openBox(HiveService.settingsBoxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveService.tasksBoxName);
    await Hive.deleteBoxFromDisk(HiveService.taskRecordsBoxName);
    await Hive.deleteBoxFromDisk(HiveService.settingsBoxName);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: child);

  testWidgets('shows the empty state when there are no open tasks',
      (tester) async {
    await tester.pumpWidget(wrap(const AIPlannerScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('caught up'), findsOneWidget);
  });

  testWidgets('shows suggested focus order and explanations for open tasks',
      (tester) async {
    await tester.runAsync(() => TaskRepository().saveTaskRecord(
          Task.create(title: 'Submit report', priority: TaskPriority.urgent),
        ));

    await tester.pumpWidget(wrap(const AIPlannerScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Submit report'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
    expect(find.textContaining('No AI provider is connected'), findsOneWidget);
  });
}
