enum SyncStatus { unavailable, idle, syncing, offline, error }

/// Cloud sync for Projects/Tasks/Events/Settings/Bookmarks.
/// [UnavailableSyncService] is the default (no backend configured);
/// [CloudSyncEngine] is the real Supabase-backed implementation. Mirrors
/// [AuthService]'s split for the same reason.
abstract class SyncService {
  Stream<SyncStatus> get statusStream;

  SyncStatus get currentStatus;

  /// Pushes local changes, then pulls remote changes. A no-op (not an
  /// error) when no user is signed in — there's nothing to sync yet.
  Future<void> syncNow();

  void startRealtime();

  void stopRealtime();

  void dispose();
}
