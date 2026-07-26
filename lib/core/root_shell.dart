import 'package:flutter/material.dart';
import 'package:zentask/features/analytics/screens/analytics_screen.dart';
import 'package:zentask/features/calendar/screens/calendar_screen.dart';
import 'package:zentask/features/projects/screens/projects_dashboard_screen.dart';
import 'package:zentask/features/settings/screens/settings_screen.dart';
import 'package:zentask/features/tasks/screens/home_screen.dart';

/// App-wide bottom navigation shell: Tasks / Projects / Calendar /
/// Analytics / Settings.
///
/// The existing [HomeScreen] (with its own `TaskController`) is hosted
/// unmodified as the Tasks tab — nesting a full `Scaffold` (with its own
/// `AppBar`) inside this shell's body is a standard, valid pattern for
/// bottom-nav apps where each tab manages its own top chrome. This
/// shell itself has no `AppBar`, only the `bottomNavigationBar`, so
/// there's no doubled-up app bar.
///
/// Every tab is now real (Phase 9, 10.1, 10.2, 10.3).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Projects',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Calendar',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Analytics',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          ProjectsDashboardScreen(),
          CalendarScreen(),
          AnalyticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: _destinations,
      ),
    );
  }
}
