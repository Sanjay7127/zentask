import 'package:zentask/utils/id_generator.dart';

/// A measurable target with a progress value (Phase 12) — e.g. "Read 12
/// books this year," tracked as `currentValue`/`targetValue`.
class Goal {
  final String id;
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final DateTime? targetDate;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    this.description = '',
    required this.targetValue,
    this.currentValue = 0,
    this.targetDate,
    required this.createdAt,
  });

  double get progress => targetValue <= 0
      ? 0
      : (currentValue / targetValue).clamp(0, 1).toDouble();

  bool get isComplete => currentValue >= targetValue;

  factory Goal.create({
    required String title,
    String description = '',
    required double targetValue,
    DateTime? targetDate,
  }) {
    return Goal(
      id: generateId(),
      title: title,
      description: description,
      targetValue: targetValue,
      targetDate: targetDate,
      createdAt: DateTime.now(),
    );
  }

  Goal copyWith({
    String? title,
    String? description,
    double? targetValue,
    double? currentValue,
    DateTime? targetDate,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        targetValue: targetValue ?? this.targetValue,
        currentValue: currentValue ?? this.currentValue,
        targetDate: targetDate ?? this.targetDate,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'targetDate': targetDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromMap(Map<dynamic, dynamic> map) => Goal(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        targetValue: (map['targetValue'] as num).toDouble(),
        currentValue: (map['currentValue'] as num?)?.toDouble() ?? 0,
        targetDate: map['targetDate'] != null
            ? DateTime.parse(map['targetDate'] as String)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
