import 'package:flutter/foundation.dart';
import 'package:zentask/config/cloud_config.dart';
import 'package:zentask/providers/auth_controller.dart';
import 'package:zentask/services/cloud/cloud_sync_engine.dart';
import 'package:zentask/services/cloud/sync_service.dart';
import 'package:zentask/services/cloud/unavailable_sync_service.dart';

/// App-wide sync state — same lazily-created-singleton shape as
/// [AppSettingsController]/[AuthController].
class SyncController extends ChangeNotifier {
  static SyncController? _instance;

  static SyncController get instance => _instance ??= SyncController();

  @visibleForTesting
  static void resetInstanceForTesting() => _instance = null;

  final SyncService _syncService;
  SyncStatus _status;
  String? _lastError;

  SyncController({SyncService? syncService})
      : _syncService = syncService ??
            (CloudConfig.hasSupabaseCredentials
                ? CloudSyncEngine(authService: AuthController.instance.authService)
                : const UnavailableSyncService()),
        _status = SyncStatus.unavailable {
    _status = _syncService.currentStatus;
    _syncService.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });
  }

  SyncStatus get status => _status;
  String? get lastError => _lastError;

  Future<void> syncNow() async {
    _lastError = null;
    try {
      await _syncService.syncNow();
    } catch (e) {
      _lastError = e.toString();
    }
    // Read the service's status directly rather than relying on the
    // broadcast-stream listener having already fired by this point —
    // stream delivery is a separate microtask from this await resuming,
    // so it isn't guaranteed to have run yet.
    _status = _syncService.currentStatus;
    notifyListeners();
  }

  void startRealtime() => _syncService.startRealtime();

  void stopRealtime() => _syncService.stopRealtime();
}
