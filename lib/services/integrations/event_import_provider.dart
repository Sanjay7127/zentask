import 'package:zentask/models/event.dart';

/// Contract for pulling events from an external source (Devpost, Luma,
/// Eventbrite, etc.) into ZenTask's [Event] model.
///
/// No implementation exists yet — this phase is architecture-only, per
/// "no external API connections." A future phase adds one
/// [EventImportProvider] per real source; nothing that registers or
/// consumes providers needs to change when that happens.
abstract class EventImportProvider {
  String get providerName;

  Future<List<Event>> fetchEvents();
}

/// A registry of [EventImportProvider]s — "plugin-ready" in the sense
/// that adding a new event source is: implement the interface, call
/// [register]. No other code changes.
class EventImportRegistry {
  final List<EventImportProvider> _providers = [];

  void register(EventImportProvider provider) {
    _providers.add(provider);
  }

  List<EventImportProvider> get providers => List.unmodifiable(_providers);

  /// Fetches from every registered provider. A single provider's
  /// failure doesn't prevent the others from returning results.
  Future<List<Event>> fetchAll() async {
    final results = <Event>[];
    for (final provider in _providers) {
      try {
        results.addAll(await provider.fetchEvents());
      } catch (_) {
        // Best-effort aggregation: one misbehaving provider shouldn't
        // block events from the rest. Revisit with real error
        // reporting once a provider actually exists to observe failing.
      }
    }
    return results;
  }
}
