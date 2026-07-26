import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A bar chart whose bars grow from zero on first appearance —
/// [fl_chart]'s `BarChart` is an `ImplicitlyAnimatedWidget`, so starting
/// at zero and flipping to the real values one frame later makes it
/// tween smoothly instead of appearing instantly. Shared by the
/// Analytics dashboard's Weekly and Monthly Activity charts (Phase 10)
/// so this "how does an activity chart look" logic lives in one place.
class AnimatedBarChart extends StatefulWidget {
  final List<int> values;
  final List<String> labels;
  final Color color;
  final String semanticsLabel;

  const AnimatedBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    required this.semanticsLabel,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> {
  bool _animateIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animateIn = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final highest = widget.values.isEmpty
        ? 0
        : widget.values.reduce((a, b) => a > b ? a : b);
    final maxY = (highest < 4 ? 4 : highest).toDouble() + 1;

    return Semantics(
      label: '${widget.semanticsLabel}: ${widget.values.join(', ')}',
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= widget.labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.labels[index],
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(widget.values.length, (i) {
            final value = _animateIn ? widget.values[i].toDouble() : 0.0;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: value,
                color: widget.color,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ]);
          }),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
