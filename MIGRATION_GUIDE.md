# Migration Guide

This app has no formal schema-versioning system — Hive stores plain maps,
and every model reads its own `fromMap` defensively (missing keys fall
back to a default). This document covers three related things: how the
**database schema** evolves safely, the **encryption migration** in
detail, and what to expect across **version upgrades**.

## Contents

- [Database migration](#database-migration)
  - [Adding a field to an existing model](#adding-a-field-to-an-existing-model)
  - [Adding a new entity type](#adding-a-new-entity-type-new-hive-box)
  - [Migrations that have actually happened](#migrations-that-have-actually-happened)
- [Encryption migration](#encryption-migration)
- [Version upgrades](#version-upgrades)
- [What's deliberately not attempted](#whats-deliberately-not-attempted)

## Database migration

### Adding a field to an existing model

This is the most common schema change in this codebase, and it has one
recurring failure mode worth checking for every time.

1. Add the field with a safe default (`false`, `const []`, `''`, etc.) —
   never make it `required` on the existing constructor, or every
   already-serialized record without that key would fail to deserialize.
2. Thread it through `toMap()` and `fromMap()`.
3. Thread it through `copyWith()`.
4. **Check for — and update — every other method on that model that
   constructs a new instance directly instead of going through
   `copyWith()`.** This is the actual bug class, not a hypothetical one:
   `Task.unassignFromProject()`, `withoutDueDate()`, and
   `withoutReminder()` all build a new `Task(...)` directly (because they
   need to force a field to `null`, which `copyWith`'s
   null-means-"leave unchanged" convention can't express) — so adding
   `Task.isPinned`/`Task.labelIds` initially left those three methods
   silently resetting both new fields back to their defaults on every
   call, until each was explicitly given `isPinned: isPinned, labelIds:
   labelIds,`. Grep the model's file for its own class name followed by
   `(` to find every direct-construction site before considering a new
   field "done."
5. Write/update a round-trip test (`toMap`/`fromMap` with every field set
   to a non-default value) — this is what would have caught the bug
   above mechanically, if the test had asserted on the new fields too.

### Adding a new entity type (new Hive box)

1. Add the box name constant + `Hive.openBox(...)` call + `Box get`
   getter to `HiveService` (see `labelsBoxName`/`labelsBox` for a recent
   example) — and add the name to `HiveService.allBoxNames`, which both
   `HiveEncryptionService` and `DataPrivacyService` iterate over.
   Forgetting this means the new box silently isn't encrypted when a
   user turns encryption on, and silently isn't cleared by "delete all
   my data."
2. Write the model (`create`/`toMap`/`fromMap`) and repository
   (`{Box? box} : _box = box ?? HiveService.xBox`) following the
   additive-only conventions above from day one.

### Migrations that have actually happened

#### Legacy task box → rich task records

The original task storage (`mybox`, `title`+`isDone` only) was never
migrated in place — a second box (`task_records`) was introduced for the
new rich `Task` shape, and `TaskRepository.migrateLegacyTasksIfNeeded()`
copies legacy entries into it lazily on first launch after upgrading
(called once, in `main()`, best-effort — a failed migration attempt just
retries on the next launch, since the legacy box is left untouched
either way). Reference this if you ever need to migrate an *entire box's
shape* rather than adding one field: two boxes + a lazy one-time copy is
lower-risk than an in-place rewrite of every existing record.

## Encryption migration

`HiveEncryptionService.enableEncryption()` converts an existing,
unencrypted install to AES-256-encrypted-at-rest. This is the template to
copy for any future "rewrite every box's on-disk format" change:

1. Read every box's entire contents into memory first (`Map<dynamic,
   dynamic>` per box) — before touching anything on disk.
2. Close every box, then delete every box's on-disk file.
3. Generate the new key/config, then reopen every box under the new
   format (encrypted, in this case).
4. Write the in-memory snapshots back.
5. **Require an app restart immediately after** — every repository and
   controller already holding a `Box` reference from before step 2 is
   now pointing at a closed box, and this class deliberately does not
   attempt to hot-swap those live references. Don't skip this
   requirement to make a migration feel more seamless; the alternative
   is a much larger, riskier change (every repository would need a way
   to be told "your box reference is now stale, re-fetch it").

A **fresh install** that enables encryption before its first launch needs
none of the above — `HiveService.init()` simply checks `SecureKeyService`
for an existing key and opens boxes with `HiveAesCipher(key)` from the
start if one's present. The multi-step migration above only exists for
converting data that's already on disk unencrypted.

## Version upgrades

This project follows [Semantic Versioning](https://semver.org/) once
tagged releases begin (see [CHANGELOG.md](CHANGELOG.md)).

- **Patch (`x.y.Z`)**: bug fixes only. No data migration is ever required
  — safe to update without reading anything further.
- **Minor (`x.Y.0`)**: new features, additive-only model/schema changes
  (see above). Existing local data continues to work unchanged; new
  fields simply default to their safe value for records created before
  the upgrade. No manual action required.
- **Major (`X.0.0`)**: reserved for breaking changes, should any ever be
  needed (none have been to date — every schema change so far has been
  additive). If a future major version requires one, it will be
  documented here with an explicit before/after data-shape comparison and
  an automated migration path, not a manual one.

**Encryption and app-lock settings are per-install, not per-version** —
upgrading the app never changes whether encryption or biometric lock is
enabled; those are user choices stored in the `settings` Hive box and the
platform keychain/keystore respectively.

## What's deliberately *not* attempted

There is no automatic Hive-to-SQL (or Hive-to-any-other-store) migration
path, and no plan to add one — see [ARCHITECTURE.md](ARCHITECTURE.md) for
why Hive was chosen and is expected to remain this app's storage layer.
