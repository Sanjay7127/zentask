int _lastMicros = 0;

/// Generates a reasonably-unique local identifier.
///
/// Not a UUID — this is timestamp-based (monotonically increasing within
/// the running isolate), which is sufficient for a single-user,
/// offline-first app with no multi-device sync. Revisit if/when cloud
/// sync is introduced (explicitly out of scope for now).
String generateId() {
  var micros = DateTime.now().microsecondsSinceEpoch;
  if (micros <= _lastMicros) {
    micros = _lastMicros + 1;
  }
  _lastMicros = micros;
  return micros.toString();
}
