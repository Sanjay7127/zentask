import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentask/providers/pomodoro_controller.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/focus/focus_statistics_service.dart';

/// Focus Mode / Pomodoro timer + Focus Statistics (Phase 12).
class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  final PomodoroController _controller = PomodoroController();
  final FocusStatisticsService _statisticsService = FocusStatisticsService();
  Timer? _ticker;
  PomodoroPhase _lastPhase = PomodoroPhase.work;

  @override
  void initState() {
    super.initState();
    _lastPhase = _controller.phase;
    _controller.addListener(_handleChanged);
  }

  // The countdown display/buttons rebuild every second via the
  // ListenableBuilder below, listening to _controller directly — this
  // handler only rebuilds the *rest* of the screen (Focus Statistics,
  // which re-scans the focus sessions box) when a phase actually
  // completes, not on every one-second tick.
  void _handleChanged() {
    if (_controller.phase != _lastPhase) {
      _lastPhase = _controller.phase;
      setState(() {});
    }
  }

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _controller.tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final minutes = _controller.remainingSeconds ~/ 60;
    final seconds = _controller.remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = _statisticsService.compute();
    final openTasks =
        TaskRepository().getAllTaskRecords().where((t) => !t.isDone).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Mode')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Only this subtree rebuilds once a second (it listens to
          // _controller directly) — everything outside it, including
          // the Focus Statistics scan below, is computed once per
          // screen build, not once a second. See _handleChanged's doc
          // comment for why.
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final isWork = _controller.phase == PomodoroPhase.work;
              return Column(
                children: [
                  Text(
                    isWork ? 'Focus' : 'Break',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isWork ? colorScheme.primary : colorScheme.tertiary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _timeLabel,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (openTasks.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      initialValue: _controller.taskId,
                      decoration: const InputDecoration(labelText: 'Focusing on (optional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No specific task')),
                        for (final task in openTasks)
                          DropdownMenuItem(value: task.id, child: Text(task.title)),
                      ],
                      onChanged: _controller.setTaskId,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _controller.isRunning
                            ? _controller.pause
                            : () {
                                _controller.start();
                                _startTicking();
                              },
                        icon: Icon(_controller.isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_controller.isRunning ? 'Pause' : 'Start'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          _ticker?.cancel();
                          _controller.stopEarly();
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text('Focus Statistics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _StatCard(label: 'Total sessions', value: '${stats.totalSessions}'),
              _StatCard(label: 'Total focus time', value: '${stats.totalFocusMinutes}m'),
              _StatCard(label: 'Sessions today', value: '${stats.sessionsToday}'),
              _StatCard(label: 'This week', value: '${stats.sessionsThisWeek}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    )),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
