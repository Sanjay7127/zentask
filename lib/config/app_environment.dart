/// Which build flavor this binary was compiled as (Phase 12) — set via
/// `--dart-define=ENVIRONMENT=dev|staging|prod` (see
/// `config/cloud_config.example.json` for the dev default, and
/// `DEVELOPER_GUIDE.md` for the full flavor setup). Defaults to [dev]
/// so a plain `flutter run` with no dart-defines still behaves
/// sensibly, matching every other `CloudConfig` getter's
/// safe-when-unconfigured default.
enum AppEnvironment { dev, staging, prod }

class AppEnvironmentConfig {
  AppEnvironmentConfig._();

  static const String _raw = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  static final AppEnvironment current = AppEnvironment.values.firstWhere(
    (e) => e.name == _raw,
    orElse: () => AppEnvironment.dev,
  );

  static bool get isProd => current == AppEnvironment.prod;
}
