import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../projects/providers.dart';
import '../../shell/main_shell.dart';
import '../domain/league.dart';
import '../providers.dart';
import 'league_project_sessions_screen.dart';
import 'submit_to_league_screen.dart';

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  // Guards against re-running the check on every rebuild of this widget
  // instance — the actual "already seen" state lives in LeagueSeenStore
  // (SharedPreferences), so it stays correct across screen instances too.
  bool _checkedForNewLeague = false;

  Future<void> _maybePromptNewLeague(League league) async {
    if (_checkedForNewLeague) return;
    _checkedForNewLeague = true;

    final seenStore = ref.read(leagueSeenStoreProvider);
    final lastSeenId = await seenStore.getLastSeenLeagueId();
    // null means this is the very first league this device has ever seen
    // (fresh install) — that's not a "restart", so just record it silently.
    final isRestart = lastSeenId != null && lastSeenId != league.id;

    await seenStore.markSeen(league.id);
    ref.invalidate(isCurrentLeagueUnseenProvider);
    if (!isRestart || !mounted) return;

    final wantsNewProject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kBorderColor, width: kBorderWidth),
        ),
        title: Text('New league: ${league.themeTitle}', style: GoogleFonts.chewy(fontSize: 20)),
        content: Text(
          'Do you want to create a new project for this league?',
          style: GoogleFonts.chewy(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: GoogleFonts.chewy(color: Colors.black, fontSize: 15)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes', style: GoogleFonts.chewy(color: kAccentColor, fontSize: 15)),
          ),
        ],
      ),
    );
    if (wantsNewProject != true || !mounted) return;

    try {
      final project = await ref.read(projectsRepositoryProvider).createProject({'title': league.themeTitle});
      ref.invalidate(projectsListProvider);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create project: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(currentLeagueProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'League'),
      body: SafeArea(
        child: leagueAsync.when(
          data: (league) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptNewLeague(league));
            return _LeagueBody(league: league);
          },
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

/// Which submissions grid the tab toggle below the "Submissions" header is
/// currently showing.
enum _SubmissionsTab { mine, everyone }

class _LeagueBody extends ConsumerStatefulWidget {
  const _LeagueBody({required this.league});

  final League league;

  @override
  ConsumerState<_LeagueBody> createState() => _LeagueBodyState();
}

class _LeagueBodyState extends ConsumerState<_LeagueBody> {
  _SubmissionsTab _tab = _SubmissionsTab.mine;

  @override
  Widget build(BuildContext context) {
    final league = widget.league;
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
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Vote for your favorite — no self-voting!',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
            ),
            const SizedBox(height: 12),
            _SubmissionsTabToggle(
              selected: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 12),
            submissionsAsync.when(
              data: (submissions) {
                final visible = submissions.where((s) {
                  return _tab == _SubmissionsTab.mine ? s.userId == myUserId : s.userId != myUserId;
                }).toList();

                if (visible.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: appHardCardDecoration(radius: 18),
                    child: Text(
                      _tab == _SubmissionsTab.mine
                          ? "You haven't submitted a project yet — tap Submit above."
                          : 'No other submissions yet.',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                    ),
                  );
                }
                final myVoteId = myVoteAsync.value;
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
                      hasVoted: myVoteId != null,
                      isMyVote: submission.id == myVoteId,
                      isVotingOpen: league.isVotingOpen,
                      isSubmissionOpen: league.isSubmissionOpen,
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
        ],
      ),
    );
  }
}

/// Live countdown to whichever boundary is next for [league]'s current
/// phase — submissions closing (Friday), voting closing (Sunday), or the
/// next league starting (Monday) — ticking every second so it stays
/// accurate without needing a pull-to-refresh.
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
    final league = widget.league;
    final (label, icon, target) = switch (league.phase) {
      LeaguePhase.submissions => ('Submissions close in', Icons.upload_outlined, league.submissionsCloseAt),
      LeaguePhase.votingOnly => ('Voting closes in', Icons.how_to_vote_outlined, league.votingClosesAt),
      LeaguePhase.ended => ('New league starts in', Icons.refresh, league.endsAt),
    };
    final remaining = target.difference(DateTime.now().toUtc());
    if (remaining.isNegative) {
      // Between ticks right at a phase boundary — next second's rebuild
      // will pick up the new phase.
      return const SizedBox(height: 76);
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kAccentColor, size: 16),
              const SizedBox(width: 6),
              Text(label, style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kAccentColor)),
            ],
          ),
          const SizedBox(height: 8),
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

/// Pill-shaped two-way toggle between "My Submissions" and "Everyone" —
/// there's no existing TabBar pattern elsewhere in the app, so this follows
/// the same hand-rolled hard-card look as the rest of the league screen
/// instead of introducing Flutter's TabBar/TabController.
class _SubmissionsTabToggle extends StatelessWidget {
  const _SubmissionsTabToggle({required this.selected, required this.onChanged});

  final _SubmissionsTab selected;
  final ValueChanged<_SubmissionsTab> onChanged;

  Widget _segment(String label, _SubmissionsTab tab) {
    final isSelected = tab == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? kAccentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: appBodyStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorderColor, width: kBorderWidth),
      ),
      child: Row(
        children: [
          _segment('My Submissions', _SubmissionsTab.mine),
          _segment('Everyone', _SubmissionsTab.everyone),
        ],
      ),
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
        MaterialPageRoute(builder: (_) => LeagueProjectSessionsScreen(submission: submission)),
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
              '${submission.votes} vote${submission.votes == 1 ? '' : 's'}',
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
    required this.isSubmissionOpen,
  });

  final LeagueSubmission submission;
  final bool isMine;
  final bool hasVoted;
  final bool isMyVote;
  final bool isVotingOpen;

  /// Whether submissions can still be added/withdrawn (Mon–Fri) — separate
  /// from [isVotingOpen], which stays true through the weekend after
  /// submissions have already locked.
  final bool isSubmissionOpen;

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  bool _isVoting = false;
  bool _isUnsubmitting = false;

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

  /// Tapping the heart on a submission you've already voted for retracts
  /// the vote instead of re-casting it (which would be a harmless no-op
  /// anyway, since it's the same submission).
  Future<void> _unvote() async {
    setState(() => _isVoting = true);
    try {
      await ref.read(leagueRepositoryProvider).unvote(widget.submission.leagueId);
      ref.invalidate(myLeagueVoteProvider(widget.submission.leagueId));
      ref.invalidate(leagueSubmissionsProvider(widget.submission.leagueId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unvote: $e')));
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

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
    final canVote = widget.isVotingOpen && !widget.isMine && !_isVoting;
    final canUnsubmit = widget.isMine && widget.isSubmissionOpen;

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
                      MaterialPageRoute(builder: (_) => LeagueProjectSessionsScreen(submission: submission)),
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
          InkWell(
            onTap: canVote ? (widget.isMyVote ? _unvote : _vote) : null,
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
