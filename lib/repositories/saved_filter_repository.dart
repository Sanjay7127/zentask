import 'package:hive/hive.dart';
import 'package:zentask/models/saved_filter.dart';
import 'package:zentask/services/hive_service.dart';

/// Storage layer for [SavedFilter]s.
class SavedFilterRepository {
  final Box _box;

  SavedFilterRepository({Box? box}) : _box = box ?? HiveService.savedFiltersBox;

  List<SavedFilter> getAll() => _box.values
      .map((raw) => SavedFilter.fromMap(raw as Map))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> save(SavedFilter filter) => _box.put(filter.id, filter.toMap());

  Future<void> delete(String id) => _box.delete(id);
}
