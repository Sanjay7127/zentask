import 'package:flutter/material.dart';
import 'package:zentask/models/task.dart';

/// Curated palette for project color-picking. `Project.colorValue` is a
/// plain `int` (the model has no Flutter dependency) — this is the UI
/// layer's mapping from that int to an actual [Color] and back.
const List<int> projectColorPalette = [
  0xFF01D1AF, // teal — the app's own brand color
  0xFF3F51B5, // indigo
  0xFFE91E63, // pink
  0xFFFF9800, // orange
  0xFF8E24AA, // purple
  0xFF2196F3, // blue
  0xFF43A047, // green
  0xFFE53935, // red
];

/// Curated icon set for `Project.iconKey`. A plain `String` key (not
/// Flutter's `IconData`) is stored on the model for the same reason
/// `colorValue` is an `int` — see the doc comment on [Project].
const Map<String, IconData> projectIconsByKey = {
  'folder': Icons.folder,
  'code': Icons.code,
  'school': Icons.school,
  'work': Icons.work,
  'star': Icons.star,
  'lightbulb': Icons.lightbulb,
  'rocket': Icons.rocket_launch,
  'trophy': Icons.emoji_events,
  'palette': Icons.palette,
  'fitness': Icons.fitness_center,
};

IconData iconForKey(String key) =>
    projectIconsByKey[key] ?? projectIconsByKey['folder']!;

Color colorForValue(int value) => Color(value);

/// Short label for a [TaskPriority] — kept as a function (rather than
/// changing every existing call site to `priority.label`) but delegates
/// to the shared [TaskPriorityLabel] extension so the wording has one
/// source of truth across UI and service-layer code (`ai_planner.dart`
/// also uses it).
String labelForPriority(TaskPriority priority) => priority.label;

Color colorForPriority(TaskPriority priority, ColorScheme colorScheme) {
  switch (priority) {
    case TaskPriority.low:
      return colorScheme.onSurfaceVariant;
    case TaskPriority.medium:
      return colorScheme.primary;
    case TaskPriority.high:
      return Colors.orange.shade700;
    case TaskPriority.urgent:
      return colorScheme.error;
  }
}
