import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../shell/main_shell.dart';
import '../domain/league.dart';
import '../providers.dart';
import 'league_voting_feed_screen.dart';
import 'submit_to_league_screen.dart';

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
          error: (error, stack) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(currentLeagueProvider),
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

class _LeagueBody extends ConsumerStatefulWidget {
  const _LeagueBody({required this.league});

  final League league;

  @override
  ConsumerState<_LeagueBody> createState() => _LeagueBodyState();
}

class _LeagueBodyState extends ConsumerState<_LeagueBody> {
  @override
  Widget build(BuildContext context) {
    final league = widget.league;
    final submissionsAsync = ref.watch(leagueSubmissionsProvider(league.id));
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentLeagueProvider);
        ref.invalidate(leagueSubmissionsProvider(league.id));
        ref.invalidate(myLeagueRatingsProvider(league.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CountdownTimer(league: league),
            const SizedBox(height: 12),
            _ThemeBanner(league: league),
            const SizedBox(height: 16),
            submissionsAsync.when(
              data: (submissions) => _Leaderboard(submissions: submissions, myUserId: myUserId),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const _PastChampionCard(),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Submissions', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
                const Spacer(),
                if (league.isSubmissionOpen)
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
                  )
                else if (league.isVotingOpen)
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LeagueVotingFeedScreen(league: league)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rate Entries',
                            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kAccentColor),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right, size: 16, color: kAccentColor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              league.isSubmissionOpen
                  ? 'Submissions close Friday 2pm London — rating opens right after.'
                  : league.isVotingOpen
                      ? 'Rate every entry 1-5 stars — no self-rating!'
                      : 'Voting has closed for this round.',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
            ),
            const SizedBox(height: 12),
            submissionsAsync.when(
              data: (submissions) {
                final visible = submissions.where((s) => s.userId == myUserId).toList();

                if (visible.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: appHardCardDecoration(radius: 18),
                    child: Text(
                      "You haven't submitted a project yet — tap Submit above.",
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final submission = visible[index];
                    return _SubmissionCard(
                      submission: submission,
                      isMine: submission.userId == myUserId,
                      canUnsubmit: submission.userId == myUserId && league.isSubmissionOpen,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                error: error,
                onRetry: () => ref.invalidate(leagueSubmissionsProvider(league.id)),
              ),
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
        ],
      ),
    );
  }
}

/// Live countdown to the current phase's boundary (submissions closing,
/// then voting closing), ticking every second so days/hours/minutes/
/// seconds — and the phase label itself — stay accurate without needing a
/// pull-to-refresh across a Friday-2pm or Sunday-midnight transition.
class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({required this.league});

  final League league;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boundary = widget.league.nextPhaseBoundary;
    if (boundary == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: appHardCardDecoration(radius: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_outlined, color: Colors.black54, size: 18),
            const SizedBox(width: 8),
            Text(
              'Voting closed',
              style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    final remaining = boundary.difference(DateTime.now().toUtc());
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: appHardCardDecoration(radius: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.league.phaseLabel.toUpperCase(),
            style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF888888)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountdownUnit(value: days, label: 'DAYS'),
              _CountdownUnit(value: hours, label: 'HRS'),
              _CountdownUnit(value: minutes, label: 'MIN'),
              _CountdownUnit(value: seconds, label: 'SEC'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value.toString().padLeft(2, '0'), style: GoogleFonts.chewy(fontSize: 26, color: Colors.black)),
        const SizedBox(height: 2),
        Text(
          label,
          style: appBodyStyle(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF888888)),
        ),
      ],
    );
  }
}

