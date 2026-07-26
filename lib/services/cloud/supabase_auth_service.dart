import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:zentask/services/cloud/auth_service.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';

/// Real [AuthService] backed by Supabase Auth (GoTrue). Email and
/// anonymous sign-in are fully implemented; Google and Apple throw
/// [CloudUnavailableException] until their OAuth client credentials are
/// configured (a separate setup step from having a Supabase project at
/// all) — see the doc comment on [AuthService].
class SupabaseAuthService implements AuthService {
  final supabase.SupabaseClient _client;

  static const _oauthNotConfigured =
      'This sign-in method needs its own OAuth client credentials, which '
      'haven\'t been configured yet.';

  SupabaseAuthService({supabase.SupabaseClient? client})
      : _client = client ?? supabase.Supabase.instance.client;

  @override
  Stream<AppUser?> get authStateChanges => _client.auth.onAuthStateChange
      .map((state) => _toAppUser(state.session?.user));

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(email: email, password: password);
    return _requireUser(response.user);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth
        .signInWithPassword(email: email, password: password);
    return _requireUser(response.user);
  }

  @override
  Future<AppUser> signInAnonymously() async {
    final response = await _client.auth.signInAnonymously();
    return _requireUser(response.user);
  }

  @override
  Future<AppUser> signInWithGoogle() =>
      throw const CloudUnavailableException(_oauthNotConfigured);

  @override
  Future<AppUser> signInWithApple() =>
      throw const CloudUnavailableException(_oauthNotConfigured);

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> signOutEverywhere() =>
      _client.auth.signOut(scope: supabase.SignOutScope.global);

  @override
  Future<AppUser> updateProfile({String? displayName}) async {
    final response = await _client.auth.updateUser(
      supabase.UserAttributes(
        data: displayName == null ? null : {'display_name': displayName},
      ),
    );
    return _requireUser(response.user);
  }

  AppUser _requireUser(supabase.User? user) {
    final appUser = _toAppUser(user);
    if (appUser == null) {
      throw const CloudUnavailableException(
          'Supabase did not return a signed-in user.');
    }
    return appUser;
  }

  AppUser? _toAppUser(supabase.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name'] as String?,
      isAnonymous: user.isAnonymous,
    );
  }
}
