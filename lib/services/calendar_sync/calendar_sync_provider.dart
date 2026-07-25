/// One syncable calendar item, in a shape that's provider-agnostic
/// rather than tied to ZenTask's own [Task]/[Event] models — a
/// [CalendarSyncProvider] implementation translates to/from this shape.
class CalendarSyncItem {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? description;

  const CalendarSyncItem({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.description,
  });
}

/// Abstract contract for syncing ZenTask's schedule with an external
/// calendar provider (e.g. Google Calendar, Outlook).
///
/// No implementation exists yet — this phase is architecture-only, per
/// "no external API connections." A future phase implements this against
/// a real provider's API; every consumer of [CalendarSyncProvider] stays
/// unchanged when that happens.
abstract class CalendarSyncProvider {
  String get providerName;

  Future<bool> get isConnected;

  Future<void> connect();

  Future<void> disconnect();

  Future<void> pushItems(List<CalendarSyncItem> items);

  Future<List<CalendarSyncItem>> pullItems({DateTime? since});
}
