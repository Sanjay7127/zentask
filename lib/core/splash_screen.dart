import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentask/core/root_shell.dart';

/// Branded launch screen shown briefly before handing off to [RootShell]
/// (the bottom-nav shell; Tasks — the original [HomeScreen] — is its
/// first tab, Phase 7).
///
/// The icon mark below is a code-drawn placeholder standing in for the
/// generated app icon (a flowing check/"Z" mark on a teal gradient tile).
/// Swap the `_Mark` widget's child for `Image.asset(...)` once the real
/// icon asset is in place.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Mark(colorScheme: colorScheme),
            const SizedBox(height: 24),
            Text(
              'ZenTask',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder icon mark: a rounded-square gradient tile with a check.
class _Mark extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Mark({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.check_rounded,
        color: colorScheme.onPrimary,
        size: 64,
      ),
    );
  }
}
