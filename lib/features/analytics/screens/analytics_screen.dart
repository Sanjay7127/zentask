import 'package:flutter/material.dart';
import 'package:zentask/features/analytics/widgets/animated_bar_chart.dart';
import 'package:zentask/providers/analytics_controller.dart';

/// The Analytics tab: productivity metrics from [AnalyticsEngine] plus
/// project counts from [ProjectsController], with animated activity
/// charts (Phase 10).
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsController _controller = AnalyticsController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _controller.snapshot;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'Total Tasks',
                value: '${snapshot.totalTasks}',
                icon: Icons.checklist_outlined,
              ),
              _StatCard(
                label: 'Completed',
                value: '${snapshot.completedTasks}',
                icon: Icons.task_alt,
              ),
              _StatCard(
                label: 'Completion %',
                value: '${(snapshot.completionRate * 100).round()}%',
                icon: Icons.pie_chart_outline,
              ),
              _StatCard(
                label: 'Productivity Score',
                value: snapshot.productivityScore.round().toString(),
                icon: Icons.bolt_outlined,
              ),
              _StatCard(
                label: 'Active Projects',
                value: '${_controller.activeProjectCount}',
                icon: Icons.folder_outlined,
              ),
              _StatCard(
                label: 'Finished Projects',
                value: '${_controller.finishedProjectCount}',
                icon: Icons.folder_copy_outlined,
              ),
              _StatCard(
                label: 'Streak',
                value: '${_controller.currentStreak}',
                icon: Icons.local_fire_department_outlined,
              ),
              _StatCard(
                label: 'Longest Streak',
                value: '${_controller.longestStreak}',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Weekly Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: AnimatedBarChart(
              values: _controller.weeklyActivity,
              labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              color: colorScheme.primary,
              semanticsLabel: 'Tasks completed per day, last 7 days',
            ),
          ),
          const SizedBox(height: 24),
          Text('Monthly Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: AnimatedBarChart(
              values: _controller.monthlyActivity,
              labels: const ['W1', 'W2', 'W3', 'W4', 'W5'],
              color: colorScheme.tertiary,
              semanticsLabel: 'Tasks completed per week, last 5 weeks',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
