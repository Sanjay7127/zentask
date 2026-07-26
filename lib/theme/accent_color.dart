import 'package:flutter/material.dart';

/// The user-selectable accent colors for Phase 10's Appearance settings.
///
/// [teal] is deliberately the same value as [AppTheme.seedColor] — it's
/// the default, so choosing it (or never changing the setting) reproduces
/// the app's original look exactly, with no visual change out of the box.
enum AccentColor { blue, purple, green, orange, pink, red, teal }

extension AccentColorX on AccentColor {
  Color get color {
    switch (this) {
      case AccentColor.blue:
        return const Color(0xFF2563EB);
      case AccentColor.purple:
        return const Color(0xFF9333EA);
      case AccentColor.green:
        return const Color(0xFF16A34A);
      case AccentColor.orange:
        return const Color(0xFFEA580C);
      case AccentColor.pink:
        return const Color(0xFFDB2777);
      case AccentColor.red:
        return const Color(0xFFDC2626);
      case AccentColor.teal:
        return const Color(0xFF01D1AF);
    }
  }

  String get label {
    switch (this) {
      case AccentColor.blue:
        return 'Blue';
      case AccentColor.purple:
        return 'Purple';
      case AccentColor.green:
        return 'Green';
      case AccentColor.orange:
        return 'Orange';
      case AccentColor.pink:
        return 'Pink';
      case AccentColor.red:
        return 'Red';
      case AccentColor.teal:
        return 'Teal';
    }
  }
}
