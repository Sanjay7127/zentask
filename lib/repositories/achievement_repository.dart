import 'package:hive/hive.dart';
import 'package:zentask/services/hive_service.dart';

/// Persists when each achievement (keyed by
/// `AchievementDefinition.id`) was unlocked, so it stays unlocked even
/// if the underlying data that earned it later changes (e.g. a streak
/// resets) — achievements are a one-way ratchet, not a live status.
class AchievementRepository {
  final Box _box;

  AchievementRepository({Box? box}) : _box = box ?? HiveService.achievementsBox;

  DateTime? unlockedAt(String achievementId) {
    final raw = _box.get(achievementId) as String?;
    return raw != null ? DateTime.parse(raw) : null;
  }

  bool isUnlocked(String achievementId) => _box.containsKey(achievementId);

  Future<void> markUnlocked(String achievementId, {DateTime? at}) {
    if (isUnlocked(achievementId)) return Future.value();
    return _box.put(achievementId, (at ?? DateTime.now()).toIso8601String());
  }

  Set<String> unlockedIds() => _box.keys.cast<String>().toSet();
}
