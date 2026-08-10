import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../providers.dart';

/// Lets the signed-in user pick one or more of their own projects (tap to
/// tick, tap again to untick), then submits every ticked project as an
/// entry to [leagueId] on Confirm — routing back to the league page once
/// done. A project can be submitted at most once per league (submitting it
/// again just replaces that entry), but a user may submit as many
/// different projects as they like. Already-submitted projects show as
/// permanently ticked; untangling those uses the × on the league page
/// itself, not this picker.
class SubmitToLeagueScreen extends ConsumerStatefulWidget {
  const SubmitToLeagueScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  ConsumerState<SubmitToLeagueScreen> createState() => _SubmitToLeagueScreenState();
}

class _SubmitToLeagueScreenState extends ConsumerState<SubmitToLeagueScreen> {
  final Set<String> _selectedProjectIds = {};
  bool _isConfirming = false;

  void _toggleSelected(String projectId) {
    setState(() {
      if (!_selectedProjectIds.remove(projectId)) {
        _selectedProjectIds.add(projectId);
      }
    });
  }

  Future<void> _confirm(List<(Map<String, dynamic> project, String coverPhotoUrl)> projectsWithCover) async {
    setState(() => _isConfirming = true);
    try {
      final repo = ref.read(leagueRepositoryProvider);
      for (final (project, coverPhotoUrl) in projectsWithCover) {
        final projectId = project['id'].toString();
        if (!_selectedProjectIds.contains(projectId)) continue;
        await repo.submitProject(leagueId: widget.leagueId, projectId: projectId, photoUrl: coverPhotoUrl);
      }
      ref.invalidate(leagueSubmissionsProvider(widget.leagueId));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(myProjectsWithCoverProvider);
    final mySubmissionsAsync = ref.watch(leagueSubmissionsProvider(widget.leagueId));
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    final submittedProjectIds = {
      for (final submission in mySubmissionsAsync.value ?? const [])
        if (submission.userId == myUserId) submission.projectId,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'Submit to League'),
      body: projectsAsync.when(
        data: (projectsWithCover) {
          if (projectsWithCover.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "You don't have any projects with a logged session yet — log a session first.",
                textAlign: TextAlign.center,
                style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projectsWithCover.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final (project, coverPhotoUrl) = projectsWithCover[index];
                    final projectId = project['id'].toString();
                    final isSubmitted = submittedProjectIds.contains(projectId);
                    final isSelected = _selectedProjectIds.contains(projectId);
                    return GestureDetector(
                      onTap: isSubmitted ? null : () => _toggleSelected(projectId),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(imageUrl: coverPhotoUrl, fit: BoxFit.cover),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                child: Text(
                                  project['title']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                            if (isSubmitted || isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: kAccentColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: AppPrimaryButton(
                    label: _selectedProjectIds.isEmpty
                        ? 'Confirm'
                        : 'Confirm (${_selectedProjectIds.length})',
                    isLoading: _isConfirming,
                    onPressed: _selectedProjectIds.isEmpty ? null : () => _confirm(projectsWithCover),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppErrorText('Error: $error'),
          ),
        ),
      ),
    );
  }
}
