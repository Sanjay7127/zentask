import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentask/features/projects/screens/project_details_screen.dart';
import 'package:zentask/models/project.dart';
import 'package:zentask/models/task.dart';
import 'package:zentask/services/search/advanced_search_service.dart';

/// Cross-entity Advanced Search (Phase 12): one query box, matching
/// against Tasks/Projects/Events, with a priority filter for tasks.
class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final AdvancedSearchService _service = AdvancedSearchService();
  final TextEditingController _queryController = TextEditingController();
  TaskPriority? _priorityFilter;
  List<SearchResult> _results = [];
  Timer? _debounce;

  void _runSearch() {
    setState(() {
      _results = _service.search(_queryController.text, priority: _priorityFilter);
    });
  }

  // Search scans every task/project/event box in full (see
  // AdvancedSearchService's doc comment on why that's an acceptable
  // approach at this app's scale) — debouncing keystrokes avoids
  // repeating that scan on every character while the user is still
  // mid-word.
  void _runSearchDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search tasks, projects, events…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _runSearch(),
                  onChanged: (_) => _runSearchDebounced(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any priority'),
                        selected: _priorityFilter == null,
                        onSelected: (_) {
                          setState(() => _priorityFilter = null);
                          _runSearch();
                        },
                      ),
                      for (final priority in TaskPriority.values)
                        ChoiceChip(
                          label: Text(priority.label),
                          selected: _priorityFilter == priority,
                          onSelected: (_) {
                            setState(() => _priorityFilter = priority);
                            _runSearch();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _queryController.text.trim().isEmpty
                ? Center(
                    child: Text('Type to search',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Text('No matches',
                            style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return ListTile(
                            leading: Icon(_iconFor(result.type)),
                            title: Text(result.title),
                            subtitle: Text(result.subtitle,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text(_labelFor(result.type)),
                            onTap: () => _openResult(result),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(SearchResultType type) {
    switch (type) {
      case SearchResultType.task:
        return Icons.check_circle_outline;
      case SearchResultType.project:
        return Icons.folder_outlined;
      case SearchResultType.event:
        return Icons.event_outlined;
    }
  }

  String _labelFor(SearchResultType type) {
    switch (type) {
      case SearchResultType.task:
        return 'Task';
      case SearchResultType.project:
        return 'Project';
      case SearchResultType.event:
        return 'Event';
    }
  }

  void _openResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.project:
        final project = result.entity as Project;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProjectDetailsScreen(projectId: project.id),
        ));
        break;
      case SearchResultType.task:
        final task = result.entity as Task;
        if (task.projectId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProjectDetailsScreen(projectId: task.projectId!),
          ));
        }
        break;
      case SearchResultType.event:
        // Events have no dedicated details screen yet (Phase 3.4's
        // known gap, unchanged by Phase 12) — nothing to navigate to.
        break;
    }
  }
}
