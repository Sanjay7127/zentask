import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ZenTask's shared Material 3 theme.
///
/// One seed color drives the whole light/dark tonal palette, and Poppins is
/// wired in once here instead of being called inline in every widget.
class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF01D1AF);

  static ThemeData get light => _build(Brightness.light, seedColor);

  static ThemeData get dark => _build(Brightness.dark, seedColor);

  /// Same as [light] but with a caller-chosen seed color (Phase 10's
  /// accent color setting). Added alongside [light]/[dark] rather than
  /// replacing them, so every existing call site (including ~10 test
  /// files using `AppTheme.light`/`AppTheme.dark` as getters) keeps
  /// compiling unchanged.
  static ThemeData buildLight(Color accent) => _build(Brightness.light, accent);

  /// Same as [dark] but with a caller-chosen seed color.
  static ThemeData buildDark(Color accent) => _build(Brightness.dark, accent);

  static ThemeData _build(Brightness brightness, Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
