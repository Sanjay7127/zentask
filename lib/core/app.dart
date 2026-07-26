import 'package:flutter/material.dart';
import 'package:zentask/core/splash_screen.dart';
import 'package:zentask/features/security/app_lock_gate.dart';
import 'package:zentask/providers/app_settings_controller.dart';
import 'package:zentask/theme/accent_color.dart';
import 'package:zentask/theme/app_theme.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final AppSettingsController _settings = AppSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    // AppSettingsController.instance is app-wide and outlives this
    // widget — only stop listening, never dispose the shared instance.
    _settings.removeListener(_handleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLight(_settings.accentColor.color),
      darkTheme: AppTheme.buildDark(_settings.accentColor.color),
      themeMode: _settings.themeMode,
      // Wraps the Navigator (not just a single route) so the lock
      // overlay persists across Splash → RootShell and every push/pop
      // inside RootShell, rather than being torn down on navigation.
      builder: (context, child) => AppLockGate(child: child!),
      home: const SplashScreen(),
    );
  }
}
