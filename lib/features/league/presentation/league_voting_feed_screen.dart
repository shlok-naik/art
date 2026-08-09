import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../auth/providers.dart';
import '../../projects/providers.dart';
import '../domain/league.dart';
import '../providers.dart';

/// Full-screen voting feed for [league]'s voting phase: swipe vertically
/// between other artists' submissions, swipe horizontally within a
/// submission to browse its sessions, and rate the whole project 1-5
/// stars. Deliberately styled as an immersive black-background story
/// viewer (unlike the rest of the app's white/hard-card look) since that's
/// the natural shape for a swipe-through rating feed.
class LeagueVotingFeedScreen extends ConsumerWidget {
  const LeagueVotingFeedScreen({super.key, required this.league});

  final League league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(leagueSubmissionsProvider(league.id));
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: submissionsAsync.when(
          data: (submissions) {
            final others = submissions.where((s) => s.userId != myUserId).toList();
            if (others.isEmpty) {
              return _EmptyFeed(onClose: () => Navigator.of(context).pop());
            }
            return _VotingFeedBody(league: league, submissions: others);
          },
          loading: () => const AppSkeletonBlock(onDark: true, height: double.infinity),
          error: (error, stack) => AppErrorState(
            error: error,
            onDark: true,
            onRetry: () => ref.invalidate(leagueSubmissionsProvider(league.id)),
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Text(
            'No other submissions to rate yet.',
            style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        Positioned(top: 8, left: 8, child: _CloseButton(onTap: onClose)),
      ],
    );
  }
}

class _VotingFeedBody extends ConsumerStatefulWidget {
  const _VotingFeedBody({required this.league, required this.submissions});

  final League league;
  final List<LeagueSubmission> submissions;

  @override
  ConsumerState<_VotingFeedBody> createState() => _VotingFeedBodyState();
}

class _VotingFeedBodyState extends ConsumerState<_VotingFeedBody> {
  late final PageController _verticalController = PageController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myRatingsAsync = ref.watch(myLeagueRatingsProvider(widget.league.id));
    final myRatings = myRatingsAsync.value ?? const {};

    return Stack(
      children: [
        PageView.builder(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          itemCount: widget.submissions.length,
          itemBuilder: (context, index) {
            final submission = widget.submissions[index];
            return _FeedProjectPage(
              league: widget.league,
              submission: submission,
              initialRating: myRatings[submission.id] ?? 0,
            );
          },
        ),
        Positioned(top: 8, left: 8, child: _CloseButton(onTap: () => Navigator.of(context).pop())),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space8),
          decoration: const BoxDecoration(color: kMutedColor, shape: BoxShape.circle),
          child: const AppIcon(AppIcons.x, size: 20, color: Colors.white, strokeWidth: 2),
        ),
      ),
    );
  }
}

/// One submission's page in the vertical feed: a horizontal PageView over
/// that project's session photos, plus a star-rating bar pinned to the
/// bottom.
class _FeedProjectPage extends ConsumerStatefulWidget {
  const _FeedProjectPage({required this.league, required this.submission, required this.initialRating});

  final League league;
  final LeagueSubmission submission;
  final int initialRating;

  @override
  ConsumerState<_FeedProjectPage> createState() => _FeedProjectPageState();
}

class _FeedProjectPageState extends ConsumerState<_FeedProjectPage> {
  final PageController _horizontalController = PageController();
  int _sessionIndex = 0;
  late int _myRating = widget.initialRating;
  bool _isRating = false;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _rate(int rating) async {
    if (_isRating || !widget.league.isVotingOpen) return;
    final previous = _myRating;
    setState(() {
      _myRating = rating;
      _isRating = true;
    });
    try {
      await ref.read(leagueRepositoryProvider).rateSubmission(
            leagueId: widget.submission.leagueId,
            submissionId: widget.submission.id,
            rating: rating,
          );
      ref.invalidate(leagueSubmissionsProvider(widget.submission.leagueId));
      ref.invalidate(myLeagueRatingsProvider(widget.submission.leagueId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _myRating = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to rate: $e')));
    } finally {
      if (mounted) setState(() => _isRating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    final sessionsAsync = ref.watch(sessionsListProvider(submission.projectId));

    return Stack(
      fit: StackFit.expand,
      children: [
        sessionsAsync.when(
          data: (sessions) {
            final photos = [
              for (final session in sessions)
                if (session['photo_url']?.toString() case final url? when url.isNotEmpty) url,
            ];
            if (photos.isEmpty) {
              return submission.photoUrl.isEmpty
                  ? Container(color: Colors.grey.shade900)
                  : CachedNetworkImage(imageUrl: submission.photoUrl, fit: BoxFit.cover);
            }
            return PageView.builder(
              controller: _horizontalController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _sessionIndex = i),
              itemBuilder: (context, i) => CachedNetworkImage(imageUrl: photos[i], fit: BoxFit.cover),
            );
          },
          loading: () => const AppSkeletonBlock(onDark: true, height: double.infinity),
          // The submission's cover still lets the entry be rated even if its
          // session list failed to load; with no cover either, say so rather
          // than showing a silent blank page.
          error: (error, stack) => submission.photoUrl.isEmpty
              ? AppErrorState(
                  error: error,
                  onDark: true,
                  onRetry: () => ref.invalidate(sessionsListProvider(submission.projectId)),
                )
              : CachedNetworkImage(imageUrl: submission.photoUrl, fit: BoxFit.cover),
        ),
        // Top gradient + per-session page dots, mirroring the Instagram-story
        // convention for "swipe sideways to see more of this one entry".
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 50, 12, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
              ),
            ),
            child: sessionsAsync.maybeWhen(
              data: (sessions) {
                final count = sessions.where((s) => (s['photo_url']?.toString() ?? '').isNotEmpty).length;
                if (count <= 1) return const SizedBox.shrink();
                return Row(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.space4),
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= _sessionIndex ? Colors.white : Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned(
          top: 44,
          left: 12,
          right: 56,
          child: Text(
            '@${submission.artistUsername} · ${submission.projectTitle}',
            style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Bottom gradient + rating bar.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (submission.caption != null && submission.caption!.isNotEmpty) ...[
                  Text(
                    submission.caption!,
                    style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.space12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var star = 1; star <= 5; star++)
                      GestureDetector(
                        onTap: widget.league.isVotingOpen ? () => _rate(star) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                          child: Text(
                            '★',
                            style: TextStyle(
                              fontSize: 30,
                              color: star <= _myRating ? const Color(0xFFF5B301) : const Color(0xFF5A5A5A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  _myRating > 0
                      ? 'Your rating: $_myRating/5 · ★ ${submission.stars} total'
                      : '★ ${submission.stars} total',
                  style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
