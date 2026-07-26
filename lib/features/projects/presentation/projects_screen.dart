import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'project_detail_screen.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatCreatedAt(dynamic value) {
  if (value == null) return '—';
  final date = DateTime.tryParse(value.toString());
  if (date == null) return value.toString();
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _nameController = TextEditingController();
  bool _isCreating = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreating = true;
      _errorText = null;
    });
    try {
      await ref.read(projectsRepositoryProvider).createProject({'title': name});
      if (!mounted) return;
      _nameController.clear();
      ref.invalidate(projectsListProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteProject(Map<String, dynamic> project) async {
    final title = project['title']?.toString() ?? project['id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('This will permanently delete "$title".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(projectsRepositoryProvider).deleteProject(project['id'].toString());
      if (!mounted) return;
      ref.invalidate(projectsListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete project: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'New project name'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  onPressed: _isCreating ? null : _createProject,
                ),
              ],
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return const Center(child: Text('No projects yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(projectsListProvider),
                  child: ListView.separated(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final title = project['title']?.toString() ?? project['id'].toString();
                      final createdAt = _formatCreatedAt(project['created_at']);
                      final finishedStatus = project['finished_status']?.toString() ?? '—';
                      final leagueId = project['league_id']?.toString() ?? '—';

                      return InkWell(
                        onTap: () async {
                          final projectId = project['id'].toString();
                          await ref.read(recentProjectStoreProvider).setLastOpenedProjectId(projectId);
                          ref.invalidate(lastOpenedProjectProvider);
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text('Date created: $createdAt'),
                                    const Text('Time spent so far: 0'),
                                    const Text('Number of sessions: 0'),
                                    Text('Finished status: $finishedStatus'),
                                    Text('League: $leagueId'),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteProject(project),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(height: 1),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Failed to load projects: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