/// The top 10 of the current standings, live off the same vote counts the
/// submissions grid uses — it updates the moment a vote is cast (or on
/// pull-to-refresh for votes cast by others), no separate polling needed.
/// If the signed-in user has a submission, their best one's rank is called
/// out separately — inline if it's already in the top 10, or in its own
/// small section below if it isn't.
class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.submissions, required this.myUserId});

  final List<LeagueSubmission> submissions;
  final String? myUserId;

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _topCount = 10;

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) return const SizedBox.shrink();
    // fetchSubmissions already orders by votes descending. A user's "rank"
    // is their best (first-listed) submission if they've entered more than
    // one project.
    final top = submissions.take(_topCount).toList();
    final myRank = myUserId == null ? -1 : submissions.indexWhere((s) => s.userId == myUserId);
    final myRowShownInTop = myRank >= 0 && myRank < top.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appHardCardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard, color: kAccentColor, size: 20),
              const SizedBox(width: 6),
              Text('Current Standings', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _LeaderboardRow(rank: i, submission: top[i], isMe: i == myRank),
          ],
          if (myRank >= 0 && !myRowShownInTop) ...[
            const SizedBox(height: 12),
            const Divider(color: kBorderColor, height: 1, thickness: kBorderWidth),
            const SizedBox(height: 10),
            Text(
              'YOUR RANK',
              style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            _LeaderboardRow(rank: myRank, submission: submissions[myRank], isMe: true),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.submission, required this.isMe});

  final int rank;
  final LeagueSubmission submission;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            project: submission.projectRow,
            artistUsername: submission.artistUsername,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isMe ? kAccentTintColor : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                rank < _Leaderboard._medals.length ? _Leaderboard._medals[rank] : '#${rank + 1}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: submission.photoUrl.isEmpty
                  ? Container(
                      width: 36,
                      height: 36,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 16, color: Colors.black26),
                    )
                  : CachedNetworkImage(imageUrl: submission.photoUrl, width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMe ? 'You (@${submission.artistUsername})' : '@${submission.artistUsername}',
                style: GoogleFonts.chewy(fontSize: 14, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '⭐ ${submission.stars}',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF555555)),
            ),
          ],
        ),
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
                  '@${champion.artistUsername} — ⭐ ${champion.stars}',
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
    required this.canUnsubmit,
  });

  final LeagueSubmission submission;
  final bool isMine;
  final bool canUnsubmit;

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  bool _isUnsubmitting = false;

  Future<void> _confirmUnsubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kBorderColor, width: kBorderWidth),
        ),
        title: Text('Pulling "${widget.submission.projectTitle}"?', style: GoogleFonts.chewy(fontSize: 20)),
        content: Text(
          "Just checking — is this because you found a stronger piece to enter, or because you're being "
          "harsh on your own work? If it's the second one, leave it up.",
          style: GoogleFonts.chewy(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Never mind, keep it', style: GoogleFonts.chewy(color: Colors.black, fontSize: 15)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Pull it', style: GoogleFonts.chewy(color: Colors.red.shade700, fontSize: 15)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUnsubmitting = true);
    try {
      await ref.read(leagueRepositoryProvider).unsubmit(widget.submission.id);
      ref.invalidate(leagueSubmissionsProvider(widget.submission.leagueId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUnsubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unsubmit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    final canUnsubmit = widget.canUnsubmit;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: appHardCardDecoration(radius: 14, shadowOffset: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(
                          project: submission.projectRow,
                          artistUsername: submission.artistUsername,
                        ),
                      ),
                    ),
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
                ),
                if (canUnsubmit)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _isUnsubmitting ? null : _confirmUnsubmit,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: kBorderColor, width: kBorderWidth)),
                        ),
                        child: _isUnsubmitting
                            ? const SizedBox(
                                height: 10,
                                width: 10,
                                child: CircularProgressIndicator(strokeWidth: 2, color: kAccentColor),
                              )
                            : const Icon(Icons.close, size: 12, color: kAccentColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${submission.artistUsername}',
            style: GoogleFonts.chewy(fontSize: 14, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: kBorderColor, width: kBorderWidth),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                Text(
                  '${submission.stars}',
                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
