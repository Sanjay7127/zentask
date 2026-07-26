import 'package:zentask/services/cloud/auth_service.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';

/// Default [AuthService] when no Supabase project is configured (see
/// `CloudConfig.hasSupabaseCredentials`). Every method fails clearly
/// rather than silently no-op-ing, so calling code and the UI always
/// know cloud features aren't set up instead of quietly doing nothing.
class UnavailableAuthService implements AuthService {
  const UnavailableAuthService();

  static const _message =
      'Cloud sync isn\'t configured for this app yet — no Supabase project is connected.';

  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      throw const CloudUnavailableException(_message);

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) =>
      throw const CloudUnavailableException(_message);

  @override
  Future<AppUser> signInAnonymously() =>
      throw const CloudUnavailableException(_message);

  @override
  Future<AppUser> signInWithGoogle() =>
      throw const CloudUnavailableException(_message);

  @override
  Future<AppUser> signInWithApple() =>
      throw const CloudUnavailableException(_message);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signOutEverywhere() async {}

  @override
  Future<AppUser> updateProfile({String? displayName}) =>
      throw const CloudUnavailableException(_message);
}
