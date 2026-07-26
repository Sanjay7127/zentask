import 'package:flutter/material.dart';
import 'package:zentask/services/achievements/achievements_engine.dart';

const Map<String, IconData> _achievementIconsByKey = {
  'star': Icons.star,
  'checklist': Icons.checklist,
  'trophy': Icons.emoji_events,
  'fire': Icons.local_fire_department,
  'folder': Icons.folder,
  'timer': Icons.timer,
  'habit': Icons.repeat,
};

/// Achievements / Gamification (Phase 12): a fixed set of milestones
/// evaluated against real usage data, unlocked permanently once earned.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementsEngine _engine = AchievementsEngine();
  List<AchievementStatus> _statuses = [];

  @override
  void initState() {
    super.initState();
    _statuses = _engine.evaluate();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unlockedCount = _statuses.where((s) => s.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$unlockedCount of ${_statuses.length} unlocked',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final icon =
                    _achievementIconsByKey[status.definition.iconKey] ?? Icons.star;
                return Semantics(
                  label:
                      '${status.definition.title}: ${status.isUnlocked ? 'unlocked' : 'locked'}',
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: status.isUnlocked
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      foregroundColor: status.isUnlocked
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      child: Icon(icon),
                    ),
                    title: Text(
                      status.definition.title,
                      style: TextStyle(
                        color: status.isUnlocked ? null : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    subtitle: Text(status.definition.description),
                    trailing: status.isUnlocked
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
