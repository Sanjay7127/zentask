# Contributing to ZenTask

Thanks for considering a contribution — this guide covers everything from
first setup to opening a pull request. Please also read our
**[Code of Conduct](CODE_OF_CONDUCT.md)**; it applies to every space this
project touches (issues, PRs, discussions).

## Table of contents

- [Before you start](#before-you-start)
- [Project setup](#project-setup)
- [Coding standards](#coding-standards)
- [Branch naming](#branch-naming)
- [Commit naming](#commit-naming)
- [Testing](#testing)
- [Pull requests](#pull-requests)

## Before you start

Read **[ARCHITECTURE.md](ARCHITECTURE.md)** first — it explains the
layering (screens → providers → services/repositories → Hive) and why a
few things aren't the "usual" Flutter default (no external state
management package, plain `ChangeNotifier` throughout). Changes that fit
that shape are much easier to review than ones that introduce a new
pattern for a single feature.

For anything beyond a small fix, consider opening an issue first to
discuss the approach before writing code — it saves everyone rework.

## Project setup

```bash
git clone https://github.com/Sanjay7127/zentask.git
cd zentask

flutter pub get
flutter run
```

No configuration is required to get the app running — see
**[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** for environment configuration
(optional Supabase/Anthropic credentials), build flavors, and testing
gotchas.

## Coding standards

- **Additive-only model changes.** Adding a field to an existing model
  (`Task`, `Project`, ...)? Give it a default value, and thread it through
  `toMap`/`fromMap`/`copyWith` *and* every other method on that model that
  constructs a new instance directly instead of via `copyWith` (check for
  these — `Task.unassignFromProject`, `withoutDueDate`, `withoutReminder`
  are the recurring example; see
  **[ARCHITECTURE.md § Hive](ARCHITECTURE.md#hive-local-storage)**).
  Never remove or repurpose an existing field — existing installs' Hive
  data still has it.
- **Constructor injection, defaulting to the real thing.** Every
  repository/service/controller takes its dependencies as optional
  constructor parameters (`XRepository({Box? box}) : _box = box ??
  HiveService.xBox`), so tests can inject a fake/temp-dir-backed instance
  without touching production code or reaching for a mocking framework.
- **Graceful degradation for anything that needs external configuration.**
  If a feature depends on credentials or hardware that might not be
  present, follow the interface + honest-default + real-implementation
  shape described in **[ARCHITECTURE.md § Graceful degradation](ARCHITECTURE.md#graceful-degradation-for-cloud-backed-and-native-features)**
  — don't crash, and don't silently no-op where a clear error would serve
  the user better (auth), but don't demand configuration for
  logging/telemetry where local-only is a legitimate default.
- **No new state management dependency.** Business logic lives in a
  `ChangeNotifier` (constructed per-screen, or a lazily-created singleton
  if genuinely shared across unrelated screens). Don't introduce
  Provider/Riverpod/Bloc/etc. for one feature.
- **Feature-first placement.** New UI goes under
  `lib/features/<feature>/screens|widgets/`; new business logic under
  `lib/providers/` or `lib/services/<concern>/`; new storage under
  `lib/repositories/`. Don't add a new top-level `lib/` folder for a
  single feature.
- **Comments explain *why*, not *what*.** Only comment where the reason
  for a choice isn't obvious from the code itself (a workaround, a
  non-obvious invariant, a documented trade-off) — see the existing
  codebase for the level of detail expected.
- **Run the linter before pushing**: `flutter analyze` should report zero
  issues for any file you touched (`flutter_lints` is enabled — see
  `analysis_options.yaml`).

## Branch naming

Use a `type/short-description` shape, matching the commit types below:

```
feat/habit-reminders
fix/pomodoro-tick-offset
docs/update-migration-guide
refactor/task-repository-cleanup
test/goal-repository-coverage
chore/bump-hive-version
```

## Commit naming

This project follows **[Conventional Commits](https://www.conventionalcommits.org/)**:

```
<type>(<optional scope>): <short summary>

[optional body — explain WHY, not just what]
```

| Type | Use for |
| --- | --- |
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only |
| `style` | Formatting, whitespace — no code meaning change |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or correcting tests |
| `chore` | Tooling, dependency bumps, CI config |

Examples:

```
feat(habits): add weekly habit frequency support
fix(pomodoro): correct off-by-one tick before phase completion
docs(readme): add platform support table
```

## Testing

- New repositories/services/controllers: real Hive in a temp directory
  (see **[DEVELOPER_GUIDE.md § Testing](DEVELOPER_GUIDE.md#testing)**'s
  "Hive-in-tempdir pattern"), not a mocking framework.
- New screens: at minimum, a smoke test that renders without throwing; add
  interaction tests for anything with real logic (validation, conditional
  UI). Inject fakes via the screen's controller constructor, not by
  monkey-patching.
- Run `flutter analyze` and the tests for whatever you touched before
  opening a PR:

  ```bash
  flutter analyze
  flutter test test/path/to/your_test.dart
  ```

  Running the *entire* `flutter test` suite locally can be slow on
  constrained machines — see `DEVELOPER_GUIDE.md`'s testing gotchas
  (there are two dependency-related quirks worth knowing about before you
  assume a red test means broken code).

## Pull requests

1. Fork the repo and create your branch from `main` using the naming
   convention above.
2. Make your change. Keep it scoped — one logical change per PR. A bug fix
   doesn't need drive-by refactoring of surrounding code.
3. Keep every commit compilable — don't split a change across commits such
   that an intermediate one doesn't build.
4. Add/update tests, then confirm `flutter analyze` and the relevant tests
   pass.
5. Open the PR with a description that explains **why**, not just what —
   the diff already shows what changed. If a change has a manual-testing
   component the automated suite doesn't cover (a native permission
   prompt, a platform-specific UI), say so explicitly rather than silently
   skipping it.
6. Link any related issue (`Closes #123`).

A maintainer will review, request changes if needed, and merge once CI is
green and the discussion settles. Thanks again for contributing!
