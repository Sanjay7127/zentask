import 'package:zentask/repositories/focus_session_repository.dart';

/// Aggregate stats over completed focus sessions (Phase 12).
class FocusStatistics {
  final int totalSessions;
  final int totalFocusMinutes;
  final int sessionsToday;
  final int sessionsThisWeek;
  final double averageSessionMinutes;

  const FocusStatistics({
    required this.totalSessions,
    required this.totalFocusMinutes,
    required this.sessionsToday,
    required this.sessionsThisWeek,
    required this.averageSessionMinutes,
  });
}

class FocusStatisticsService {
  final FocusSessionRepository _repository;

  FocusStatisticsService({FocusSessionRepository? repository})
      : _repository = repository ?? FocusSessionRepository();

  FocusStatistics compute({DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final sessions = _repository.getAll().where((s) => s.completed).toList();

    if (sessions.isEmpty) {
      return const FocusStatistics(
        totalSessions: 0,
        totalFocusMinutes: 0,
        sessionsToday: 0,
        sessionsThisWeek: 0,
        averageSessionMinutes: 0,
      );
    }

    final today = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day);
    final weekStart = today.subtract(Duration(days: today.weekday - DateTime.monday));

    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final sessionsToday =
        sessions.where((s) => !s.startedAt.isBefore(today)).length;
    final sessionsThisWeek =
        sessions.where((s) => !s.startedAt.isBefore(weekStart)).length;

    return FocusStatistics(
      totalSessions: sessions.length,
      totalFocusMinutes: totalSeconds ~/ 60,
      sessionsToday: sessionsToday,
      sessionsThisWeek: sessionsThisWeek,
      averageSessionMinutes: (totalSeconds / sessions.length) / 60,
    );
  }
}
