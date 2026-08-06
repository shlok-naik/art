import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../shell/main_shell.dart';
import '../domain/league.dart';
import '../providers.dart';
import 'submit_to_league_screen.dart';

String _formatTimeRemaining(DateTime endsAt) {
  final remaining = endsAt.difference(DateTime.now().toUtc());
  if (remaining.isNegative) return 'Voting closed';
  final days = remaining.inDays;
  final hours = remaining.inHours.remainder(24);
  if (days > 0) return '${days}d ${hours}h left';
  final minutes = remaining.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m left';
  return '${minutes}m left';
}

class LeagueScreen extends ConsumerWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(currentLeagueProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'League'),
      body: SafeArea(
        child: leagueAsync.when(
          data: (league) => _LeagueBody(league: league),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppErrorText('Error: $error'),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) => AppBottomNav(
          currentIndex: -1,
          onTap: (i) => goToMainTab(context, ref, i),
        ),
      ),
    );
  }
}

class _LeagueBody extends ConsumerWidget {
  const _LeagueBody({required this.league});

  final League league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(leagueSubmissionsProvider(league.id));
    final myVoteAsync = ref.watch(myLeagueVoteProvider(league.id));
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentLeagueProvider);
        ref.invalidate(leagueSubmissionsProvider(league.id));
        ref.invalidate(myLeagueVoteProvider(league.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ThemeBanner(league: league),
            const SizedBox(height: 16),
            const _PastChampionCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Submissions', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
                const Spacer(),
                if (league.isOpen)
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SubmitToLeagueScreen(leagueId: league.id)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        'Submit',
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kAccentColor),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Vote for your favorite — no self-voting!',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
            ),
            const SizedBox(height: 12),
            submissionsAsync.when(
              data: (submissions) {
                if (submissions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: appHardCardDecoration(radius: 18),
                    child: Text(
                      'No submissions yet — be the first to enter this theme.',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                    ),
                  );
                }
                final myVoteId = myVoteAsync.value;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: submissions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final submission = submissions[index];
                    return _SubmissionCard(
                      submission: submission,
                      isMine: submission.userId == myUserId,
                      hasVoted: myVoteId != null,
                      isMyVote: submission.id == myVoteId,
                      isVotingOpen: league.isOpen,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorText('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeBanner extends StatelessWidget {
  const _ThemeBanner({required this.league});

  final League league;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appHardCardDecoration(radius: 18, color: kAccentTintColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "THIS SEASON'S THEME",
            style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kAccentColor),
          ),
          const SizedBox(height: 4),
          Text(league.themeTitle, style: appHeadlineStyle(fontSize: 38)),
          const SizedBox(height: 2),
          Text(
            league.themeDescription,
            style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF444444)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.black, size: 18),
              const SizedBox(width: 6),
              Text(
                _formatTimeRemaining(league.endsAt),
                style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastChampionCard extends ConsumerWidget {
  const _PastChampionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championAsync = ref.watch(latestLeagueChampionProvider);
    final champion = championAsync.value;
    if (champion == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: appHardCardDecoration(radius: 18),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Last Season's Champion", style: GoogleFonts.chewy(fontSize: 16, color: Colors.black)),
                Text(
                  '@${champion.artistUsername} — ${champion.votes} vote${champion.votes == 1 ? '' : 's'}',
                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends ConsumerStatefulWidget {
  const _SubmissionCard({
    required this.submission,
    required this.isMine,
    required this.hasVoted,
    required this.isMyVote,
    required this.isVotingOpen,
  });

  final LeagueSubmission submission;
  final bool isMine;
  final bool hasVoted;
  final bool isMyVote;
  final bool isVotingOpen;

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  bool _isVoting = false;

  Future<void> _vote() async {
    setState(() => _isVoting = true);
    try {
      await ref.read(leagueRepositoryProvider).vote(
            leagueId: widget.submission.leagueId,
            submissionId: widget.submission.id,
          );
      ref.invalidate(myLeagueVoteProvider(widget.submission.leagueId));
      ref.invalidate(leagueSubmissionsProvider(widget.submission.leagueId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to vote: $e')));
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    final canVote = widget.isVotingOpen && !widget.isMine && !_isVoting;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: appHardCardDecoration(radius: 14, shadowOffset: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: submission.photoUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 24, color: Colors.black26),
                    )
                  : CachedNetworkImage(
                      imageUrl: submission.photoUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(color: Colors.grey.shade100),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 24, color: Colors.black26),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${submission.artistUsername}',
            style: GoogleFonts.chewy(fontSize: 14, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: canVote ? _vote : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: widget.isMyVote ? kAccentTintColor : null,
                border: Border.all(color: kBorderColor, width: kBorderWidth),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isVoting
                  ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.isMyVote ? '❤️' : '🤍', style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 5),
                        Text(
                          '${submission.votes}',
                          style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
