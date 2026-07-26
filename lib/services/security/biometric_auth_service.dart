/// Abstraction over device biometric/passcode authentication, so the
/// app-lock UI never depends on `local_auth` directly (mirrors the
/// interface-plus-swappable-implementation pattern used for cloud sync
/// and crash reporting elsewhere in the app).
abstract class BiometricAuthService {
  /// Whether this device can prompt for biometrics or a device
  /// passcode/PIN fallback at all.
  Future<bool> isAvailable();

  /// Prompts the user with [reason] and returns whether they
  /// authenticated successfully.
  Future<bool> authenticate(String reason);
}

/// Default no-op implementation for platforms/environments where
/// `local_auth` has no working backend (e.g. this sandbox's incomplete
/// desktop toolchains). Reports itself unavailable so callers fall back
/// to "no app lock" rather than a broken prompt.
class UnavailableBiometricAuthService implements BiometricAuthService {
  const UnavailableBiometricAuthService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}
