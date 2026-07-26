import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/ai_planner_controller.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/ai/ai_planner.dart';

void main() {
  late Directory tempDir;
  late Box legacyBox;
  late Box recordsBox;
  late Box settingsBox;
  late TaskRepository taskRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_ai_planner_test');
    Hive.init(tempDir.path);
    legacyBox = await Hive.openBox('legacy_test');
    recordsBox = await Hive.openBox('records_test');
    settingsBox = await Hive.openBox('settings_test');
    taskRepository = TaskRepository(
      box: legacyBox,
      recordsBox: recordsBox,
      settingsBox: settingsBox,
    );
  });

  tearDown(() async {
    await legacyBox.deleteFromDisk();
    await recordsBox.deleteFromDisk();
    await settingsBox.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AIPlannerController controller({AIPlanner? planner}) => AIPlannerController(
        planner: planner ?? const UnavailableAIPlanner(),
        taskRepository: taskRepository,
      );

  Future<void> waitForLoad(AIPlannerController c) async {
    var attempts = 0;
    while (c.isLoading && attempts < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      attempts++;
    }
  }

  test('starts loading, then settles with an empty order when there are no '
      'open tasks', () async {
    final c = controller();
    await waitForLoad(c);
    expect(c.isLoading, false);
    expect(c.focusOrder, isEmpty);
  });

  test('includes only not-done tasks in the focus order', () async {
    await taskRepository.saveTaskRecord(
        Task.create(title: 'open', status: TaskStatus.todo));
    await taskRepository.saveTaskRecord(
        Task.create(title: 'done', status: TaskStatus.done));

    final c = controller();
    await waitForLoad(c);

    expect(c.focusOrder.map((t) => t.title), ['open']);
  });

  test('explanationFor returns a non-empty string for every task in the order',
      () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'A task'));

    final c = controller();
    await waitForLoad(c);

    final task = c.focusOrder.single;
    expect(c.explanationFor(task), isNotEmpty);
  });

  test('refresh reloads after new tasks are added', () async {
    final c = controller();
    await waitForLoad(c);
    expect(c.focusOrder, isEmpty);

    await taskRepository.saveTaskRecord(Task.create(title: 'New task'));
    await c.refresh();

    expect(c.focusOrder.map((t) => t.title), ['New task']);
  });

  test('orders tasks using whatever AIPlanner is injected (swap-ready)',
      () async {
    await taskRepository.saveTaskRecord(Task.create(title: 'A'));
    await taskRepository.saveTaskRecord(Task.create(title: 'B'));

    // A fake "AI" that always reverses the input order — proves the
    // controller defers entirely to the injected AIPlanner rather than
    // hardcoding UnavailableAIPlanner's heuristic.
    final c = controller(planner: _ReversingPlanner());
    await waitForLoad(c);

    expect(c.focusOrder.map((t) => t.title), ['B', 'A']);
  });
}

class _ReversingPlanner implements AIPlanner {
  @override
  Future<List<String>> suggestFocusOrder(List<Task> openTasks) async =>
      openTasks.reversed.map((t) => t.id).toList();

  @override
  Future<String> explainPriority(Task task) async => 'reversed order';

  @override
  Future<AITaskSuggestion> parseTaskFromText(String input) async =>
      AITaskSuggestion(title: input);

  @override
  Future<List<String>> suggestSubtasks({
    required String taskTitle,
    String? taskDescription,
  }) async =>
      const [];

  @override
  Future<String> generateDailyPlan(List<Task> openTasks) async => 'reversed plan';

  @override
  Future<Duration> estimateTaskDuration(Task task) async =>
      const Duration(minutes: 30);

  @override
  Future<String> summarizeWorkload(List<Task> openTasks) async => 'reversed workload';

  @override
  Future<String> summarizeProject(Project project, List<Task> tasks) async =>
      'reversed summary';
}
