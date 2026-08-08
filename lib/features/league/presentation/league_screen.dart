import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../profile/providers.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../shell/main_shell.dart';
import '../domain/league.dart';
import '../domain/league_region.dart';
import '../providers.dart';
import 'league_voting_feed_screen.dart';
import 'region_picker_sheet.dart';
import 'submit_to_league_screen.dart';

class LeagueScreen extends ConsumerWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leagueAsync = ref.watch(currentLeagueProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppNavyHeader(title: 'League'),
          Expanded(
            child: leagueAsync.when(
              data: (league) => _LeagueBody(league: league),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  error is NoRegionSelectedException ? const _RegionPickerPrompt() : AppErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(currentLeagueProvider),
                  ),
            ),
          ),
        ],
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

/// Shown in place of the league body when the signed-in user hasn't picked
/// a region yet — regional leagues need one to know which week's league row
/// to materialize/join.
class _RegionPickerPrompt extends ConsumerStatefulWidget {
  const _RegionPickerPrompt();

  @override
  ConsumerState<_RegionPickerPrompt> createState() => _RegionPickerPromptState();
}

class _RegionPickerPromptState extends ConsumerState<_RegionPickerPrompt> {
  bool _isSaving = false;

  Future<void> _choose() async {
    final region = await pickLeagueRegion(context);
    if (region == null || !mounted) return;

    setState(() => _isSaving = true);
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    try {
      if (userId != null) {
        await ref.read(profileRepositoryProvider).updateRegion(userId: userId, region: region);
        ref.invalidate(currentProfileProvider);
        ref.invalidate(currentLeagueProvider);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text('Pick your region', style: appBodyStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              "Leagues run per-region so the leaderboard stays close — pick where you'd like to compete.",
              textAlign: TextAlign.center,
              style: appBodyStyle(fontSize: 14, color: kMutedColor),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _isSaving ? null : _choose,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: kAccentColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Choose region',
                        style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
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
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Submissions', style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAccentColor),
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
                            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kAccentColor),
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
              style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kMutedColor),
            ),
            const SizedBox(height: 12),
            submissionsAsync.when(
              data: (submissions) {
                final visible = submissions.where((s) => s.userId == myUserId).toList();

                if (visible.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: appFlatCardDecoration(),
                    child: Text(
                      "You haven't submitted a project yet — tap Submit above.",
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 13, color: kMutedColor),
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
      decoration: appFlatCardDecoration(color: kAccentTintColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "This season's theme",
                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kMutedColor),
              ),
              const Spacer(),
              Text(
                leagueRegionLabel(league.region),
                style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMutedColor),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(league.themeTitle, style: appHeadlineStyle()),
          const SizedBox(height: 2),
          Text(
            league.themeDescription,
            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
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
        decoration: appFlatCardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_outlined, color: kMutedColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Voting closed',
              style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kMutedColor),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: appFlatCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.league.phaseLabel,
            style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMutedColor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountdownUnit(value: days, label: 'days'),
              _CountdownUnit(value: hours, label: 'hrs'),
              _CountdownUnit(value: minutes, label: 'min'),
              _CountdownUnit(value: seconds, label: 'sec'),
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
        Text(
          value.toString().padLeft(2, '0'),
          style: appBodyStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(label, style: appBodyStyle(fontSize: 10, color: kMutedColor)),
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
      decoration: appFlatCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Current standings', style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _LeaderboardRow(rank: i, submission: top[i], isMe: i == myRank),
          ],
          if (myRank >= 0 && !myRowShownInTop) ...[
            const SizedBox(height: 12),
            const Divider(color: kHairlineColor, height: 1, thickness: 1),
            const SizedBox(height: 10),
            Text(
              'Your rank',
              style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMutedColor),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isMe ? kAccentTintColor : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                rank < _Leaderboard._medals.length ? _Leaderboard._medals[rank] : '#${rank + 1}',
                style: const TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: submission.photoUrl.isEmpty
                  ? Container(
                      width: 34,
                      height: 34,
                      color: kHairlineColor,
                      child: const Icon(Icons.image_not_supported, size: 16, color: kMutedColor),
                    )
                  : CachedNetworkImage(imageUrl: submission.photoUrl, width: 34, height: 34, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMe ? 'You (@${submission.artistUsername})' : '@${submission.artistUsername}',
                style: appBodyStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '★ ${submission.stars}',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
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
      decoration: appFlatCardDecoration(),
      child: Row(
        children: [
          const AppIcon(AppIcons.trophy, size: 30, strokeWidth: 1.6),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Last season's champion", style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(
                  '@${champion.artistUsername} · ★ ${champion.stars}',
                  style: appBodyStyle(fontSize: 12, color: kMutedColor),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Pulling "${widget.submission.projectTitle}"?',
          style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Just checking — is this because you found a stronger piece to enter, or because you're being "
          "harsh on your own work? If it's the second one, leave it up.",
          style: appBodyStyle(fontSize: 14, color: kMutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Never mind, keep it', style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Pull it',
              style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red.shade700),
            ),
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
      padding: const EdgeInsets.all(8),
      decoration: appFlatCardDecoration(radius: 14),
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
                              color: kHairlineColor,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported, size: 24, color: kMutedColor),
                            )
                          : CachedNetworkImage(
                              imageUrl: submission.photoUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(color: kSurfaceColor),
                              errorWidget: (context, url, error) => Container(
                                color: kHairlineColor,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported, size: 24, color: kMutedColor),
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
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isUnsubmitting
                            ? const SizedBox(
                                height: 10,
                                width: 10,
                                child: CircularProgressIndicator(strokeWidth: 2, color: kAccentColor),
                              )
                            : const AppIcon(AppIcons.x, size: 10, color: kAccentColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${submission.artistUsername}',
            style: appBodyStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '★ ${submission.stars}',
              textAlign: TextAlign.center,
              style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
