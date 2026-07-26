import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/accent_color.dart';

/// App-wide appearance settings: theme mode (Light/Dark/System) and
/// accent color, persisted to the settings box and applied by rebuilding
/// [AppTheme] at runtime (Phase 9's confirmed approach for this).
///
/// Unlike every other controller in this app (constructed fresh per
/// screen), this one needs a single shared instance: the root
/// [MainApp] listens to it to rebuild `MaterialApp`'s `theme`/
/// `themeMode`, and the Settings screen (nested deep below it) needs to
/// mutate that same instance. [instance] is a lazily-created singleton
/// for that reason — the plain constructor still exists (and still
/// accepts an injectable [settingsBox]) so this controller's own logic
/// can be unit-tested in isolation without touching the singleton.
class AppSettingsController extends ChangeNotifier {
  static AppSettingsController? _instance;

  static AppSettingsController get instance =>
      _instance ??= AppSettingsController();

  /// Widget tests that pump a screen depending on [instance] directly
  /// (rather than going through `MainApp`) need this to discard a
  /// previous test's box reference before the next test's `setUp` opens
  /// a fresh one.
  @visibleForTesting
  static void resetInstanceForTesting() => _instance = null;

  final Box _settingsBox;

  static const String _themeModeKey = 'app_theme_mode';
  static const String _accentColorKey = 'app_accent_color';

  late ThemeMode _themeMode;
  late AccentColor _accentColor;

  AppSettingsController({Box? settingsBox})
      : _settingsBox = settingsBox ?? HiveService.settingsBox {
    _themeMode = _readThemeMode();
    _accentColor = _readAccentColor();
  }

  ThemeMode get themeMode => _themeMode;
  AccentColor get accentColor => _accentColor;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _settingsBox.put(_themeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> setAccentColor(AccentColor color) async {
    _accentColor = color;
    await _settingsBox.put(_accentColorKey, color.name);
    notifyListeners();
  }

  ThemeMode _readThemeMode() {
    final stored = _settingsBox.get(_themeModeKey) as String?;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  AccentColor _readAccentColor() {
    final stored = _settingsBox.get(_accentColorKey) as String?;
    return AccentColor.values.firstWhere(
      (color) => color.name == stored,
      orElse: () => AccentColor.teal,
    );
  }
}
