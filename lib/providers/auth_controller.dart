import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zentask/config/cloud_config.dart';
import 'package:zentask/services/cloud/auth_service.dart';
import 'package:zentask/services/cloud/supabase_auth_service.dart';
import 'package:zentask/services/cloud/unavailable_auth_service.dart';

/// App-wide auth state, mirroring [AppSettingsController]'s
/// lazily-created-singleton shape (Phase 10) for the same reason: the
/// Settings/Account screen mutates auth state that other parts of the
/// app — eventually [SyncController] — need to observe too.
class AuthController extends ChangeNotifier {
  static AuthController? _instance;

  static AuthController get instance => _instance ??= AuthController();

  @visibleForTesting
  static void resetInstanceForTesting() => _instance = null;

  /// Lets a widget test point the shared singleton at a controller built
  /// around a [FakeAuthService], since screens like `AccountScreen`
  /// read `AuthController.instance` directly rather than taking one as
  /// a constructor parameter.
  @visibleForTesting
  static void setInstanceForTesting(AuthController controller) =>
      _instance = controller;

  final AuthService _authService;
  StreamSubscription<AppUser?>? _subscription;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _lastError;

  AuthController({AuthService? authService})
      : _authService = authService ??
            (CloudConfig.hasSupabaseCredentials
                ? SupabaseAuthService()
                : const UnavailableAuthService()) {
    _currentUser = _authService.currentUser;
    _subscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Exposed so [SyncController] can build a [CloudSyncEngine] against
  /// the same underlying [AuthService] this controller uses — sync and
  /// auth must always agree on who's signed in.
  AuthService get authService => _authService;

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) => _run(() async {
        _currentUser =
            await _authService.signUpWithEmail(email: email, password: password);
      });

  Future<void> signInWithEmail(String email, String password) => _run(() async {
        _currentUser =
            await _authService.signInWithEmail(email: email, password: password);
      });

  Future<void> signInAnonymously() => _run(() async {
        _currentUser = await _authService.signInAnonymously();
      });

  Future<void> signInWithGoogle() => _run(() async {
        _currentUser = await _authService.signInWithGoogle();
      });

  Future<void> signInWithApple() => _run(() async {
        _currentUser = await _authService.signInWithApple();
      });

  Future<void> signOut() => _run(() async {
        await _authService.signOut();
        _currentUser = null;
      });

  Future<void> signOutEverywhere() => _run(() async {
        await _authService.signOutEverywhere();
        _currentUser = null;
      });

  Future<void> updateProfile({String? displayName}) => _run(() async {
        _currentUser = await _authService.updateProfile(displayName: displayName);
      });

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
