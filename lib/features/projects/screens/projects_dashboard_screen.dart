import 'package:flutter/material.dart';
import 'package:zentask/features/projects/screens/project_details_screen.dart';
import 'package:zentask/features/projects/widgets/project_card.dart';
import 'package:zentask/features/projects/widgets/project_form_dialog.dart';
import 'package:zentask/features/projects/widgets/project_list_tile.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/saved_filter.dart';
import 'package:zentask/providers/projects_controller.dart';
import 'package:zentask/repositories/saved_filter_repository.dart';

class ProjectsDashboardScreen extends StatefulWidget {
  const ProjectsDashboardScreen({super.key});

  @override
  State<ProjectsDashboardScreen> createState() =>
      _ProjectsDashboardScreenState();
}

class _ProjectsDashboardScreenState extends State<ProjectsDashboardScreen> {
  final ProjectsController _controller = ProjectsController();
  final TextEditingController _searchController = TextEditingController();
  final SavedFilterRepository _savedFilterRepository = SavedFilterRepository();

  ProjectStatusFilter _filter = ProjectStatusFilter.all;
  ProjectSortOption _sort = ProjectSortOption.recentlyUpdated;
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
    _searchController.addListener(_handleSearchChanged);
  }

  Future<void> _saveCurrentFilter() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Save filter as...'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    await _savedFilterRepository.save(SavedFilter.create(
      name: name,
      searchQuery: _searchQuery,
      filter: _filter,
      sort: _sort,
    ));
    setState(() {});
  }

  void _applySavedFilter(SavedFilter saved) {
    setState(() {
      _searchController.text = saved.searchQuery;
      _filter = saved.filter;
      _sort = saved.sort;
    });
  }

  void _handleChanged() => setState(() {});

  void _handleSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final result = await showProjectFormDialog(context);
    if (result == null) return;
    await _controller.createProject(
      title: result.title,
      description: result.description,
      colorValue: result.colorValue,
      iconKey: result.iconKey,
      category: result.category,
      priority: result.priority,
    );
  }

  Future<void> _editProject(Project project) async {
    final result = await showProjectFormDialog(context, existing: project);
    if (result == null) return;
    await _controller.updateProject(project.copyWith(
      title: result.title,
      description: result.description,
      colorValue: result.colorValue,
      iconKey: result.iconKey,
      category: result.category,
      priority: result.priority,
    ));
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          '"${project.title}" will be removed. Its tasks will be kept, unassigned from any project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteProject(project.id);
    }
  }

  void _handleCardAction(Project project, ProjectCardAction action) {
    switch (action) {
      case ProjectCardAction.edit:
        _editProject(project);
        break;
      case ProjectCardAction.archive:
        _controller.archiveProject(project.id);
        break;
      case ProjectCardAction.restore:
        _controller.restoreProject(project.id);
        break;
      case ProjectCardAction.delete:
        _deleteProject(project);
        break;
    }
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(projectId: project.id),
      ),
    );
    _handleChanged();
  }

  static const _filterLabels = {
    ProjectStatusFilter.all: 'All',
    ProjectStatusFilter.active: 'Active',
    ProjectStatusFilter.completed: 'Completed',
    ProjectStatusFilter.archived: 'Archived',
  };

  static const _sortLabels = {
    ProjectSortOption.recentlyUpdated: 'Recently updated',
    ProjectSortOption.name: 'Name',
    ProjectSortOption.dueDate: 'Due date',
    ProjectSortOption.progress: 'Progress',
  };

  @override
  Widget build(BuildContext context) {
    final hasAnyProjects = _controller.totalProjectCount > 0;
    final projects = _controller.visibleProjects(
      searchQuery: _searchQuery,
      filter: _filter,
      sort: _sort,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          PopupMenuButton<ProjectSortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => ProjectSortOption.values
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (option == _sort)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(_sortLabels[option]!),
                        ],
                      ),
                    ))
                .toList(),
          ),
          PopupMenuButton<Object>(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Saved filters',
            onSelected: (value) {
              if (value == 'save') {
                _saveCurrentFilter();
              } else if (value is SavedFilter) {
                _applySavedFilter(value);
              }
            },
            itemBuilder: (context) {
              final saved = _savedFilterRepository.getAll();
              return [
                const PopupMenuItem(value: 'save', child: Text('Save current filter...')),
                if (saved.isNotEmpty) const PopupMenuDivider(),
                for (final filter in saved)
                  PopupMenuItem(value: filter, child: Text(filter.name)),
              ];
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: !hasAnyProjects
          ? _EmptyState(onCreate: _createProject)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search projects…',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear),
                              onPressed: _searchController.clear,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: ProjectStatusFilter.values.map((filter) {
                        return ChoiceChip(
                          label: Text(_filterLabels[filter]!),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardStats(controller: _controller),
                        const SizedBox(height: 20),
                        Text(
                          'Your Projects (${projects.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: projects.isEmpty
                              ? _NoResultsState(
                                  key: const ValueKey('empty'),
                                  searchQuery: _searchQuery,
                                )
                              : _isGridView
                                  ? _ProjectGrid(
                                      key: const ValueKey('grid'),
                                      projects: projects,
                                      controller: _controller,
                                      onOpen: _openProject,
                                      onAction: _handleCardAction,
                                    )
                                  : _ProjectList(
                                      key: const ValueKey('list'),
                                      projects: projects,
                                      controller: _controller,
                                      onOpen: _openProject,
                                      onAction: _handleCardAction,
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectGrid extends StatelessWidget {
  final List<Project> projects;
  final ProjectsController controller;
  final ValueChanged<Project> onOpen;
  final void Function(Project, ProjectCardAction) onAction;

  const _ProjectGrid({
    super.key,
    required this.projects,
    required this.controller,
    required this.onOpen,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 360).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 190,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final project = projects[index];
            return RepaintBoundary(
              child: ProjectCard(
                project: project,
                completedTaskCount: controller.completedTaskCountFor(project.id),
                totalTaskCount: controller.totalTaskCountFor(project.id),
                completionRate: controller.completionRateFor(project.id),
                nextUpcomingTask: controller.nextUpcomingTaskFor(project.id),
                onTap: () => onOpen(project),
                onAction: (action) => onAction(project, action),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProjectList extends StatelessWidget {
  final List<Project> projects;
  final ProjectsController controller;
  final ValueChanged<Project> onOpen;
  final void Function(Project, ProjectCardAction) onAction;

  const _ProjectList({
    super.key,
    required this.projects,
    required this.controller,
    required this.onOpen,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: projects.map((project) {
        return RepaintBoundary(
          child: ProjectListTile(
            project: project,
            completedTaskCount: controller.completedTaskCountFor(project.id),
            totalTaskCount: controller.totalTaskCountFor(project.id),
            completionRate: controller.completionRateFor(project.id),
            onTap: () => onOpen(project),
            onAction: (action) => onAction(project, action),
          ),
        );
      }).toList(),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  final ProjectsController controller;
  const _DashboardStats({required this.controller});

  @override
  Widget build(BuildContext context) {
    final upcoming = controller.upcomingDeadlines();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 160).floor().clamp(2, 5);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatTile(
              label: 'Total Projects',
              value: '${controller.totalProjectCount}',
            ),
            _StatTile(
              label: 'Active',
              value: '${controller.activeProjectCount}',
            ),
            _StatTile(
              label: 'Archived',
              value: '${controller.archivedProjectCount}',
            ),
            _StatTile(
              label: 'Completion',
              value:
                  '${(controller.averageActiveCompletion * 100).round()}%',
            ),
            _StatTile(
              label: 'Upcoming Deadlines',
              value: '${upcoming.length}',
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          Text(
            label,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 72, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project to start organizing tasks.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final String searchQuery;
  const _NoResultsState({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = searchQuery.trim().isEmpty
        ? 'No projects match this filter.'
        : 'No projects match "$searchQuery".';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
