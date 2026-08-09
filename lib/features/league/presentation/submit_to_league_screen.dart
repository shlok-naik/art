import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../auth/providers.dart';
import '../providers.dart';

/// Lets the signed-in user submit one or more of their own projects as
/// entries to [leagueId]. A project can be submitted at most once per
/// league (submitting it again just replaces that entry), but a user may
/// submit as many different projects as they like.
class SubmitToLeagueScreen extends ConsumerStatefulWidget {
  const SubmitToLeagueScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  ConsumerState<SubmitToLeagueScreen> createState() => _SubmitToLeagueScreenState();
}

class _SubmitToLeagueScreenState extends ConsumerState<SubmitToLeagueScreen> {
  String? _submittingProjectId;

  Future<void> _submit(String projectId, String photoUrl) async {
    setState(() => _submittingProjectId = projectId);
    try {
      await ref.read(leagueRepositoryProvider).submitProject(
            leagueId: widget.leagueId,
            projectId: projectId,
            photoUrl: photoUrl,
          );
      ref.invalidate(leagueSubmissionsProvider(widget.leagueId));
      if (!mounted) return;
      setState(() => _submittingProjectId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted! Tap another project to submit it too.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingProjectId = null);
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
              padding: const EdgeInsets.all(AppSpacing.space24),
              child: Text(
                "You don't have any projects with a logged session yet — log a session first.",
                textAlign: TextAlign.center,
                style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kMutedColor),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.space16),
            itemCount: projectsWithCover.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final (project, coverPhotoUrl) = projectsWithCover[index];
              final projectId = project['id'].toString();
              final isSubmitting = _submittingProjectId == projectId;
              final isSubmitted = submittedProjectIds.contains(projectId);
              return GestureDetector(
                onTap: isSubmitting ? null : () => _submit(projectId, coverPhotoUrl),
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
                          color: kMutedColor,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8, vertical: AppSpacing.space4),
                          child: Text(
                            project['title']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                      if (isSubmitting)
                        Container(
                          color: kMutedColor,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: Colors.white),
                        ),
                      if (isSubmitted)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.space4),
                            decoration: const BoxDecoration(color: kAccentColor, shape: BoxShape.circle),
                            child: const AppIcon(AppIcons.checkCircle, size: 12, color: Colors.white, strokeWidth: 2.4),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const AppSkeletonScreen(),
        error: (error, stack) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(myProjectsWithCoverProvider),
        ),
      ),
    );
  }
}
