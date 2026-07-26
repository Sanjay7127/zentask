import 'package:flutter_test/flutter_test.dart';
import 'package:zentask/services/security/secure_key_service.dart';

import '../../test_utils/fake_secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureKeyService service;

  setUp(() {
    installFakeSecureStorageChannel(
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
    );
    service = SecureKeyService();
  });

  test('getKey is null when no key has ever been generated', () async {
    expect(await service.getKey(), isNull);
  });

  test('generateAndStoreKey returns and persists a 32-byte key', () async {
    final key = await service.generateAndStoreKey();

    expect(key, hasLength(32));
    expect(await service.getKey(), key);
  });

  test('generateAndStoreKey overwrites a previously-stored key', () async {
    final first = await service.generateAndStoreKey();
    final second = await service.generateAndStoreKey();

    expect(second, isNot(equals(first)));
    expect(await service.getKey(), second);
  });

  test('deleteKey removes the stored key', () async {
    await service.generateAndStoreKey();

    await service.deleteKey();

    expect(await service.getKey(), isNull);
  });
}
