import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/utils/id_generator.dart';

/// A named, reusable Projects-screen filter preset (Phase 12): search
/// text + status filter + sort, saved so it doesn't need re-entering.
class SavedFilter {
  final String id;
  final String name;
  final String searchQuery;
  final ProjectStatusFilter filter;
  final ProjectSortOption sort;
  final DateTime createdAt;

  const SavedFilter({
    required this.id,
    required this.name,
    required this.searchQuery,
    required this.filter,
    required this.sort,
    required this.createdAt,
  });

  factory SavedFilter.create({
    required String name,
    required String searchQuery,
    required ProjectStatusFilter filter,
    required ProjectSortOption sort,
  }) {
    return SavedFilter(
      id: generateId(),
      name: name,
      searchQuery: searchQuery,
      filter: filter,
      sort: sort,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'searchQuery': searchQuery,
        'filter': filter.name,
        'sort': sort.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedFilter.fromMap(Map<dynamic, dynamic> map) => SavedFilter(
        id: map['id'] as String,
        name: map['name'] as String,
        searchQuery: map['searchQuery'] as String? ?? '',
        filter: ProjectStatusFilter.values.firstWhere(
          (f) => f.name == map['filter'],
          orElse: () => ProjectStatusFilter.all,
        ),
        sort: ProjectSortOption.values.firstWhere(
          (s) => s.name == map['sort'],
          orElse: () => ProjectSortOption.recentlyUpdated,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
