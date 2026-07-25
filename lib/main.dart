import 'package:flutter/material.dart';
import 'package:zentask/core/app.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/hive_service.dart';

void main() async {
  await HiveService.init();

  // Best-effort, non-fatal: the legacy task box is untouched either way,
  // and today's UI only reads that legacy box. A failed migration can
  // simply retry on the next launch.
  try {
    await TaskRepository().migrateLegacyTasksIfNeeded();
  } catch (_) {}

  runApp(const MainApp());
}
