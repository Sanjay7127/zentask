import 'package:hive_flutter/hive_flutter.dart';

import 'package:zentask/services/hive_service.dart';

/// Backs Settings → Privacy → "Delete all my data": irreversibly wipes
/// every local box named in [HiveService.allBoxNames]. Deliberately
/// local-only — it does not touch the signed-in cloud account or the
/// Hive encryption key, since those are separate concerns ("delete my
/// data" vs. "sign out" vs. "disable encryption").
class DataPrivacyService {
  const DataPrivacyService();

  Future<void> deleteAllData() async {
    for (final name in HiveService.allBoxNames) {
      await Hive.box(name).clear();
    }
  }
}
