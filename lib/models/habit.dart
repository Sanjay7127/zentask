import 'package:zentask/utils/id_generator.dart';

enum HabitFrequency { daily, weekly }

/// A recurring habit to check off (Phase 12) — distinct from
/// [Recurrence] (which generates new *task* occurrences): a habit has
/// no due date or completion state of its own, just a daily/weekly
/// rhythm of check-ins tracked by [HabitCompletionRepository].
class Habit {
  final String id;
  final String title;
  final HabitFrequency frequency;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.title,
    required this.frequency,
    required this.createdAt,
  });

  factory Habit.create({
    required String title,
    HabitFrequency frequency = HabitFrequency.daily,
  }) {
    return Habit(
      id: generateId(),
      title: title,
      frequency: frequency,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'frequency': frequency.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromMap(Map<dynamic, dynamic> map) => Habit(
        id: map['id'] as String,
        title: map['title'] as String,
        frequency: HabitFrequency.values.firstWhere(
          (f) => f.name == map['frequency'],
          orElse: () => HabitFrequency.daily,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
