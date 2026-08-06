import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_styles.dart';
import '../../feed/providers.dart';
import '../providers.dart';

/// Lets the signed-in user pick one of their own posted sessions to submit
/// as their entry to [leagueId]. Submitting again (a different post)
/// replaces their existing entry, matching the one-submission-per-league
/// constraint enforced server-side.
class SubmitToLeagueScreen extends ConsumerStatefulWidget {
  const SubmitToLeagueScreen({super.key, required this.leagueId});

  final String leagueId;

  @override
  ConsumerState<SubmitToLeagueScreen> createState() => _SubmitToLeagueScreenState();
}

class _SubmitToLeagueScreenState extends ConsumerState<SubmitToLeagueScreen> {
  String? _submittingSessionId;

  Future<void> _submit(String sessionId, String photoUrl) async {
    setState(() => _submittingSessionId = sessionId);
    try {
      await ref.read(leagueRepositoryProvider).submit(
            leagueId: widget.leagueId,
            sessionId: sessionId,
            photoUrl: photoUrl,
          );
      ref.invalidate(leagueSubmissionsProvider(widget.leagueId));
      ref.invalidate(myLeagueSubmissionProvider(widget.leagueId));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingSessionId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(myPostsProvider);
    final mySubmissionAsync = ref.watch(myLeagueSubmissionProvider(widget.leagueId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'Submit to League'),
      body: postsAsync.when(
        data: (posts) {
          final postsWithPhotos = posts.where((p) => (p.photoUrl ?? '').isNotEmpty).toList();
          if (postsWithPhotos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "You don't have any posts with a photo yet — post a session first.",
                textAlign: TextAlign.center,
                style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
              ),
            );
          }
          final mySubmissionId = mySubmissionAsync.value?.id;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: postsWithPhotos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final post = postsWithPhotos[index];
              final isSubmitting = _submittingSessionId == post.id;
              return GestureDetector(
                onTap: isSubmitting ? null : () => _submit(post.id, post.photoUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(imageUrl: post.photoUrl!, fit: BoxFit.cover),
                      if (isSubmitting)
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: Colors.white),
                        ),
                      if (mySubmissionId != null && post.id == mySubmissionId)
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
