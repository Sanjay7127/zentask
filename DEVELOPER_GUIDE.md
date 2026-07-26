# Developer Guide

## Contents

- [Requirements](#requirements)
- [Flutter SDK](#flutter-sdk)
- [Environment configuration](#environment-configuration)
- [Build flavors](#build-flavors)
- [Build](#build)
- [Testing](#testing)
- [Debugging](#debugging)
- [CI/CD](#cicd)
- [Release](#release)

## Requirements

- **Flutter SDK** — stable channel (developed against `3.44.8`).
- **Android builds**: Android SDK + a JDK (CI uses Temurin 17).
- **iOS builds**: Xcode + CocoaPods, on macOS.
- Neither of the above is required to run `flutter analyze`/`flutter
  test`, or to run the app on web (`flutter run -d chrome`) or desktop.

## Flutter SDK

This project's Dart SDK constraint (`pubspec.yaml`'s `environment.sdk`) is:

```yaml
sdk: '>=3.4.1 <4.0.0'
```

Check your installed versions match before filing a build issue:

```bash
flutter --version
dart --version
```

If you manage multiple Flutter SDKs, pin this project to a specific one
with [FVM](https://fvm.app/) or your tool of choice — no repo-specific
config for that exists yet (a reasonable first contribution if you rely
on it).

## Environment configuration

Cloud credentials (Supabase, Anthropic) and the build environment flag are
compiled in via `--dart-define-from-file`, never bundled as a readable
asset:

```bash
cp config/cloud_config.example.json config/cloud_config.json
# fill in the values you have — every field is optional
flutter run --dart-define-from-file=config/cloud_config.json
```

`config/cloud_config.json` is gitignored. Leaving any field blank (or
skipping `--dart-define-from-file` entirely) is always safe — every
cloud-backed service (`AuthService`, sync, the AI planner) detects missing
credentials via `CloudConfig.has*Credentials` and falls back to a
local-only implementation. See `lib/config/cloud_config.dart` for the
exact fields.

## Build flavors

Android has two flavors, defined in `android/app/build.gradle`:

| Flavor | Application ID | Label | Purpose |
| --- | --- | --- | --- |
| `dev` | `com.github.sanjay7127.zentask.dev` | ZenTask Dev | Installs side-by-side with a release build on the same device |
| `prod` | `com.github.sanjay7127.zentask` | ZenTask | The store-submission flavor |

> **This means `flutter run`/`flutter build apk` now require `--flavor
> dev` or `--flavor prod` on Android** — running either command with no
> `--flavor` fails once flavors are defined. This is expected Gradle
> behavior, not a bug; update any local scripts/muscle memory
> accordingly.

Pair the Android flavor with your cloud config:

```bash
flutter run --flavor dev --dart-define-from-file=config/cloud_config.json
flutter build appbundle --flavor prod --dart-define-from-file=config/cloud_config.prod.json
```

**iOS flavors are not yet set up.** Xcode's scheme/configuration files are
a fragile, mostly-binary project format not safe to hand-edit without
Xcode itself to validate the result. To add them: duplicate the `Runner`
scheme twice (Dev/Prod) in Xcode, each pointing at its own build
configuration with a distinct `PRODUCT_BUNDLE_IDENTIFIER` and
`PRODUCT_NAME`, following
[Flutter's official flavors guide](https://docs.flutter.dev/deployment/flavors).

## Build

```bash
# Debug, for local development
flutter run --flavor dev --dart-define-from-file=config/cloud_config.json

# Web
flutter build web

# Android (App Bundle, for Play Store)
flutter build appbundle --release --flavor prod --dart-define-from-file=config/cloud_config.json

# Android (APK, for sideloading/testing)
flutter build apk --release --flavor prod

# iOS (requires macOS + Xcode + CocoaPods)
flutter build ipa --release
```

See [Before your first store submission](#release) below — several
placeholders (application id, signing config) need attention before a
`--release` build is truly store-ready.

## Testing

```bash
flutter test
```

### The Hive-in-tempdir pattern

Every repository/service/controller test follows the same shape — copy it
rather than reinventing storage mocking:

```dart
setUp(() async {
  tempDir = Directory.systemTemp.createTempSync('zentask_x_test');
  Hive.init(tempDir.path);
  box = await Hive.openBox('x_test');
  repository = XRepository(box: box);
});

tearDown(() async {
  await box.deleteFromDisk();
  if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
});
```

Every repository/controller/service in this app accepts its dependencies
via constructor parameters defaulting to the real Hive box
(`XRepository({Box? box}) : _box = box ?? HiveService.xBox`) specifically
so this pattern works without touching production code.

### `flutter_secure_storage` in tests

Anything built on `FlutterSecureStorage` (currently just
`SecureKeyService`) needs its method channel mocked, since there's no real
platform keychain/keystore in a `flutter test` run:

```dart
installFakeSecureStorageChannel(
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
);
```

See `test/test_utils/fake_secure_storage_channel.dart`.

### Two environment-specific gotchas

These are properties of this dependency set, not bugs in the app's own
logic — worth ruling out before spending time debugging a red or hanging
test:

1. **`google_fonts` + `http`-based packages interacting under
   `flutter_test`.** `googleFontsTextStyle` kicks off font loading as a
   fire-and-forget `Future` (no `.catchError`). Once this app depends on
   `http`/`supabase_flutter`, Flutter's test binding detects an
   `HttpClient` in the process and forces every HTTP call — including
   that unrelated font fetch — to return 400. The resulting unhandled
   rejection can surface as a failure attributed to whatever test happens
   to be running at that moment, not necessarily the one that triggered
   the font load. If a widget test fails with a confusing,
   seemingly-unrelated HTTP/font error: suspect this before the feature
   you're actually testing.
2. **`flutter test` can be compile-time- and memory-heavy** on
   constrained machines, especially running the *entire* suite at once.
   Prefer running the specific test file(s) you're working on (`flutter
   test test/path/to/one_test.dart`); only run the whole suite when you
   have the resources for it (e.g. in CI).

## Debugging

- **Logging**: use `AppLogger.debug/info/warning/error` (`lib/services/logging/app_logger.dart`)
  instead of raw `print`/`debugPrint` — messages route through
  `dart:developer`'s `log()`, which shows up in DevTools/your IDE's
  console with a severity level and is never truncated for long
  messages. It's a no-op in release builds.
- **Uncaught errors**: both `FlutterError.onError` and
  `PlatformDispatcher.instance.onError` are wired in `main.dart` to the
  app's `CrashReporter` — check its output (local-only by default, see
  `LocalCrashReporter`) when chasing a crash that doesn't reproduce under
  the debugger.
- **DevTools**: standard Flutter DevTools work as usual
  (`flutter run` prints a DevTools URL) — the widget inspector is
  particularly useful given the `IndexedStack`-based tab navigation in
  `RootShell` (inactive tabs stay mounted, so state bugs are often about
  *which* tab's tree you're inspecting).
- **Hive data**: there's no built-in Hive inspector UI. For local
  debugging, a throwaway script or a temporary `AppLogger.debug` call
  printing `box.toMap()` is usually faster than adding tooling.

## CI/CD

`.github/workflows/ci.yml` runs on every push/PR to `main`:

| Job | Runner | Required? | What it does |
| --- | --- | --- | --- |
| `analyze_and_test` | `ubuntu-latest` | ✅ Required | `flutter analyze` + `flutter test` |
| `build_android` | `ubuntu-latest` | ✅ Required | Unsigned debug APK, `--flavor dev` — catches Android build regressions with no signing config needed |
| `build_ios` | `macos-latest` | ⚠️ Best-effort (`continue-on-error`) | Unsigned debug build, `--no-codesign` — Xcode/CocoaPods toolchain drift on hosted runners is outside this app's control |

## Release

### Fastlane

Skeletons only, in `android/fastlane/` and `ios/fastlane/` — lanes for
building and uploading to Play Store internal testing / TestFlight, plus
real store-listing metadata text (`android/fastlane/metadata/`,
`ios/fastlane/metadata/`). **Not runnable as committed**: both need real
store credentials (a Play Console service-account JSON, an Apple
Developer Program membership + signing identity) that this repo
intentionally doesn't have. Fill in the commented-out `Appfile` values
once you have real credentials — see the comments in each `Fastfile` for
exactly what's missing.

### Before your first store submission

Application id, bundle identifier, and copyright metadata have already
been updated from Flutter's placeholder defaults to
`com.github.sanjay7127.zentask` / Prakash Sanjay across Android, iOS,
macOS, Windows, and Linux. What's still outstanding:

- **Release signing**: `android/app/build.gradle`'s release build type
  currently signs with the debug keystore (`signingConfig =
  signingConfigs.debug`) specifically so `flutter build apk --release`
  works with zero setup. Replace with a real signing config before
  shipping.
- **App icon/splash source image**: generated correctly, but from a
  pre-rebrand placeholder source (`assests/ToDo.png`) — swap in real
  branded artwork and re-run `dart run flutter_launcher_icons` +
  `dart run flutter_native_splash:create`.
- **iOS Privacy Manifest**: `ios/Runner/PrivacyInfo.xcprivacy` exists on
  disk but has **not** been added to `Runner.xcodeproj`'s resources —
  Xcode's project file is a fragile, mostly-binary format not safe to
  hand-edit blindly without Xcode itself available to validate the
  result. Open the project in Xcode and drag the file into the `Runner`
  target before archiving for App Store submission — without this step
  the manifest isn't actually bundled into the app and Apple's automated
  check for it will fail at upload.

### Versioning

Follows [Semantic Versioning](https://semver.org/) — bump
`pubspec.yaml`'s `version: x.y.z+build` and add an entry to
[CHANGELOG.md](CHANGELOG.md) under a new version heading before tagging a
release.
