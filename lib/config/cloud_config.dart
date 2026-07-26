/// Compile-time cloud credentials (Phase 11) — read via
/// `String.fromEnvironment`, populated from `config/cloud_config.json`
/// (gitignored; `config/cloud_config.example.json` is the checked-in
/// template) at build/run time via:
///
/// ```
/// flutter run --dart-define-from-file=config/cloud_config.json
/// flutter test --dart-define-from-file=config/cloud_config.json
/// ```
///
/// Deliberately **not** `flutter_dotenv` or any asset-bundled `.env` —
/// that would ship the raw secret file inside the compiled app as a
/// readable asset. `--dart-define` compiles values in as constants
/// instead, and this file never contains the actual secrets itself.
///
/// Every real cloud implementation in this app checks the relevant
/// `has*Credentials` getter and falls back to a local-only/Unavailable
/// implementation when it's `false` — the same graceful-degradation
/// pattern as `AppInfo.githubUrl` (Phase 10) and `UnavailableAIPlanner`
/// (Phase 9), so running without `--dart-define-from-file` is always
/// safe and never crashes.
class CloudConfig {
  CloudConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String anthropicApiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY');

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasAnthropicApiKey => anthropicApiKey.isNotEmpty;
}
