# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note:** `pubspec.yaml` currently pins `version: 0.1.0` — the `[1.0.0]`
> entry below documents the feature set as of the "Enterprise & Release"
> milestone (internally "Phase 12"). Bumping the actual `pubspec.yaml`
> version is a maintainer decision made at tag time, not implied by this
> file alone.

## [Unreleased]

Nothing yet.

## [1.0.0] — Enterprise & Release

Initial feature-complete release. Development proceeded in phases, each
adding a coherent slice of functionality; phases 1–6 predate per-commit
history (squashed into a single `feat: implement Phase 6 architecture and
core services` commit) and are summarized under Foundation below.

### Added

**Foundation**
- Rich tasks: priority, due dates, description, subtasks, tags.
- Projects, with tasks assignable to and unassignable from them.
- A reminders/notifications framework (`flutter_local_notifications`),
  surviving device reboots.
- The feature-first project structure this codebase still follows.

**Productivity core**
- AI Planner: turns a plain-language goal into a structured task plan
  (Anthropic-backed; gracefully unavailable with zero configuration).
  Later expanded with daily planning, task time estimation, workload
  balancing, and project summaries.
- Appearance settings: Light/Dark/System theme mode + selectable accent
  color.
- Data portability: full JSON export/import, plus `.ics` calendar
  export/import.
- Analytics: productivity snapshots, current/longest completion streaks,
  per-project completion rates.
- Calendar: a unified view of task due dates, reminders, and events.

**Cloud**
- Optional Supabase-backed accounts (email + anonymous sign-in) and
  cross-device sync, inferring local deletions without hooking every
  repository's `delete()` method.

**Enterprise features**
- Pinned Tasks, Custom Labels, Saved Filters, Advanced Search
  (cross-entity, debounced), and Recurring Task templates.
- Focus Mode: a Pomodoro-style timer with session history and Focus
  Statistics.
- Habits with streak tracking, Goals with progress bars, and
  Achievements evaluated live against real usage data.

**Security & privacy**
- Optional biometric/passcode app lock, auto re-locking after the app
  has been backgrounded past a threshold.
- Opt-in AES-256 encryption of all local Hive data, with a safe
  migration path for existing unencrypted installs.
- "Sign out everywhere" (ends every device's session) and "delete all
  my data" (irreversible local wipe).

**Developer & release infrastructure**
- GitHub Actions CI: static analysis, the full test suite, and unsigned
  Android/iOS build verification.
- Fastlane lane skeletons for both platforms.
- Android `dev`/`prod` build flavors and an `ENVIRONMENT` dart-define.
- A local-only logging service, plus interface-based crash-reporting
  and product-analytics abstractions (no telemetry leaves the device
  by default).
- Generated app icons and native splash screens; an iOS Privacy
  Manifest; Play Store / App Store listing copy.
- Full documentation set: `ARCHITECTURE.md`, `DEVELOPER_GUIDE.md`,
  `CONTRIBUTING.md`, `SECURITY.md`.

### Known limitations

- Google/Apple sign-in surface a clear "not configured" error — no OAuth
  client credentials are wired in.
- Home-screen widgets and OS quick-actions (app shortcuts) are not
  implemented — native platform-channel work outside this project's
  current scope.
- iOS build flavors and the iOS Privacy Manifest's Xcode-project wiring
  are documented but not completed — Xcode project files aren't safe to
  hand-edit without Xcode itself to validate the result.

[Unreleased]: https://github.com/Sanjay7127/zentask/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Sanjay7127/zentask/releases/tag/v1.0.0
