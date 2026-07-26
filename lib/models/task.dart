import 'package:zentask/utils/id_generator.dart';

/// Priority level for a [Task] (and, since Phase 7, a [Project]).
enum TaskPriority { low, medium, high, urgent }

/// Shared human-readable label for [TaskPriority] — pure Dart (no
/// Flutter dependency, matching this file's models), so both UI code
/// (`project_visuals.dart`) and service-layer code (`ai_planner.dart`)
/// can use the same wording without duplicating the switch statement.
extension TaskPriorityLabel on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}

/// Workflow state for a [Task], distinct from the legacy [Task.isDone]
/// flag.
///
/// Kept as an independent field rather than derived solely from
/// [Task.isDone] because it carries more states (`inProgress`,
/// `blocked`) than a single boolean can express. [Task.copyWith] keeps
/// the two in sync whenever either is passed explicitly, so the only way
/// they could drift is a future call site that mutates the box data
/// directly instead of going through the model — worth keeping in mind
/// once task-editing UI lands (Phase 3.3).
enum TaskStatus { todo, inProgress, done, blocked }

/// How often a [Task] recurs. `none` means it doesn't repeat.
enum RecurrenceFrequency { none, daily, weekly, monthly }

class Recurrence {
  final RecurrenceFrequency frequency;
  final int interval;

  const Recurrence({
    this.frequency = RecurrenceFrequency.none,
    this.interval = 1,
  });

  Map<String, dynamic> toMap() => {
        'frequency': frequency.name,
        'interval': interval,
      };

  factory Recurrence.fromMap(Map<dynamic, dynamic> map) => Recurrence(
        frequency: RecurrenceFrequency.values.firstWhere(
          (f) => f.name == map['frequency'],
          orElse: () => RecurrenceFrequency.none,
        ),
        interval: map['interval'] as int? ?? 1,
      );
}

/// A checklist item nested inside a [Task].
class Subtask {
  final String id;
  final String title;
  final bool completed;

  const Subtask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Subtask copyWith({String? title, bool? completed}) => Subtask(
        id: id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'completed': completed,
      };

  factory Subtask.fromMap(Map<dynamic, dynamic> map) => Subtask(
        id: map['id'] as String,
        title: map['title'] as String,
        completed: map['completed'] as bool? ?? false,
      );
}

/// A single to-do item.
///
/// **Backward compatibility note (Phase 3):** `title` and `isDone` are
/// the original fields from before Phase 3 — `TaskController`/
/// `HomeScreen` still construct and read `Task` through them exactly as
/// before, via the unchanged [fromStorage]/[toStorage] pair (legacy
/// `mybox`/`TODOLIST` format). Every field below is new, added
/// additively with safe defaults so those existing call sites keep
/// compiling and behaving unchanged.
///
/// `completed` is a read-only alias for `isDone` (not a second stored
/// bool) — the two would otherwise be the same fact stored twice, which
/// is exactly the kind of duplicated state that drifts and causes bugs.
///
/// New rich tasks (with a project, priority, subtasks, etc.) are stored
/// via [toMap]/[fromMap] in the new `task_records` Hive box; use
/// [Task.create] to build one of those instead of the legacy positional
/// constructor.
class Task {
  final String id;
  final String? projectId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminder;
  final TaskStatus status;
  final bool isDone;
  final List<String> tags;
  final List<Subtask> subtasks;
  final Recurrence? recurrence;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Pinned tasks surface in the Pinned Tasks section regardless of
  /// project/priority (Phase 12). Plain `bool`, same reasoning as every
  /// other flag on this model — one field, one source of truth.
  final bool isPinned;

  /// [Label] ids attached to this task (Phase 12) — a task can carry
  /// several. Distinct from [tags] (free-form strings with no color or
  /// management UI of their own): labels are a curated, reusable set
  /// managed on their own screen.
  final List<String> labelIds;

  const Task({
    required this.title,
    required this.isDone,
    this.id = '',
    this.projectId,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.reminder,
    TaskStatus? status,
    this.tags = const [],
    this.subtasks = const [],
    this.recurrence,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.labelIds = const [],
  }) : status = status ?? (isDone ? TaskStatus.done : TaskStatus.todo);

  /// Read-only alias for [isDone] using Phase 3's naming. There is
  /// exactly one source of truth for "is this task done" — this getter,
  /// not a second stored field.
  bool get completed => isDone;

  /// Builds a fully-formed rich task with a generated id and timestamps.
  /// Prefer this over the positional constructor for anything created
  /// from Phase 3 onward.
  factory Task.create({
    required String title,
    String? projectId,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? reminder,
    TaskStatus status = TaskStatus.todo,
    List<String> tags = const [],
    List<Subtask> subtasks = const [],
    Recurrence? recurrence,
    int order = 0,
    bool isPinned = false,
    List<String> labelIds = const [],
  }) {
    final now = DateTime.now();
    return Task(
      id: generateId(),
      title: title,
      isDone: status == TaskStatus.done,
      projectId: projectId,
      description: description,
      priority: priority,
      dueDate: dueDate,
      reminder: reminder,
      status: status,
      tags: tags,
      subtasks: subtasks,
      recurrence: recurrence,
      order: order,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
      labelIds: labelIds,
    );
  }

