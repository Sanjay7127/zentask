import 'package:zentask/services/cloud/sync_service.dart';

/// Default [SyncService] when no Supabase project is configured.
class UnavailableSyncService implements SyncService {
  const UnavailableSyncService();

  @override
  Stream<SyncStatus> get statusStream =>
      Stream<SyncStatus>.value(SyncStatus.unavailable);

  @override
  SyncStatus get currentStatus => SyncStatus.unavailable;

  @override
  Future<void> syncNow() async {}

  @override
  void startRealtime() {}

  @override
  void stopRealtime() {}

  @override
  void dispose() {}
}
