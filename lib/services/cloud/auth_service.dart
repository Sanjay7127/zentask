/// A signed-in cloud user — deliberately a small, SDK-independent shape
/// (not `supabase`'s own `User` type) so the rest of the app depends on
/// this interface, not on Supabase specifically. Swapping [AuthService]
/// implementations later never requires touching UI code.
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });
}

/// Cloud authentication, covering every method Phase 11 asked for.
/// [UnavailableAuthService] is the default (no backend configured);
/// [SupabaseAuthService] is the real implementation — email and
/// anonymous sign-in only for now. Google/Apple throw
/// [CloudUnavailableException] even in the real implementation: those
/// need their own OAuth client credentials, which haven't been supplied
/// yet, so promising them here would be dishonest about what actually
/// works. Extending [SupabaseAuthService] to support them later needs no
/// interface change.
abstract class AuthService {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signInAnonymously();

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<void> signOut();

  /// Invalidates every session for this user, not just the current
  /// device's — e.g. "sign out everywhere" after a suspected compromise.
  Future<void> signOutEverywhere();

  Future<AppUser> updateProfile({String? displayName});
}
