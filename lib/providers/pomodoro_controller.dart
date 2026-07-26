import 'package:flutter/foundation.dart';
import 'package:zentask/models/focus_session.dart';
import 'package:zentask/repositories/focus_session_repository.dart';

enum PomodoroPhase { work, shortBreak }

/// Pomodoro timer state (Phase 12). Deliberately has **no real
/// `Timer`/`Ticker` of its own — [tick] is a plain method the caller
/// invokes once per second (typically from a `Timer.periodic` owned by
/// the screen). Keeping the actual clock outside this class means tests
/// can drive it deterministically by calling [tick] directly, with no
/// need to fake a real timer.
class PomodoroController extends ChangeNotifier {
  final FocusSessionRepository _focusSessionRepository;
  final int workDurationSeconds;
  final int breakDurationSeconds;

  PomodoroPhase _phase = PomodoroPhase.work;
  int _remainingSeconds;
  bool _isRunning = false;
  DateTime? _phaseStartedAt;
  String? _taskId;

  PomodoroController({
    FocusSessionRepository? focusSessionRepository,
    this.workDurationSeconds = 25 * 60,
    this.breakDurationSeconds = 5 * 60,
    String? taskId,
  })  : _focusSessionRepository = focusSessionRepository ?? FocusSessionRepository(),
        _remainingSeconds = workDurationSeconds,
        _taskId = taskId;

  PomodoroPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  String? get taskId => _taskId;

  void setTaskId(String? taskId) {
    _taskId = taskId;
    notifyListeners();
  }

  void start() {
    _phaseStartedAt ??= DateTime.now();
    _isRunning = true;
    notifyListeners();
  }

  void pause() {
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _phase = PomodoroPhase.work;
    _remainingSeconds = workDurationSeconds;
    _phaseStartedAt = null;
    notifyListeners();
  }

  /// Advances the timer by one second. A no-op while paused.
  void tick() {
    if (!_isRunning) return;
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
      return;
    }
    _completePhase(completed: true);
  }

  /// Ends the current phase early (e.g. the user stops mid-session).
  /// Work phases are still recorded — a shorter, "not completed"
  /// session is still real focus time worth counting.
  void stopEarly() {
    if (_phase == PomodoroPhase.work) _completePhase(completed: false);
    reset();
  }

  void _completePhase({required bool completed}) {
    if (_phase == PomodoroPhase.work) {
      final startedAt = _phaseStartedAt ?? DateTime.now();
      _focusSessionRepository.save(FocusSession.create(
        taskId: _taskId,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        completed: completed,
      ));
      _phase = PomodoroPhase.shortBreak;
      _remainingSeconds = breakDurationSeconds;
    } else {
      _phase = PomodoroPhase.work;
      _remainingSeconds = workDurationSeconds;
    }
    _phaseStartedAt = DateTime.now();
    notifyListeners();
  }
}
