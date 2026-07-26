import 'package:zentask/utils/id_generator.dart';

/// One completed (or abandoned) Pomodoro work interval (Phase 12) —
/// feeds Focus Statistics. Only work intervals are recorded; breaks
/// aren't "focus time" and aren't tracked as sessions.
class FocusSession {
  final String id;
  final String? taskId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final bool completed;

  const FocusSession({
    required this.id,
    this.taskId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.completed,
  });

  factory FocusSession.create({
    String? taskId,
    required DateTime startedAt,
    required DateTime endedAt,
    required bool completed,
  }) {
    return FocusSession(
      id: generateId(),
      taskId: taskId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: endedAt.difference(startedAt).inSeconds,
      completed: completed,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'taskId': taskId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'completed': completed,
      };

  factory FocusSession.fromMap(Map<dynamic, dynamic> map) => FocusSession(
        id: map['id'] as String,
        taskId: map['taskId'] as String?,
        startedAt: DateTime.parse(map['startedAt'] as String),
        endedAt: DateTime.parse(map['endedAt'] as String),
        durationSeconds: map['durationSeconds'] as int,
        completed: map['completed'] as bool? ?? false,
      );
}
