# Store Readiness Checklist

Status as of Phase 12. Everything here was verifiable without a real
Android SDK or Xcode install (this repo was developed in a sandbox
missing both) — anything that genuinely needs one is marked
"needs a real device/emulator" below, not silently skipped.

## Done

- [x] **App icon** generated for Android + iOS (`dart run
      flutter_launcher_icons`), with `remove_alpha_ios: true` set so
      the iOS icon passes Apple's no-alpha-channel requirement.
- [x] **Native splash screen** generated for Android + iOS + web
      (`dart run flutter_native_splash:create`), using the app's teal
      brand color (`AppTheme.seedColor`, `#01D1AF`) with a dark-mode
      variant.
- [x] **Web app manifest** (`web/manifest.json`) brand color fixed
      (was still Flutter's default blue, `#0175C2` — a pre-existing
      leftover from before the app was rebranded to ZenTask).
- [x] **Android app label** now resolves per build flavor
      (`@string/app_name` + flavor `resValue`, see
      `android/app/build.gradle`) instead of a hardcoded "To Do"
      string (another pre-rebrand leftover, fixed as part of adding
      flavors — see `DEVELOPER_GUIDE.md`).
- [x] **Play Store listing text**:
      `android/fastlane/metadata/android/en-US/{title,short_description,
      full_description}.txt` + an initial changelog entry.
- [x] **App Store listing text**:
      `ios/fastlane/metadata/en-US/{name,subtitle,description,keywords,
      promotional_text,release_notes}.txt` — all checked against
      Apple's character limits (name ≤30, subtitle ≤30, keywords ≤100).
- [x] **iOS Privacy Manifest** created at
      `ios/Runner/PrivacyInfo.xcprivacy`, declaring no tracking, no
      data collection, and the required-reason API categories this
      app's dependencies are known to touch (file timestamps, user
      defaults, disk space).

## Needs action before submission (can't be done from this sandbox)

- [ ] **Real branded icon artwork.** The generated icons above are
      real, correctly-sized files — but the *source image*
      (`assests/ToDo.png`) is still the app's pre-rebrand icon design,
      not new ZenTask-branded artwork. Replace that source file with a
      real 1024×1024 design and re-run both generators.
- [ ] **Attach `PrivacyInfo.xcprivacy` to the Xcode project.** It
      exists on disk but Xcode's project file wasn't hand-edited to
      reference it (too risky to do blindly without Xcode to verify) —
      open the project in Xcode and drag it into the `Runner` target.
      See `DEVELOPER_GUIDE.md`.
- [ ] **Screenshots** (needs a real device/simulator — a genuinely
      hardware/OS-dependent step, not something any codebase change
      can produce): capture at minimum —
      1. Tasks list (with a few realistic tasks — priorities, due
         dates, labels visible)
      2. A project's detail view (progress bar, task list)
      3. Focus Mode timer mid-session
      4. Analytics screen
      5. Calendar view
      Play Store needs 2–8 phone screenshots (min 320px, max 3840px on
      the long edge); App Store needs sets sized for each supported
      device class (6.9", 6.5", 5.5" iPhone at minimum — see Apple's
      current requirements, which change periodically).
- [ ] **Feature graphic** (Play Store only, 1024×500 PNG/JPG,
      no alpha) — promotional banner shown in Play Store search/browse.
- [ ] **Play Console hi-res icon** (512×512, separate upload from the
      in-app adaptive icon).
- [ ] **Privacy policy URL** — required by both stores once any data
      collection is declared, and good practice regardless. Should
      describe: local-only storage by default, what's sent if cloud
      sync is enabled (which cloud backend, what data), and that no
      analytics/crash data leaves the device (see
      `lib/services/telemetry/product_analytics_service.dart` and
      `lib/services/crash/crash_reporter.dart` — both local-only
      today).
- [ ] **App Store "App Privacy" questionnaire** — should mirror
      `PrivacyInfo.xcprivacy`: no data collected, no tracking.
- [ ] **Content/age rating questionnaire** (both stores) — nothing in
      this app suggests anything other than the lowest rating tier,
      but each store requires answering its own questionnaire directly.
- [ ] **Application id / bundle identifier / release signing** — see
      `DEVELOPER_GUIDE.md`'s "Before your first store submission"
      section; these are still Flutter's defaults / debug-signed.