  /// Legacy positional shape: `[String title, bool isDone]`. Unchanged
  /// from before Phase 3 — still what `TaskRepository`'s original
  /// `loadTasks`/`saveTasks` read and write against `mybox`/`TODOLIST`.
  factory Task.fromStorage(List<dynamic> raw) => Task(
        title: raw[0] as String,
        isDone: raw[1] as bool,
      );

  List<dynamic> toStorage() => [title, isDone];

  /// Rich map shape for the new `task_records` Hive box.
  Map<String, dynamic> toMap() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'reminder': reminder?.toIso8601String(),
        'status': status.name,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'recurrence': recurrence?.toMap(),
        'order': order,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isPinned': isPinned,
        'labelIds': labelIds,
      };

  factory Task.fromMap(Map<dynamic, dynamic> map) {
    final status = TaskStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => TaskStatus.todo,
    );
    return Task(
      id: map['id'] as String,
      projectId: map['projectId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      reminder: map['reminder'] != null
          ? DateTime.parse(map['reminder'] as String)
          : null,
      status: status,
      isDone: status == TaskStatus.done,
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      subtasks: (map['subtasks'] as List?)
              ?.map((s) => Subtask.fromMap(s as Map))
              .toList() ??
          const [],
      recurrence: map['recurrence'] != null
          ? Recurrence.fromMap(map['recurrence'] as Map)
          : null,
      order: map['order'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      isPinned: map['isPinned'] as bool? ?? false,
      labelIds: (map['labelIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  /// Standard `copyWith` null-coalescing convention: passing `null` for
  /// any parameter means "leave this field unchanged," not "set it to
  /// null." There is currently no field here that ever needs to be
  /// explicitly cleared via `copyWith` — [projectId] is the one
  /// exception, and [unassignFromProject] exists specifically because
  /// `copyWith(projectId: null)` cannot express "clear it."
  Task copyWith({
    String? title,
    bool? isDone,
    String? projectId,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? reminder,
    TaskStatus? status,
    List<String>? tags,
    List<Subtask>? subtasks,
    Recurrence? recurrence,
    int? order,
    bool? isPinned,
    List<String>? labelIds,
  }) {
    final effectiveStatus = status ??
        (isDone != null
            ? (isDone ? TaskStatus.done : TaskStatus.todo)
            : this.status);
    final effectiveIsDone =
        isDone ?? (status != null ? status == TaskStatus.done : this.isDone);
    return Task(
      id: id,
      title: title ?? this.title,
      isDone: effectiveIsDone,
      status: effectiveStatus,
      projectId: projectId ?? this.projectId,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      reminder: reminder ?? this.reminder,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      recurrence: recurrence ?? this.recurrence,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
      labelIds: labelIds ?? this.labelIds,
    );
  }

  /// Returns a copy with [projectId] cleared (set to `null`).
  ///
  /// Exists because `copyWith(projectId: null)` can't do this — see the
  /// doc comment on [copyWith]. Used when a project is deleted: its
  /// tasks are unassigned rather than deleted, so no task data is lost
  /// (Phase 7).
  Task unassignFromProject() => Task(
        id: id,
        title: title,
        isDone: isDone,
        status: status,
        projectId: null,
        description: description,
        priority: priority,
        dueDate: dueDate,
        reminder: reminder,
        tags: tags,
        subtasks: subtasks,
        recurrence: recurrence,
        order: order,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        isPinned: isPinned,
        labelIds: labelIds,
      );

  /// Returns a copy with [dueDate] cleared. Same reasoning as
  /// [unassignFromProject] — `copyWith(dueDate: null)` can't do this
  /// (Phase 7).
  Task withoutDueDate() => Task(
        id: id,
        title: title,
        isDone: isDone,
        status: status,
        projectId: projectId,
        description: description,
        priority: priority,
        dueDate: null,
        reminder: reminder,
        tags: tags,
        subtasks: subtasks,
        recurrence: recurrence,
        order: order,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        isPinned: isPinned,
        labelIds: labelIds,
      );

  /// Returns a copy with [reminder] cleared. Same reasoning as
  /// [unassignFromProject] — `copyWith(reminder: null)` can't do this
  /// (Phase 7).
  Task withoutReminder() => Task(
        id: id,
        title: title,
        isDone: isDone,
        status: status,
        projectId: projectId,
        description: description,
        priority: priority,
        dueDate: dueDate,
        reminder: null,
        tags: tags,
        subtasks: subtasks,
        recurrence: recurrence,
        order: order,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        isPinned: isPinned,
        labelIds: labelIds,
      );
}
