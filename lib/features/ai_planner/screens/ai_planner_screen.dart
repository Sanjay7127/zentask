import 'package:flutter/material.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/providers/ai_planner_controller.dart';

/// AI Planner page: suggested focus order + per-task priority
/// explanations, backed by whatever [AIPlannerController]'s [AIPlanner]
/// happens to be — currently [UnavailableAIPlanner]'s local heuristic.
/// A future real AI provider plugs in behind the same controller
/// without this screen changing.
class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final AIPlannerController _controller = AIPlannerController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _controller.refresh,
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No AI provider is connected yet — this order '
                          'is a local suggestion based on due dates and '
                          'priority.',
                          style: textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Suggested Focus Order', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                if (_controller.focusOrder.isEmpty)
                  _EmptyState(colorScheme: colorScheme, textTheme: textTheme)
                else
                  ..._controller.focusOrder.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    return _FocusOrderTile(
                      position: index + 1,
                      title: task.title,
                      priority: task.priority,
                      explanation: _controller.explanationFor(task),
                    );
                  }),
              ],
            ),
    );
  }
}

class _FocusOrderTile extends StatelessWidget {
  final int position;
  final String title;
  final TaskPriority priority;
  final String explanation;

  const _FocusOrderTile({
    required this.position,
    required this.title,
    required this.priority,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text('$position'),
        ),
        title: Text(title),
        subtitle: Text(explanation),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorForPriority(priority, colorScheme).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            labelForPriority(priority),
            style: TextStyle(
              color: colorForPriority(priority, colorScheme),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  const _EmptyState({required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No open tasks — you\'re all caught up!',
              style:
                  textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
