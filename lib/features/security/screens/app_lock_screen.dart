import 'package:flutter/material.dart';

import 'package:zentask/providers/app_lock_controller.dart';

/// Full-screen lock shown by [AppLockGate] at startup and after the app
/// returns from the background beyond [AppLockController.autoLockAfter].
/// Opaque and full-bleed so it fully occludes whatever screen was open
/// underneath — it is stacked on top of the live app rather than
/// replacing it, so unlocking simply removes it and the app resumes
/// exactly where the user left off.
class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockController _controller = AppLockController.instance;
  bool _authenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
  }

  Future<void> _attemptUnlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    final success = await _controller.authenticate();
    if (!mounted) return;
    if (success) {
      widget.onUnlocked();
    } else {
      setState(() {
        _authenticating = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 72, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text('ZenTask is locked', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  _failed
                      ? 'Authentication failed. Try again.'
                      : 'Authenticate to continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _authenticating ? null : _attemptUnlock,
                  icon: _authenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(_authenticating ? 'Authenticating...' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
