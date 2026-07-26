import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Generates and stores the 256-bit key [HiveEncryptionService] uses to
/// encrypt Hive boxes, via the platform keychain/keystore
/// (`flutter_secure_storage`) rather than Hive's own (plaintext-on-disk)
/// settings box — the key protecting encrypted data can't itself sit
/// next to that data in the clear.
class SecureKeyService {
  final FlutterSecureStorage _storage;
  static const String _encryptionKeyStorageKey = 'hive_encryption_key';

  SecureKeyService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// The stored key, or `null` if encryption has never been enabled.
  Future<List<int>?> getKey() async {
    final encoded = await _storage.read(key: _encryptionKeyStorageKey);
    if (encoded == null) return null;
    return base64Decode(encoded);
  }

  /// Creates and stores a new random 256-bit key, overwriting any
  /// existing one. Callers that already have encrypted data under the
  /// old key must re-encrypt it before calling this — see
  /// `HiveEncryptionService.enableEncryption`.
  Future<List<int>> generateAndStoreKey() async {
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    await _storage.write(key: _encryptionKeyStorageKey, value: base64Encode(key));
    return key;
  }

  Future<void> deleteKey() => _storage.delete(key: _encryptionKeyStorageKey);
}
