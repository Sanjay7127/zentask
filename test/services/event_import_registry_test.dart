import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/models/event.dart';
import 'package:zentask/services/integrations/event_import_provider.dart';

class _FakeProvider implements EventImportProvider {
  final String _name;
  final List<Event> _events;
  final bool shouldThrow;

  _FakeProvider(this._name, this._events, {this.shouldThrow = false});

  @override
  String get providerName => _name;

  @override
  Future<List<Event>> fetchEvents() async {
    if (shouldThrow) throw Exception('provider failed');
    return _events;
  }
}

void main() {
  test('registry starts empty', () {
    final registry = EventImportRegistry();
    expect(registry.providers, isEmpty);
  });

  test('register adds a provider, providers list reflects it', () {
    final registry = EventImportRegistry();
    final provider = _FakeProvider('Devpost', []);

    registry.register(provider);

    expect(registry.providers, hasLength(1));
    expect(registry.providers.first.providerName, 'Devpost');
  });

  test('fetchAll aggregates events from every registered provider',
      () async {
    final registry = EventImportRegistry();
    registry.register(_FakeProvider('Devpost', [Event.create(title: 'Hack A')]));
    registry.register(_FakeProvider('Luma', [Event.create(title: 'Hack B')]));

    final events = await registry.fetchAll();

    expect(events.map((e) => e.title).toSet(), {'Hack A', 'Hack B'});
  });

  test('fetchAll tolerates a provider that throws, still returns the rest',
      () async {
    final registry = EventImportRegistry();
    registry.register(_FakeProvider('Broken', [], shouldThrow: true));
    registry.register(_FakeProvider('Working', [Event.create(title: 'OK')]));

    final events = await registry.fetchAll();

    expect(events, hasLength(1));
    expect(events.single.title, 'OK');
  });
}
