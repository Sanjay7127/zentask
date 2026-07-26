import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/features/projects/widgets/project_card.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      );

  testWidgets('shows title, progress, task counts, and priority',
      (tester) async {
    final project = Project.create(
      title: 'ZenTask Hackathon',
      priority: TaskPriority.urgent,
    );

    await tester.pumpWidget(wrap(ProjectCard(
      project: project,
      completedTaskCount: 3,
      totalTaskCount: 5,
      completionRate: 0.6,
      nextUpcomingTask: null,
      onTap: () {},
      onAction: (_) {},
    )));

    expect(find.text('ZenTask Hackathon'), findsOneWidget);
    expect(find.text('3 / 5 tasks'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
  });

  testWidgets('tapping the card invokes onTap', (tester) async {
    var tapped = false;
    final project = Project.create(title: 'Tap me');

    await tester.pumpWidget(wrap(ProjectCard(
      project: project,
      completedTaskCount: 0,
      totalTaskCount: 0,
      completionRate: 0.0,
      nextUpcomingTask: null,
      onTap: () => tapped = true,
      onAction: (_) {},
    )));

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(tapped, true);
  });

  testWidgets('shows "Archived" label for archived projects', (tester) async {
    final project = Project.create(title: 'Old').copyWith(isArchived: true);

    await tester.pumpWidget(wrap(ProjectCard(
      project: project,
      completedTaskCount: 0,
      totalTaskCount: 0,
      completionRate: 0.0,
      nextUpcomingTask: null,
      onTap: () {},
      onAction: (_) {},
    )));

    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('selecting a popup menu action invokes onAction',
      (tester) async {
    ProjectCardAction? selected;
    final project = Project.create(title: 'Menu test');

    await tester.pumpWidget(wrap(ProjectCard(
      project: project,
      completedTaskCount: 0,
      totalTaskCount: 0,
      completionRate: 0.0,
      nextUpcomingTask: null,
      onTap: () {},
      onAction: (action) => selected = action,
    )));

    await tester.tap(find.byType(PopupMenuButton<ProjectCardAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(selected, ProjectCardAction.archive);
  });
}
