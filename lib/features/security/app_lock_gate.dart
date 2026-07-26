import 'package:flutter/material.dart';

import 'package:zentask/features/security/screens/app_lock_screen.dart';
import 'package:zentask/providers/app_lock_controller.dart';

/// Wraps the app shell and stacks [AppLockScreen] on top of it whenever
/// app lock is due, without ever unmounting [child] — so the tab index,
/// scroll positions, and nested navigator stacks underneath survive a
/// lock/unlock cycle intact.
///
/// Locked at startup whenever [AppLockController.enabled] is true, and
/// re-locked on foreground if the app spent at least
/// [AppLockController.autoLockAfter] backgrounded.
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final AppLockController _controller = AppLockController.instance;
  late bool _locked;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = _controller.enabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.enabled) return;
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >= _controller.autoLockAfter) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          AppLockScreen(onUnlocked: () => setState(() => _locked = false)),
      ],
    );
  }
}
