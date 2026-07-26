import 'dart:async';

import 'package:zentask/services/cloud/sync_service.dart';

/// Shared fake [SyncService] for testing [SyncController] without a real
/// Supabase client.
class FakeSyncService implements SyncService {
  final _controller = StreamController<SyncStatus>.broadcast();
  SyncStatus _status;
  bool failNextSync = false;
  int syncCallCount = 0;
  bool realtimeStarted = false;

  FakeSyncService({SyncStatus initialStatus = SyncStatus.idle})
      : _status = initialStatus;

  @override
  SyncStatus get currentStatus => _status;

  @override
  Stream<SyncStatus> get statusStream => _controller.stream;

  void _setStatus(SyncStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  Future<void> syncNow() async {
    syncCallCount++;
    _setStatus(SyncStatus.syncing);
    if (failNextSync) {
      _setStatus(SyncStatus.error);
      throw Exception('sync failed');
    }
    _setStatus(SyncStatus.idle);
  }

  @override
  void startRealtime() => realtimeStarted = true;

  @override
  void stopRealtime() => realtimeStarted = false;

  @override
  void dispose() => _controller.close();
}
