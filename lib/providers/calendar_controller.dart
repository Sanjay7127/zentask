import 'package:flutter/foundation.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/repositories/project_repository.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/timeline/timeline_engine.dart';

enum CalendarViewMode { month, week, agenda }

/// Business-logic layer for the Calendar screen: wraps [TimelineEngine]
/// (Phase 3.4) with view-mode/navigation state and the lookups its UI
/// needs for color coding and completed/overdue indicators — those
/// lookups stay here rather than on [TimelineEntry] itself, since the
/// engine's entries are deliberately minimal (see its own doc comment)
/// and don't carry `isDone`/project color.
///
/// Returns raw `int?` color values (not `Color`) for the same reason
/// `Project.colorValue` is an `int` — matches this codebase's existing
/// split of "models/providers stay Flutter-light, the UI layer maps
/// values to `Color`/`IconData`" (see `project_visuals.dart`).
class CalendarController extends ChangeNotifier {
  final TimelineEngine _timelineEngine;
  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;

  CalendarViewMode _viewMode = CalendarViewMode.month;
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  CalendarController({
    TimelineEngine? timelineEngine,
    TaskRepository? taskRepository,
    ProjectRepository? projectRepository,
    DateTime? initialDate,
  })  : _timelineEngine = timelineEngine ?? TimelineEngine(),
        _taskRepository = taskRepository ?? TaskRepository(),
        _projectRepository = projectRepository ?? ProjectRepository() {
    final today = _dateOnly(initialDate ?? DateTime.now());
    _selectedDate = today;
    _focusedMonth = DateTime(today.year, today.month);
  }

  CalendarViewMode get viewMode => _viewMode;
  DateTime get focusedMonth => _focusedMonth;
  DateTime get selectedDate => _selectedDate;
  DateTime get today => _dateOnly(DateTime.now());

  void setViewMode(CalendarViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
  }

  void goToToday() {
    final now = today;
    _selectedDate = now;
    _focusedMonth = DateTime(now.year, now.month);
    notifyListeners();
  }

  void goToPrevious() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
        break;
      case CalendarViewMode.week:
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
        break;
      case CalendarViewMode.agenda:
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        break;
    }
    notifyListeners();
  }

  void goToNext() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
        break;
      case CalendarViewMode.week:
        _selectedDate = _selectedDate.add(const Duration(days: 7));
        _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
        break;
      case CalendarViewMode.agenda:
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        break;
    }
    notifyListeners();
  }

  void jumpToDate(DateTime date) {
    final day = _dateOnly(date);
    _selectedDate = day;
    _focusedMonth = DateTime(day.year, day.month);
    notifyListeners();
  }

  /// Selects [date] and switches to Agenda view in one step — "tap a
  /// date to see its agenda" (Phase 10).
  void selectDateAndShowAgenda(DateTime date) {
    final day = _dateOnly(date);
    _selectedDate = day;
    _focusedMonth = DateTime(day.year, day.month);
    _viewMode = CalendarViewMode.agenda;
    notifyListeners();
  }

  /// The Monday on/before the 1st of [month] — the first cell of that
  /// month's 6-row (42-day) grid.
  DateTime monthGridStart(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysFromMonday = firstOfMonth.weekday - DateTime.monday;
    return firstOfMonth.subtract(Duration(days: daysFromMonday));
  }

  /// The Monday on/before [date] — start of that week.
  DateTime weekStart(DateTime date) {
    final day = _dateOnly(date);
    final daysFromMonday = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: daysFromMonday));
  }

  List<TimelineEntry> entriesForDay(DateTime day) {
    final start = _dateOnly(day);
    final end = start.add(const Duration(days: 1));
    return _timelineEngine
        .buildTimeline(from: start, to: end)
        .where((e) => e.date.isBefore(end))
        .toList();
  }

  /// Every entry across the 42-day grid containing [month], grouped by
  /// day — computed once per month-view build rather than once per cell.
  Map<DateTime, List<TimelineEntry>> entriesByDayForMonthGrid(DateTime month) {
    final gridStart = monthGridStart(month);
    final gridEnd = gridStart.add(const Duration(days: 42));
    final entries = _timelineEngine.buildTimeline(from: gridStart, to: gridEnd);
    final map = <DateTime, List<TimelineEntry>>{};
    for (final entry in entries) {
      final day = _dateOnly(entry.date);
      map.putIfAbsent(day, () => []).add(entry);
    }
    return map;
  }

  /// Entries for the rolling Agenda window: [days] days starting at
  /// [selectedDate].
  List<TimelineEntry> agendaEntries({int days = 30}) {
    final start = _selectedDate;
    final end = start.add(Duration(days: days));
    return _timelineEngine.buildTimeline(from: start, to: end);
  }

  bool isEntryCompleted(TimelineEntry entry) {
    final task = _findTask(entry);
    return task?.isDone ?? false;
  }

  bool isEntryOverdue(TimelineEntry entry) {
    if (entry.type != TimelineEntryType.taskDue) return false;
    if (isEntryCompleted(entry)) return false;
    return entry.date.isBefore(today);
  }

  /// The project color behind a task entry, or `null` if the task has no
  /// project (or this isn't a task entry) — the UI falls back to a
  /// theme color in that case, same as `ProjectCard` does.
  int? colorValueForEntry(TimelineEntry entry) {
    final projectId = _findTask(entry)?.projectId;
    if (projectId == null) return null;
    return _projectRepository.getById(projectId)?.colorValue;
  }

  Task? _findTask(TimelineEntry entry) {
    if (entry.type != TimelineEntryType.taskDue &&
        entry.type != TimelineEntryType.taskReminder) {
      return null;
    }
    for (final task in _taskRepository.getAllTaskRecords()) {
      if (task.id == entry.sourceId) return task;
    }
    return null;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
