import 'package:zentask/utils/id_generator.dart';

/// A user-defined, reusable label (Phase 12) — distinct from
/// [Task.tags] (free-form strings with no identity of their own):
/// labels are managed on their own screen, have a color, and are
/// referenced by id from [Task.labelIds] so renaming/recoloring a label
/// doesn't require touching every task that uses it.
class Label {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;

  const Label({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  factory Label.create({required String name, int colorValue = 0xFF01D1AF}) {
    return Label(
      id: generateId(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
  }

  Label copyWith({String? name, int? colorValue}) => Label(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Label.fromMap(Map<dynamic, dynamic> map) => Label(
        id: map['id'] as String,
        name: map['name'] as String,
        colorValue: map['colorValue'] as int? ?? 0xFF01D1AF,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
