import 'package:hive_flutter/hive_flutter.dart';

import 'package:zentask/services/hive_service.dart';
import 'package:zentask/services/security/secure_key_service.dart';

/// Migrates the app's existing (unencrypted) Hive boxes to AES-256
/// encryption, or reports whether that migration has already run.
///
/// [HiveService.init] already opens boxes encrypted whenever
/// [SecureKeyService] holds a key, so a **fresh install** that enables
/// encryption before its first launch needs nothing else — this class
/// only exists for the harder case of converting an **existing**
/// install that already has unencrypted data on disk.
///
/// The migration reads every entry into memory, deletes the plaintext
/// box files, generates a new key, reopens each box encrypted, and
/// writes the entries back. It deliberately does **not** attempt to
/// hot-swap the live `Box` references that repositories/controllers
/// already hold — those would keep pointing at now-closed boxes — so
/// callers must prompt the user to restart the app immediately after
/// [enableEncryption] completes.
class HiveEncryptionService {
  final SecureKeyService _secureKeyService;

  HiveEncryptionService({SecureKeyService? secureKeyService})
      : _secureKeyService = secureKeyService ?? SecureKeyService();

  /// Whether Hive boxes are currently opened with encryption, i.e.
  /// whether a key has already been generated and stored.
  Future<bool> isEnabled() async => (await _secureKeyService.getKey()) != null;

  /// Converts all boxes named in [HiveService.allBoxNames] from
  /// plaintext to AES-256 encrypted-at-rest.
  ///
  /// Must only be called while every one of those boxes is currently
  /// open (i.e. after normal app startup). Throws if encryption is
  /// already enabled — call [isEnabled] first.
  ///
  /// The app must be restarted after this returns; every repository
  /// and controller holding a `Box` reference obtained before this
  /// call is now pointing at a closed box.
  Future<void> enableEncryption() async {
    if (await isEnabled()) {
      throw StateError('Encryption is already enabled.');
    }

    final snapshots = <String, Map<dynamic, dynamic>>{};
    for (final name in HiveService.allBoxNames) {
      snapshots[name] = Map<dynamic, dynamic>.from(Hive.box(name).toMap());
    }

    for (final name in HiveService.allBoxNames) {
      await Hive.box(name).close();
    }
    for (final name in HiveService.allBoxNames) {
      await Hive.deleteBoxFromDisk(name);
    }

    final key = await _secureKeyService.generateAndStoreKey();
    final cipher = HiveAesCipher(key);

    for (final name in HiveService.allBoxNames) {
      final box = await Hive.openBox(name, encryptionCipher: cipher);
      final entries = snapshots[name];
      if (entries != null && entries.isNotEmpty) {
        await box.putAll(entries);
      }
    }
  }
}
