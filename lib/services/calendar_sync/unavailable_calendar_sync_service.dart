import 'package:zentask/services/calendar_sync/calendar_sync_service.dart';
import 'package:zentask/services/cloud/cloud_exceptions.dart';

/// Stub for a calendar sync provider that needs its own OAuth client
/// credentials Phase 11 wasn't given — Google Calendar and Apple
/// Calendar both use this today. Exists (rather than omitting the
/// provider entirely) so the Settings UI can list every provider Phase
/// 11 asked for and say honestly which ones aren't wired up yet, instead
/// of silently only offering ICS.
class UnavailableCalendarSyncService implements CalendarSyncService {
  @override
  final String displayName;

  const UnavailableCalendarSyncService(this.displayName);

  @override
  bool get isAvailable => false;

  @override
  Future<String> exportAll() => throw CloudUnavailableException(
      '$displayName needs OAuth client credentials that haven\'t been configured yet.');

  @override
  Future<int> importFrom(String data) => throw CloudUnavailableException(
      '$displayName needs OAuth client credentials that haven\'t been configured yet.');
}
