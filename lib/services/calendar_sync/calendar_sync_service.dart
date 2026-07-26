/// External calendar sync (Phase 11): Google Calendar, Apple Calendar,
/// and plain ICS files. Each has its own implementation rather than one
/// shared interface trying to abstract over fundamentally different
/// transports (OAuth + REST APIs for Google/Apple vs. a local file for
/// ICS) — there's no shared "sync now" verb that means the same thing
/// across all three the way [SyncService] does for Supabase's tables.
abstract class CalendarSyncService {
  /// Human-readable name shown in Settings (e.g. "Google Calendar").
  String get displayName;

  bool get isAvailable;

  Future<String> exportAll();

  Future<int> importFrom(String data);
}
