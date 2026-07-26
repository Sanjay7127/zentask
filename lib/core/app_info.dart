/// Static app metadata shown on the Settings > About section.
///
/// [version] is a plain constant (not read via `package_info_plus`) to
/// avoid adding a new platform-channel plugin — and the risk of the same
/// plugin-registration-in-tests gap already hit once this session with
/// `flutter_local_notifications` — for a single version string. Keep it
/// in sync with `pubspec.yaml`'s `version:` field by hand.
///
/// [githubUrl]/[reportIssueUrl] are intentionally empty: this app has no
/// real public repository URL yet, and fabricating one would point users
/// at a link that doesn't exist. The Settings screen shows a clear
/// "not configured yet" message when these are empty rather than
/// pretending the row does something it doesn't. Fill these in with the
/// real repository URL once one exists.
class AppInfo {
  AppInfo._();

  static const String appName = 'ZenTask';
  static const String version = '0.1.0';
  static const String githubUrl = '';
  static const String reportIssueUrl = '';
}
