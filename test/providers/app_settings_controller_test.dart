import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zentask/providers/app_settings_controller.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/theme/accent_color.dart';

void main() {
  late Directory tempDir;
  late Box box;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('zentask_app_settings_test');
    Hive.init(tempDir.path);
    // Opened under HiveService's real box name (not an arbitrary one) so
    // that AppSettingsController.instance — which resolves through
    // HiveService.settingsBox — can find it in the singleton test below.
    box = await Hive.openBox(HiveService.settingsBoxName);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('defaults to system theme mode and teal accent when nothing is stored',
      () {
    final controller = AppSettingsController(settingsBox: box);

    expect(controller.themeMode, ThemeMode.system);
    expect(controller.accentColor, AccentColor.teal);
  });

  test('reads a previously persisted theme mode and accent color', () async {
    await box.put('app_theme_mode', 'dark');
    await box.put('app_accent_color', 'blue');

    final controller = AppSettingsController(settingsBox: box);

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.accentColor, AccentColor.blue);
  });

  test('setThemeMode persists and notifies listeners', () async {
    final controller = AppSettingsController(settingsBox: box);
    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setThemeMode(ThemeMode.light);

    expect(controller.themeMode, ThemeMode.light);
    expect(box.get('app_theme_mode'), 'light');
    expect(notified, true);
  });

  test('setAccentColor persists and notifies listeners', () async {
    final controller = AppSettingsController(settingsBox: box);
    var notified = false;
    controller.addListener(() => notified = true);

    await controller.setAccentColor(AccentColor.orange);

    expect(controller.accentColor, AccentColor.orange);
    expect(box.get('app_accent_color'), 'orange');
    expect(notified, true);
  });

  test('instance is a shared singleton until reset for testing', () {
    AppSettingsController.resetInstanceForTesting();
    final first = AppSettingsController.instance;
    final second = AppSettingsController.instance;
    expect(identical(first, second), true);

    AppSettingsController.resetInstanceForTesting();
    final third = AppSettingsController.instance;
    expect(identical(first, third), false);
  });
}
