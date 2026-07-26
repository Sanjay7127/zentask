import 'package:zentask/models/task.dart';
import 'package:zentask/utils/id_generator.dart';

enum ProjectCategory { work, personal, hackathon, study, other }

/// A container for related tasks, optionally linked to a Competition,
/// Hackathon, Event, or personal goal via [linkedEventId].
///
/// Deliberately does **not** store a completion percentage: that's
/// derived from this project's tasks, and persisting it here would
/// create a second source of truth that can silently go stale the
/// moment a task changes without this record being updated too.
/// Computed on demand instead — see `AnalyticsEngine.projectCompletionRate`
/// (Phase 6) — rather than stored redundantly here.
///
/// `colorValue`/`iconKey` are plain `int`/`String` rather than Flutter's
/// `Color`/`IconData` so this model has no Flutter dependency, matching
/// the existing `Task` model — the UI layer maps `iconKey` to an actual
/// icon and `colorValue` to a `Color`.
///
/// `priority` reuses [TaskPriority] (Phase 7) rather than a duplicate
/// project-specific enum — it's the same real-world concept (how
/// urgently this thing deserves attention), just at the project level
/// instead of the task level.
class Project {
  final String id;
  final String title;
  final String description;
  final int colorValue;
  final String iconKey;
  final ProjectCategory category;
  final TaskPriority priority;
  final bool isArchived;
  final bool isFavorite;
  final String? linkedEventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.title,
    this.description = '',
    this.colorValue = 0xFF01D1AF,
    this.iconKey = 'folder',
    this.category = ProjectCategory.other,
    this.priority = TaskPriority.medium,
    this.isArchived = false,
    this.isFavorite = false,
    this.linkedEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.create({
    required String title,
    String description = '',
    int colorValue = 0xFF01D1AF,
    String iconKey = 'folder',
    ProjectCategory category = ProjectCategory.other,
    TaskPriority priority = TaskPriority.medium,
    String? linkedEventId,
  }) {
    final now = DateTime.now();
    return Project(
      id: generateId(),
      title: title,
      description: description,
      colorValue: colorValue,
      iconKey: iconKey,
      category: category,
      priority: priority,
      linkedEventId: linkedEventId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Project copyWith({
    String? title,
    String? description,
    int? colorValue,
    String? iconKey,
    ProjectCategory? category,
    TaskPriority? priority,
    bool? isArchived,
    bool? isFavorite,
    String? linkedEventId,
  }) =>
      Project(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        colorValue: colorValue ?? this.colorValue,
        iconKey: iconKey ?? this.iconKey,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        isArchived: isArchived ?? this.isArchived,
        isFavorite: isFavorite ?? this.isFavorite,
        linkedEventId: linkedEventId ?? this.linkedEventId,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'colorValue': colorValue,
        'iconKey': iconKey,
        'category': category.name,
        'priority': priority.name,
        'isArchived': isArchived,
        'isFavorite': isFavorite,
        'linkedEventId': linkedEventId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Project.fromMap(Map<dynamic, dynamic> map) => Project(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        colorValue: map['colorValue'] as int? ?? 0xFF01D1AF,
        iconKey: map['iconKey'] as String? ?? 'folder',
        category: ProjectCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => ProjectCategory.other,
        ),
        priority: TaskPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => TaskPriority.medium,
        ),
        isArchived: map['isArchived'] as bool? ?? false,
        isFavorite: map['isFavorite'] as bool? ?? false,
        linkedEventId: map['linkedEventId'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
