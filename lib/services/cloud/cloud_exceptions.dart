/// Thrown by any cloud-backed service (auth, sync, calendar sync) when
/// the feature it's being asked for isn't configured or set up yet —
/// missing credentials, an unconfigured OAuth provider, no network,
/// etc. UI code catches this and shows [message] directly rather than a
/// generic error, matching how `AppInfo.githubUrl.isEmpty` is handled
/// (Phase 10): honest about what isn't wired up instead of pretending.
class CloudUnavailableException implements Exception {
  final String message;
  const CloudUnavailableException(this.message);

  @override
  String toString() => message;
}
