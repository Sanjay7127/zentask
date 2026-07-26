import 'package:hive/hive.dart';
import 'package:zentask/models/habit.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for [Habit]s and their daily completions.
///
/// Completions are stored as `'<habitId>:<yyyy-MM-dd>' -> true` in a
/// separate box — the same key-existence-means-true shape as
/// [BookmarksRepository], since a completion has no fields of its own
/// beyond "did this happen on this day."
class HabitRepository {
  final Box _habitsBox;
  final Box _completionsBox;

  HabitRepository({Box? habitsBox, Box? completionsBox})
      : _habitsBox = habitsBox ?? HiveService.habitsBox,
        _completionsBox = completionsBox ?? HiveService.habitCompletionsBox;

  List<Habit> getAll() =>
      _habitsBox.values.map((raw) => Habit.fromMap(raw as Map)).toList();

  Future<void> save(Habit habit) => _habitsBox.put(habit.id, habit.toMap());

  Future<void> delete(String id) async {
    await _habitsBox.delete(id);
    final keysToRemove =
        _completionsBox.keys.cast<String>().where((k) => k.startsWith('$id:'));
    for (final key in keysToRemove.toList()) {
      await _completionsBox.delete(key);
    }
  }

  bool isCompletedOn(String habitId, DateTime date) {
    return _completionsBox.get(_key(habitId, date)) == true;
  }

  Future<void> setCompletedOn(String habitId, DateTime date, bool completed) {
    final key = _key(habitId, date);
    return completed ? _completionsBox.put(key, true) : _completionsBox.delete(key);
  }

  /// Every date [habitId] was completed on, ascending.
  List<DateTime> completionDatesFor(String habitId) {
    final prefix = '$habitId:';
    return _completionsBox.keys
        .cast<String>()
        .where((k) => k.startsWith(prefix))
        .map((k) => DateTime.parse(k.substring(prefix.length)))
        .toList()
      ..sort();
  }

  /// Current streak of consecutive completed days ending today (or
  /// yesterday, if today hasn't happened yet) — same rule as
  /// `AnalyticsEngine.currentStreak` (Phase 10).
  int currentStreakFor(String habitId, {DateTime? now}) {
    final dates = completionDatesFor(habitId).toSet();
    if (dates.isEmpty) return 0;

    final today = _dateOnly(now ?? DateTime.now());
    var cursor = today;
    if (!dates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!dates.contains(cursor)) return 0;
    }

    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The longest run of consecutive completed days ever, for [habitId] —
  /// same computation as `AnalyticsEngine.longestStreak` (Phase 10), just
  /// scoped to one habit's completion dates instead of task completions.
  int longestStreakFor(String habitId) {
    final dates = completionDatesFor(habitId);
    if (dates.isEmpty) return 0;

    var longest = 1;
    var current = 1;
    for (var i = 1; i < dates.length; i++) {
      final gap = dates[i].difference(dates[i - 1]).inDays;
      current = gap == 1 ? current + 1 : 1;
      if (current > longest) longest = current;
    }
    return longest;
  }

  String _key(String habitId, DateTime date) =>
      '$habitId:${_dateOnly(date).toIso8601String().substring(0, 10)}';

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}
