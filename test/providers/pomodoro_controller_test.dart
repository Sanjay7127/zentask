import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/providers/pomodoro_controller.dart';
import 'package:zentask/repositories/focus_session_repository.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late FocusSessionRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_pomodoro_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('focus_sessions_test');
    repository = FocusSessionRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  PomodoroController controller({int work = 3, int shortBreak = 2}) =>
      PomodoroController(
        focusSessionRepository: repository,
        workDurationSeconds: work,
        breakDurationSeconds: shortBreak,
      );

  test('starts in the work phase, paused, at the full work duration', () {
    final c = controller(work: 25 * 60);
    expect(c.phase, PomodoroPhase.work);
    expect(c.isRunning, isFalse);
    expect(c.remainingSeconds, 25 * 60);
  });

  test('tick is a no-op while paused', () {
    final c = controller();
    c.tick();
    expect(c.remainingSeconds, 3);
  });

  test('start then tick counts down once per call', () {
    final c = controller();
    c.start();
    c.tick();
    expect(c.remainingSeconds, 2);
    c.tick();
    expect(c.remainingSeconds, 1);
  });

  test('work phase completing switches to a break and records a session', () {
    // tick() only decrements while remainingSeconds > 0; the phase
    // actually completes on the *next* tick after it hits 0, so a
    // 1-second phase needs 2 ticks (decrement to 0, then complete).
    final c = controller(work: 1, shortBreak: 5);
    c.start();
    c.tick();
    c.tick();
    expect(c.phase, PomodoroPhase.shortBreak);
    expect(c.remainingSeconds, 5);

    final sessions = repository.getAll();
    expect(sessions, hasLength(1));
    expect(sessions.single.completed, isTrue);
  });

  test('break phase completing switches back to work without a new session', () {
    final c = controller(work: 1, shortBreak: 1);
    c.start();
    c.tick(); // work: decrement to 0
    c.tick(); // work: completes -> break
    c.tick(); // break: decrement to 0
    c.tick(); // break: completes -> work
    expect(c.phase, PomodoroPhase.work);
    expect(repository.getAll(), hasLength(1));
  });

  test('stopEarly during work records an incomplete session and resets', () {
    final c = controller(work: 100);
    c.start();
    c.tick();
    c.stopEarly();

    final sessions = repository.getAll();
    expect(sessions, hasLength(1));
    expect(sessions.single.completed, isFalse);
    expect(c.phase, PomodoroPhase.work);
    expect(c.isRunning, isFalse);
    expect(c.remainingSeconds, 100);
  });

  test('stopEarly during a break records nothing new and resets to work', () {
    final c = controller(work: 1, shortBreak: 100);
    c.start();
    c.tick(); // completes work -> break, 1 session recorded
    c.stopEarly();

    expect(repository.getAll(), hasLength(1));
    expect(c.phase, PomodoroPhase.work);
  });

  test('setTaskId is reflected on the next recorded session', () {
    final c = controller(work: 1);
    c.setTaskId('task-1');
    c.start();
    c.tick(); // decrement to 0
    c.tick(); // completes -> session recorded

    expect(repository.getAll().single.taskId, 'task-1');
  });

  test('reset returns to the initial work phase without recording a session', () {
    final c = controller(work: 10);
    c.start();
    c.tick();
    c.reset();

    expect(c.phase, PomodoroPhase.work);
    expect(c.remainingSeconds, 10);
    expect(c.isRunning, isFalse);
    expect(repository.getAll(), isEmpty);
  });
}
