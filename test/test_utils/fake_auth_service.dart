import 'dart:async';

import 'package:zentask/services/cloud/auth_service.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';

/// Shared fake [AuthService] for widget/provider tests — mirrors
/// `FakeReminderScheduler`'s shape (Phase 9): configurable results,
/// tracks what was called, no real backend involved.
class FakeAuthService implements AuthService {
  AppUser? _currentUser;
  final _controller = StreamController<AppUser?>.broadcast();

  bool failSignIn = false;
  bool failGoogleAndApple = true;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  void _setUser(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (failSignIn) throw const CloudUnavailableException('sign up failed');
    final user = AppUser(id: 'user-$email', email: email);
    _setUser(user);
    return user;
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (failSignIn) throw const CloudUnavailableException('sign in failed');
    final user = AppUser(id: 'user-$email', email: email);
    _setUser(user);
    return user;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    if (failSignIn) throw const CloudUnavailableException('anon sign in failed');
    const user = AppUser(id: 'anon-user', isAnonymous: true);
    _setUser(user);
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (failGoogleAndApple) {
      throw const CloudUnavailableException('Google sign-in not configured');
    }
    const user = AppUser(id: 'google-user', email: 'g@example.com');
    _setUser(user);
    return user;
  }

  @override
  Future<AppUser> signInWithApple() async {
    if (failGoogleAndApple) {
      throw const CloudUnavailableException('Apple sign-in not configured');
    }
    const user = AppUser(id: 'apple-user', email: 'a@example.com');
    _setUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _setUser(null);
  }

  @override
  Future<void> signOutEverywhere() async {
    _setUser(null);
  }

  @override
  Future<AppUser> updateProfile({String? displayName}) async {
    final user = _currentUser;
    if (user == null) {
      throw const CloudUnavailableException('not signed in');
    }
    final updated = AppUser(
      id: user.id,
      email: user.email,
      displayName: displayName ?? user.displayName,
      isAnonymous: user.isAnonymous,
    );
    _setUser(updated);
    return updated;
  }

  void dispose() => _controller.close();
}
