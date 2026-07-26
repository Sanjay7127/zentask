import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:zentask/services/hive_service.dart';
import 'package:zentask/services/security/biometric_auth_service.dart';
import 'package:zentask/services/security/local_auth_biometric_service.dart';

/// App-lock (biometric/passcode) settings and session state.
///
/// Mirrors [AppSettingsController]'s singleton pattern: [AppLockGate] and
/// [SecurityScreen] both need to share one instance — the gate reads
/// [enabled] on every lifecycle change, the settings screen flips it —
/// so this is a lazily-created singleton with a plain, injectable
/// constructor underneath for unit tests.
class AppLockController extends ChangeNotifier {
  static AppLockController? _instance;

  static AppLockController get instance => _instance ??= AppLockController();

  @visibleForTesting
  static void resetInstanceForTesting() => _instance = null;

  final Box _settingsBox;
  final BiometricAuthService _biometricAuthService;

  static const String _enabledKey = 'app_lock_enabled';

  /// How long the app can sit backgrounded before [AppLockGate] demands
  /// re-authentication on foreground. Fixed rather than user-configurable
  /// for now — a reasonable default that keeps the feature simple.
  final Duration autoLockAfter = const Duration(minutes: 1);

  late bool _enabled;

  AppLockController({Box? settingsBox, BiometricAuthService? biometricAuthService})
      : _settingsBox = settingsBox ?? HiveService.settingsBox,
        _biometricAuthService =
            biometricAuthService ?? LocalAuthBiometricService() {
    _enabled = _settingsBox.get(_enabledKey, defaultValue: false) as bool;
  }

  bool get enabled => _enabled;

  Future<bool> isBiometricAvailable() => _biometricAuthService.isAvailable();

  /// Enables app lock. Callers should confirm [isBiometricAvailable]
  /// first — enabling on a device with no biometric/passcode backend
  /// would otherwise lock the user out with no way to authenticate.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _settingsBox.put(_enabledKey, value);
    notifyListeners();
  }

  Future<bool> authenticate({String reason = 'Unlock ZenTask'}) {
    return _biometricAuthService.authenticate(reason);
  }
}
