import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kBorderColor, width: kBorderWidth),
        ),
        title: Text('Delete project?', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text('This will permanently delete "$title".', style: GoogleFonts.chewy(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.chewy(color: Colors.black, fontSize: 15)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: GoogleFonts.chewy(color: kAccentColor, fontSize: 15)),
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

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Projects'),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: appInputDecoration('New project name'),
                        style: GoogleFonts.chewy(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: kAccentColor),
                            )
                          : const Icon(Icons.add_circle, color: kAccentColor, size: 32),
                      onPressed: _isCreating ? null : _createProject,
                    ),
                  ],
                ),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppErrorText(_errorText!),
                ),
              Expanded(
                child: projectsAsync.when(
                  data: (projects) {
                    if (projects.isEmpty) {
                      return Center(
                        child: Text(
                          'No projects yet.',
                          style: GoogleFonts.chewy(fontSize: 16, color: Colors.black),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(projectsListProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final title = project['title']?.toString() ?? project['id'].toString();
                          final createdAt = _formatCreatedAt(project['created_at']);
                          final finishedStatus = project['finished_status']?.toString() ?? '—';
                          final leagueId = project['league_id']?.toString() ?? '—';

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final projectId = project['id'].toString();
                              await ref.read(recentProjectStoreProvider).recordOpened(projectId);
                              ref.invalidate(projectsListProvider);
                              ref.invalidate(lastOpenedProjectProvider);
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: appCardDecoration(),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Date created: $createdAt', style: GoogleFonts.chewy(fontSize: 14)),
                                        Text('Time spent so far: 0', style: GoogleFonts.chewy(fontSize: 14)),
                                        Text('Number of sessions: 0', style: GoogleFonts.chewy(fontSize: 14)),
                                        Text('Finished status: $finishedStatus', style: GoogleFonts.chewy(fontSize: 14)),
                                        Text('League: $leagueId', style: GoogleFonts.chewy(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.black),
                                    onPressed: () => _deleteProject(project),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: AppErrorText('Failed to load projects: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}