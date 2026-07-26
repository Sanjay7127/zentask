import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Automatically applied by `flutter test` to every test file in this
/// directory tree.
///
/// `AppTheme` uses `google_fonts` (Poppins) — by default, google_fonts
/// tries a real network fetch the first time a given weight/style is
/// needed if it isn't bundled with the app, and normally fails silently
/// back to a fallback font. Once this app started depending on
/// `package:http`/`supabase_flutter` (Phase 11), something about an
/// `HttpClient` existing in the test binary changed that failure from a
/// silent fallback into an uncaught exception that crashed the test —
/// first caught via a widget test that pumped `SettingsScreen` fresh in
/// its own process. `allowRuntimeFetching = false` is google_fonts' own
/// documented fix: it skips the network attempt entirely and always
/// uses the fallback, which is what every widget test actually wants
/// anyway (deterministic rendering, no network dependency).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
