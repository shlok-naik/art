import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'project_detail_screen.dart';

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

  Future<void> _finishProject(Map<String, dynamic> project) async {
    final title = project['title']?.toString() ?? project['id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: kBorderColor, width: kBorderWidth),
        ),
        title: Text('Finish project?', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text(
          '"$title" will be marked 100% complete and locked — no new sessions can be added afterward.',
          style: GoogleFonts.chewy(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.chewy(color: kInkColor, fontSize: 15)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Finish', style: GoogleFonts.chewy(color: kAccentColor, fontSize: 15)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(projectsRepositoryProvider).finishProject(project['id'].toString());
      if (!mounted) return;
      ref.invalidate(projectsListProvider);
      ref.invalidate(lastOpenedProjectProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to finish project: $e')),
      );
    }
  }

  Future<void> _deleteProject(Map<String, dynamic> project) async {
    final title = project['title']?.toString() ?? project['id'].toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: kBorderColor, width: kBorderWidth),
        ),
        title: Text('Delete project?', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text('This will permanently delete "$title".', style: GoogleFonts.chewy(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.chewy(color: kInkColor, fontSize: 15)),
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

    return Scaffold(
      appBar: appThemedAppBar(context, 'Projects'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: appInputDecoration('New project name').copyWith(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: kBorderColor, width: kBorderWidth),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: kBorderColor, width: kBorderWidth),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: kAccentColor, width: kBorderWidth),
                        ),
                        labelStyle: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kMutedColor),
                      ),
                      style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kInkColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isCreating ? null : _createProject,
                    borderRadius: BorderRadius.circular(23),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kAccentColor,
                        border: Border.all(color: kBorderColor, width: kBorderWidth),
                        boxShadow: hardShadow(offset: 3),
                      ),
                      alignment: Alignment.center,
                      child: _isCreating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
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
                        style: GoogleFonts.chewy(fontSize: 16, color: kInkColor),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(projectsListProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return _ProjectCard(
                          project: project,
                          onOpen: () async {
                            final projectId = project['id'].toString();
                            await ref.read(projectsRepositoryProvider).recordOpened(projectId);
                            ref.invalidate(projectsListProvider);
                            ref.invalidate(lastOpenedProjectProvider);
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                            );
                          },
                          onFinish: () => _finishProject(project),
                          onDelete: () => _deleteProject(project),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(projectsListProvider),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) => goToMainTab(context, ref, i),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onFinish,
    required this.onDelete,
  });

  final Map<String, dynamic> project;
  final VoidCallback onOpen;
  final VoidCallback onFinish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = project['title']?.toString() ?? project['id'].toString();
    final createdAt = formatDateValue(project['created_at']);
    final completionPercent =
        int.tryParse(project['completion_percent']?.toString() ?? '') ?? 0;
    final isFinished = completionPercent == 100;
    final sessionCount = ref.watch(sessionsListProvider(project['id'].toString())).value?.length;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: GoogleFonts.chewy(fontSize: 18, color: kInkColor)),
                  const SizedBox(height: 3),
                  Text(
                    sessionCount == null
                        ? 'Created $createdAt'
                        : 'Created $createdAt · $sessionCount session${sessionCount == 1 ? '' : 's'}',
                    style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF666666)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isFinished ? kSuccessBgColor : kAccentTintColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFinished ? 'Finished' : 'In progress',
                      style: appBodyStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isFinished ? kSuccessTextColor : kAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isFinished)
                  InkWell(
                    onTap: onFinish,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.check_circle_outline, color: kSuccessTextColor, size: 20),
                    ),
                  ),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.close, color: kInkColor, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
