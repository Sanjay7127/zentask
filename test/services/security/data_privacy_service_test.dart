import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/services/security/data_privacy_service.dart';

void main() {
  late Directory tempDir;
  const service = DataPrivacyService();

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_data_privacy_test');
    Hive.init(tempDir.path);
    for (final name in HiveService.allBoxNames) {
      await Hive.openBox(name);
    }
  });

  tearDown(() async {
    for (final name in HiveService.allBoxNames) {
      final box = Hive.box(name);
      if (box.isOpen) await box.close();
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('deleteAllData clears every box named in HiveService.allBoxNames', () async {
    await Hive.box(HiveService.settingsBoxName).put('theme', 'dark');
    await Hive.box(HiveService.projectsBoxName).put('p1', {'title': 'Launch'});
    await Hive.box(HiveService.habitsBoxName).put('h1', {'title': 'Read'});

    await service.deleteAllData();

    for (final name in HiveService.allBoxNames) {
      expect(Hive.box(name).isEmpty, isTrue, reason: '$name should be empty');
    }
  });

  test('deleteAllData leaves every box open and usable afterward', () async {
    await service.deleteAllData();

    for (final name in HiveService.allBoxNames) {
      final box = Hive.box(name);
      expect(box.isOpen, isTrue);
      await box.put('smoke', 'ok');
      expect(box.get('smoke'), 'ok');
    }
  });
}
