import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/features/projects/widgets/project_form_dialog.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/theme/app_theme.dart';

void main() {
  testWidgets('submitting with a title closes the dialog',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showProjectFormDialog(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, 'New Project'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Dialog Test Project');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // The dialog should have closed after a valid submit.
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('cancelling returns null and closes the dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showProjectFormDialog(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('prefills fields when editing an existing project',
      (tester) async {
    final existing = Project.create(
      title: 'Existing Project',
      description: 'Existing notes',
      priority: TaskPriority.high,
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showProjectFormDialog(context, existing: existing);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, 'Edit Project'), findsOneWidget);
    expect(find.text('Existing Project'), findsOneWidget);
    expect(find.text('Existing notes'), findsOneWidget);
  });
}
