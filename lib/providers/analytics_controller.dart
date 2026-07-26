import 'package:flutter/foundation.dart';
import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/services/analytics/analytics_engine.dart';

/// Business-logic layer for the Analytics dashboard: wraps
/// [AnalyticsEngine] for task metrics and reuses [ProjectsController]
/// for project counts (Phase 10) rather than duplicating that logic
/// here — `ProjectsController.activeProjectCount`/`finishedProjectCount`
/// already exist and are exactly what this screen needs.
class AnalyticsController extends ChangeNotifier {
  final AnalyticsEngine _analyticsEngine;
  final ProjectsController _projectsController;

  AnalyticsController({
    AnalyticsEngine? analyticsEngine,
    ProjectsController? projectsController,
  })  : _analyticsEngine = analyticsEngine ?? AnalyticsEngine(),
        _projectsController = projectsController ?? ProjectsController();

  ProductivitySnapshot get snapshot => _analyticsEngine.computeSnapshot();

  int get activeProjectCount => _projectsController.activeProjectCount;

  int get finishedProjectCount => _projectsController.finishedProjectCount;

  int get currentStreak => _analyticsEngine.currentStreak();

  int get longestStreak => _analyticsEngine.longestStreak();

  /// Tasks completed per day for the last 7 days, oldest first.
  List<int> get weeklyActivity => _analyticsEngine.weeklyActivity();

  /// Tasks completed per week for the last 5 weeks, oldest first.
  List<int> get monthlyActivity => _analyticsEngine.monthlyActivity();

  @override
  void dispose() {
    _projectsController.dispose();
    super.dispose();
  }
}
