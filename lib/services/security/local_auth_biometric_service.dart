import 'package:local_auth/local_auth.dart';

import 'package:zentask/services/security/biometric_auth_service.dart';

/// Real [BiometricAuthService] backed by `local_auth` — biometrics with
/// a device passcode/PIN fallback, matching what most apps mean by
/// "app lock".
class LocalAuthBiometricService implements BiometricAuthService {
  final LocalAuthentication _localAuth;

  LocalAuthBiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }
}
