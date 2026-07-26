import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:zentask/config/cloud_config.dart';
import 'package:zentask/core/app.dart';
import 'package:zentask/repositories/task_repository.dart';
import 'package:zentask/services/crash/crash_reporter.dart';
import 'package:zentask/services/hive_service.dart';
import 'package:zentask/services/telemetry/product_analytics_service.dart';

/// The app's [CrashReporter] instance. `const LocalCrashReporter()`
/// today — logs locally only, since no crash-reporting backend has
/// credentials configured yet (see `CloudConfig`). Swapping in a real
/// backend later only ever means changing this one line.
const CrashReporter crashReporter = LocalCrashReporter();

/// The app's [ProductAnalyticsService] instance — same local-only,
/// swap-later story as [crashReporter].
const ProductAnalyticsService productAnalytics = LocalProductAnalyticsService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Routes every uncaught error — both Flutter framework errors and
  // errors from outside it (async gaps, platform channels) — through
  // the app's single crash-reporting seam rather than only the default
  // console dump.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashReporter.recordError(details.exception, details.stack ?? StackTrace.empty, fatal: true);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    crashReporter.recordError(error, stack, fatal: true);
    return true;
  };

  await HiveService.init();

  // Best-effort, non-fatal: the legacy task box is untouched either way,
  // and today's UI only reads that legacy box. A failed migration can
  // simply retry on the next launch.
  try {
    await TaskRepository().migrateLegacyTasksIfNeeded();
  } catch (_) {}

  // Only initialize Supabase when real credentials were supplied via
  // --dart-define-from-file (see lib/config/cloud_config.dart) — every
  // cloud-backed service already falls back to an Unavailable
  // implementation otherwise, so skipping this call is always safe.
  if (CloudConfig.hasSupabaseCredentials) {
    await supabase.Supabase.initialize(
      url: CloudConfig.supabaseUrl,
      publishableKey: CloudConfig.supabaseAnonKey,
    );
  }

  productAnalytics.logEvent('app_opened');

  runApp(const MainApp());
}
