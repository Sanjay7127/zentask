import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/services/security/hive_encryption_service.dart';
import 'package:zentask/services/security/secure_key_service.dart';

import '../../test_utils/fake_secure_storage_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SecureKeyService secureKeyService;
  late HiveEncryptionService encryptionService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_hive_encryption_test');
    Hive.init(tempDir.path);
    for (final name in HiveService.allBoxNames) {
      await Hive.openBox(name);
    }

    installFakeSecureStorageChannel(
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
    );
    secureKeyService = SecureKeyService();
    encryptionService = HiveEncryptionService(secureKeyService: secureKeyService);
  });

  tearDown(() async {
    for (final name in HiveService.allBoxNames) {
      final box = Hive.box(name);
      if (box.isOpen) await box.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('isEnabled is false before any key has been generated', () async {
    expect(await encryptionService.isEnabled(), isFalse);
  });

  test('enableEncryption generates a key and reports enabled afterward', () async {
    await encryptionService.enableEncryption();

    expect(await encryptionService.isEnabled(), isTrue);
    expect(await secureKeyService.getKey(), hasLength(32));
  });

  test('enableEncryption preserves existing data across the migration', () async {
    await Hive.box(HiveService.settingsBoxName).put('theme', 'dark');
    await Hive.box(HiveService.projectsBoxName).put('p1', {'title': 'Launch'});

    await encryptionService.enableEncryption();

    expect(Hive.box(HiveService.settingsBoxName).get('theme'), 'dark');
    expect(Hive.box(HiveService.projectsBoxName).get('p1'), {'title': 'Launch'});
  });

  test('every box is reopened and usable after the migration', () async {
    await encryptionService.enableEncryption();

    for (final name in HiveService.allBoxNames) {
      final box = Hive.box(name);
      expect(box.isOpen, isTrue);
      await box.put('smoke', 'ok');
      expect(box.get('smoke'), 'ok');
    }
  });

  test('calling enableEncryption twice throws', () async {
    await encryptionService.enableEncryption();

    expect(() => encryptionService.enableEncryption(), throwsStateError);
  });
}
