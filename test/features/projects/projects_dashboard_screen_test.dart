import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zentask/features/projects/screens/projects_dashboard_screen.dart';
import 'package:zentask/features/projects/widgets/project_card.dart';
import 'package:zentask/features/projects/widgets/project_list_tile.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_dashboard_test');
    Hive.init(tempDir.path);
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

  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: child);

  testWidgets('shows empty state when there are no projects', (tester) async {
    await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
  });

  testWidgets('displays a project that already exists in the repository',
      (tester) async {
    // Seeding via the repository (rather than driving the create dialog
    // through simulated taps) keeps this test focused on one thing:
    // does the dashboard correctly render project data that's there.
    // The dialog's own submit behavior is covered by
    // project_form_dialog_test.dart, and ProjectsController's create/
    // archive/delete logic is covered by projects_controller_test.dart
    // — this screen test only needs to prove those pieces are wired
    // together correctly, not re-verify each of them end-to-end.
    //
    // Hive's write is real disk I/O, which never resolves inside a
    // testWidgets callback's FakeAsync zone unless explicitly escaped
    // via runAsync — awaiting it directly would hang indefinitely.
    await tester.runAsync(() =>
        ProjectRepository().save(Project.create(title: 'Seeded Project')));

    await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Seeded Project'), findsOneWidget);
    expect(find.text('Total Projects'), findsOneWidget);
    expect(find.text('No projects yet'), findsNothing);
  });

  testWidgets('tapping the FAB opens the create-project dialog',
      (tester) async {
    await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, 'New Project'), findsOneWidget);
  });

  group('search, filter, sort, and view toggle (Phase 9)', () {
    Future<void> seedTwoProjects(WidgetTester tester) async {
      await tester.runAsync(() async {
        await ProjectRepository().save(Project.create(title: 'Alpha Launch'));
        await ProjectRepository().save(Project.create(title: 'Beta Cleanup'));
      });
    }

    testWidgets('search narrows the visible projects', (tester) async {
      await seedTwoProjects(tester);
      await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Launch'), findsOneWidget);
      expect(find.text('Beta Cleanup'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.pumpAndSettle();

      expect(find.text('Alpha Launch'), findsOneWidget);
      expect(find.text('Beta Cleanup'), findsNothing);
    });

    testWidgets('a search with no matches shows a helpful message',
        (tester) async {
      await seedTwoProjects(tester);
      await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nonexistent project');
      await tester.pumpAndSettle();

      expect(find.textContaining('No projects match'), findsOneWidget);
    });

    testWidgets('filter chips narrow to archived projects', (tester) async {
      await seedTwoProjects(tester);
      await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final repo = ProjectRepository();
        final betaCleanup =
            repo.getAll().firstWhere((p) => p.title == 'Beta Cleanup');
        await repo.save(betaCleanup.copyWith(isArchived: true));
      });

      // Re-pump with a fresh key so Flutter actually unmounts the old
      // State (and its already-loaded ProjectsController) instead of
      // reusing it in place — a plain `const ProjectsDashboardScreen()`
      // with no key is the *same* widget as far as element reconciliation
      // is concerned, so the archive write above would otherwise never
      // be picked up.
      await tester.pumpWidget(wrap(ProjectsDashboardScreen(key: UniqueKey())));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Beta Cleanup'), findsOneWidget);
      expect(find.text('Alpha Launch'), findsNothing);
    });

    testWidgets('view toggle switches between grid and list layouts',
        (tester) async {
      await seedTwoProjects(tester);
      await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
      await tester.pumpAndSettle();

      // _DashboardStats renders its own GridView.count regardless of the
      // toggle, so asserting on raw GridView presence/count would also
      // match that always-there stats grid — assert on the
      // project-display widgets themselves instead.
      expect(find.byType(ProjectCard), findsWidgets);
      expect(find.byType(ProjectListTile), findsNothing);

      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectCard), findsNothing);
      expect(find.byType(ProjectListTile), findsWidgets);
    });

    testWidgets('sort menu reorders projects by name', (tester) async {
      await seedTwoProjects(tester);
      await tester.pumpWidget(wrap(const ProjectsDashboardScreen()));
      await tester.pumpAndSettle();

      // Switch to list view so project order is easy to read top-to-bottom.
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      final titles = tester
          .widgetList<Text>(find.descendant(
            of: find.byType(ListTile),
            matching: find.textContaining(RegExp('Launch|Cleanup')),
          ))
          .map((t) => t.data)
          .toList();
      expect(titles, ['Alpha Launch', 'Beta Cleanup']);
    });
  });
}
