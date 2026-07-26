import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/providers/app_lock_controller.dart';
import 'package:zentask/services/security/biometric_auth_service.dart';

class _FakeBiometricAuthService implements BiometricAuthService {
  bool available = true;
  bool authenticateResult = true;
  int authenticateCallCount = 0;
  String? lastReason;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    authenticateCallCount++;
    lastReason = reason;
    return authenticateResult;
  }
}

void main() {
  late Directory tempDir;
  late Box box;
  late _FakeBiometricAuthService biometrics;
  late AppLockController controller;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_app_lock_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('settings_test');
    biometrics = _FakeBiometricAuthService();
    controller = AppLockController(settingsBox: box, biometricAuthService: biometrics);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('defaults to disabled with no stored preference', () {
    expect(controller.enabled, isFalse);
  });

  test('setEnabled(true) persists and notifies', () async {
    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setEnabled(true);

    expect(controller.enabled, isTrue);
    expect(notified, isTrue);
    expect(box.get('app_lock_enabled'), isTrue);
  });

  test('a fresh controller reads the persisted preference back', () async {
    await controller.setEnabled(true);

    final reloaded = AppLockController(settingsBox: box, biometricAuthService: biometrics);

    expect(reloaded.enabled, isTrue);
  });

  test('isBiometricAvailable delegates to the injected service', () async {
    biometrics.available = false;
    expect(await controller.isBiometricAvailable(), isFalse);

    biometrics.available = true;
    expect(await controller.isBiometricAvailable(), isTrue);
  });

  test('authenticate delegates to the injected service with the given reason', () async {
    biometrics.authenticateResult = true;

    final result = await controller.authenticate(reason: 'Unlock test');

    expect(result, isTrue);
    expect(biometrics.authenticateCallCount, 1);
    expect(biometrics.lastReason, 'Unlock test');
  });

  test('authenticate surfaces a failed authentication', () async {
    biometrics.authenticateResult = false;

    expect(await controller.authenticate(), isFalse);
  });
}
