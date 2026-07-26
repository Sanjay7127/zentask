import 'package:flutter/material.dart';
import 'package:zentask/features/calendar/utils/calendar_visuals.dart';
import 'package:zentask/features/calendar/widgets/timeline_entry_tile.dart';
import 'package:zentask/features/projects/utils/project_visuals.dart';
import 'package:zentask/providers/calendar_controller.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

/// The Calendar tab: Month / Week / Agenda views over [TimelineEngine]'s
/// aggregated tasks + events (Phase 10).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarController _controller = CalendarController();

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

  Future<void> _jumpToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) _controller.jumpToDate(picked);
  }

  String get _titleLabel {
    switch (_controller.viewMode) {
      case CalendarViewMode.month:
        return formatMonthYear(_controller.focusedMonth);
      case CalendarViewMode.week:
        final start = _controller.weekStart(_controller.selectedDate);
        final end = start.add(const Duration(days: 6));
        return '${formatShortDate(start)} – ${formatShortDate(end)}';
      case CalendarViewMode.agenda:
        return 'Agenda';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleLabel),
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today_outlined),
            onPressed: _controller.goToToday,
          ),
          IconButton(
            tooltip: 'Jump to date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _jumpToDate,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _controller.goToPrevious,
                ),
                Expanded(
                  child: SegmentedButton<CalendarViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: CalendarViewMode.month,
                        label: Text('Month'),
                      ),
                      ButtonSegment(
                        value: CalendarViewMode.week,
                        label: Text('Week'),
                      ),
                      ButtonSegment(
                        value: CalendarViewMode.agenda,
                        label: Text('Agenda'),
                      ),
                    ],
                    selected: {_controller.viewMode},
                    onSelectionChanged: (selection) =>
                        _controller.setViewMode(selection.first),
                  ),
                ),
                IconButton(
                  tooltip: 'Next',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _controller.goToNext,
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_controller.viewMode) {
      case CalendarViewMode.month:
        return _MonthView(
          key: ValueKey('month-${_controller.focusedMonth}'),
          controller: _controller,
          onSelectDate: _controller.selectDateAndShowAgenda,
        );
      case CalendarViewMode.week:
        return _WeekView(
          key: ValueKey('week-${_controller.weekStart(_controller.selectedDate)}'),
          controller: _controller,
          onSelectDate: _controller.selectDateAndShowAgenda,
        );
      case CalendarViewMode.agenda:
        return _AgendaView(
          key: ValueKey('agenda-${_controller.selectedDate}'),
          controller: _controller,
        );
    }
  }
}

class _MonthView extends StatelessWidget {
  final CalendarController controller;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthView({
    super.key,
    required this.controller,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final month = controller.focusedMonth;
    final gridStart = controller.monthGridStart(month);
    final entriesByDay = controller.entriesByDayForMonthGrid(month);
    final today = controller.today;
    final selected = controller.selectedDate;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: weekdayAbbreviations
              .map((label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = gridStart.add(Duration(days: index));
              return RepaintBoundary(
                child: _MonthDayCell(
                  day: day,
                  inMonth: day.month == month.month,
                  isToday: isSameDay(day, today),
                  isSelected: isSameDay(day, selected),
                  entries: entriesByDay[day] ?? const [],
                  controller: controller,
                  onTap: () => onSelectDate(day),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<TimelineEntry> entries;
  final CalendarController controller;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.entries,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleEntries = entries.take(4).toList();
    final hasOverdue = entries.any(controller.isEntryOverdue);

    return Semantics(
      label: '${formatShortDate(day)}'
          '${isToday ? ', today' : ''}'
          '${entries.isEmpty ? ', no items' : ', ${entries.length} item${entries.length == 1 ? '' : 's'}'}'
          '${hasOverdue ? ', has overdue items' : ''}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : null,
            border: isToday && !isSelected
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: inMonth
                      ? (isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface)
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (visibleEntries.isNotEmpty) ...[
                const SizedBox(height: 2),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  children: visibleEntries.map((entry) {
                    final completed = controller.isEntryCompleted(entry);
                    final overdue = controller.isEntryOverdue(entry);
                    final colorValue = controller.colorValueForEntry(entry);
                    final color = overdue
                        ? colorScheme.error
                        : colorValue != null
                            ? colorForValue(colorValue)
                            : defaultColorForEntryType(entry.type, colorScheme);
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed ? Colors.transparent : color,
                        border: completed ? Border.all(color: color, width: 1) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  final CalendarController controller;
  final ValueChanged<DateTime> onSelectDate;

  const _WeekView({
    super.key,
    required this.controller,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final start = controller.weekStart(controller.selectedDate);
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    final today = controller.today;
    final colorScheme = Theme.of(context).colorScheme;

    final weekEntries = <MapEntry<DateTime, List<TimelineEntry>>>[];
    for (final day in days) {
      final entries = controller.entriesForDay(day);
      if (entries.isNotEmpty) weekEntries.add(MapEntry(day, entries));
    }

    return Column(
      children: [
        SizedBox(
          height: 72,
          child: Row(
            children: days.map((day) {
              final isToday = isSameDay(day, today);
              final isSelected = isSameDay(day, controller.selectedDate);
              final count = controller.entriesForDay(day).length;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelectDate(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primaryContainer : null,
                      border: isToday && !isSelected
                          ? Border.all(color: colorScheme.primary, width: 1.5)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(weekdayAbbreviations[day.weekday - 1],
                            style: Theme.of(context).textTheme.labelSmall),
                        Text('${day.day}',
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? colorScheme.onPrimaryContainer : null,
                            )),
                        if (count > 0)
                          Text('$count', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: weekEntries.isEmpty
              ? const _EmptyTimelineMessage(message: 'No items this week')
              : ListView.builder(
                  itemCount: weekEntries.length,
                  itemBuilder: (context, index) {
                    final day = weekEntries[index].key;
                    final entries = weekEntries[index].value;
                    return RepaintBoundary(
                      child: _DayGroup(
                        day: day,
                        entries: entries,
                        controller: controller,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AgendaView extends StatelessWidget {
  final CalendarController controller;

  const _AgendaView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final entries = controller.agendaEntries();
    final grouped = <DateTime, List<TimelineEntry>>{};
    for (final entry in entries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      grouped.putIfAbsent(day, () => []).add(entry);
    }
    final days = grouped.keys.toList()..sort();

    if (days.isEmpty) {
      return const _EmptyTimelineMessage(
        message: 'Nothing coming up in the next 30 days',
      );
    }

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return RepaintBoundary(
          child: _DayGroup(
            day: day,
            entries: grouped[day]!,
            controller: controller,
          ),
        );
      },
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime day;
  final List<TimelineEntry> entries;
  final CalendarController controller;

  const _DayGroup({
    required this.day,
    required this.entries,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = isSameDay(day, controller.today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            isToday ? 'Today • ${formatShortDate(day)}' : formatShortDate(day),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...entries.map((entry) {
          final completed = controller.isEntryCompleted(entry);
          final overdue = controller.isEntryOverdue(entry);
          final colorValue = controller.colorValueForEntry(entry);
          final color = colorValue != null
              ? colorForValue(colorValue)
              : defaultColorForEntryType(entry.type, colorScheme);
          return TimelineEntryTile(
            entry: entry,
            color: color,
            completed: completed,
            overdue: overdue,
          );
        }),
      ],
    );
  }
}

class _EmptyTimelineMessage extends StatelessWidget {
  final String message;
  const _EmptyTimelineMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
