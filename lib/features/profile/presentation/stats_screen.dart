import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../feed/providers.dart';
import '../../league/providers.dart';
import '../data/stats_repository.dart';
import '../domain/stat_key.dart';
import '../providers.dart';

String _formatMinutes(double minutes) {
  final hours = minutes ~/ 60;
  final mins = (minutes % 60).round();
  if (hours > 0) return '${hours}h ${mins}m';
  return '${mins}m';
}

/// Public-facing Stats page for one user — reachable from their profile.
/// Only shows the stats the profile owner has opted into via
/// [StatsVisibilityScreen], resolved against real data (posts, followers,
/// views, time spent, streak, current league rank).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'Stats'),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.space16),
                child: Text('Profile not found.', style: appBodyStyle(fontSize: 16, color: kInkColor)),
              );
            }
            final visibleKeys = statKeysFromStorage(profile.visibleStats);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${profile.username}',
                    style: GoogleFonts.rubikMonoOne(fontSize: 16, color: kAccentColor),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(profile.displayName, style: appBodyStyle(fontSize: 22, color: kInkColor)),
                  const SizedBox(height: AppSpacing.space20),
                  if (visibleKeys.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space28, horizontal: AppSpacing.space20),
                      decoration: appHardCardDecoration(radius: 18),
                      child: Text(
                        "This artist hasn't chosen to show any stats yet.",
                        textAlign: TextAlign.center,
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
                      ),
                    )
                  else ...[
                    if (visibleKeys.any((key) => !key.isChart))
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          for (final key in visibleKeys.where((key) => !key.isChart))
                            _StatTile(statKey: key, userId: userId),
                        ],
                      ),
                    for (final key in visibleKeys.where((key) => key.isChart)) ...[
                      const SizedBox(height: AppSpacing.space20),
                      switch (key) {
                        StatKey.stageBreakdown => _StageBreakdownChart(userId: userId),
                        StatKey.difficultySpread => _DifficultySpreadChart(userId: userId),
                        StatKey.projectStatus => _ProjectStatusChart(userId: userId),
                        _ => const SizedBox.shrink(),
                      },
                    ],
                  ],
                ],
              ),
            );
          },
          loading: () => const AppSkeletonScreen(),
          error: (error, stack) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(profileByIdProvider(userId)),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends ConsumerWidget {
  const _StatTile({required this.statKey, required this.userId});

  final StatKey statKey;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostsProvider(userId)).value;
    final followCounts = ref.watch(followCountsProvider(userId)).value;
    final sessionStats = ref.watch(sessionStatsProvider(userId)).value;
    final projectStats = ref.watch(projectStatsProvider(userId)).value;
    final leagueRank = ref.watch(leagueRankProvider(userId)).value;

    final displayValue = switch (statKey) {
      StatKey.posts => posts == null ? '—' : formatCount(posts.length),
      StatKey.followers => followCounts == null ? '—' : formatCount(followCounts.followers),
      StatKey.following => followCounts == null ? '—' : formatCount(followCounts.following),
      StatKey.totalViews =>
        posts == null ? '—' : formatCount(posts.fold<int>(0, (sum, post) => sum + post.views)),
      StatKey.timeSpent => sessionStats == null ? '—' : _formatMinutes(sessionStats.totalMinutes),
      StatKey.sessionCount => sessionStats == null ? '—' : formatCount(sessionStats.sessionCount),
      StatKey.streak => sessionStats == null ? '—' : formatCount(sessionStats.currentStreakDays),
      StatKey.leagueRank => leagueRank == null ? '—' : '#$leagueRank',
      StatKey.averageDifficulty => sessionStats?.averageDifficulty == null
          ? '—'
          : '${sessionStats!.averageDifficulty!.toStringAsFixed(1)}/10',
      StatKey.finishedProjects => projectStats == null ? '—' : formatCount(projectStats.finishedCount),
      StatKey.longestSession => sessionStats == null ? '—' : _formatMinutes(sessionStats.longestMinutes),
      StatKey.averageSessionLength => sessionStats == null ? '—' : _formatMinutes(sessionStats.averageMinutes),
      StatKey.workStyle => sessionStats?.workStyle ?? '—',
      // Rendered as a full-width chart card, never as a grid tile — see
      // the StatsScreen build method, which filters chart stats out before
      // building _StatTile widgets.
      StatKey.stageBreakdown || StatKey.difficultySpread || StatKey.projectStatus => '—',
    };

    final isBadge = statKey == StatKey.workStyle;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(statKey.icon, size: 20, color: kAccentColor),
          const SizedBox(height: AppSpacing.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              displayValue,
              maxLines: 1,
              style: appBodyStyle(
                fontSize: isBadge ? 15 : 20,
                fontWeight: FontWeight.w900,
                color: kInkColor,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            statKey.label,
            style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMutedColor),
          ),
        ],
      ),
    );
  }
}

/// "Time per stage" bar chart — a public-facing equivalent of the Analytics
/// tab's free-tier stage breakdown (`_StageTimeRow` in
/// time_analytics_screen.dart), styled the same way: a single accent-color
/// bar per stage, scaled to the busiest stage.
class _StageBreakdownChart extends ConsumerWidget {
  const _StageBreakdownChart({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(stageMinutesProvider(userId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time per stage', style: appBodyStyle(fontSize: 18, color: kInkColor)),
        const SizedBox(height: AppSpacing.space8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
          decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
          child: stages == null
              ? const AppSkeletonBlock(height: 140)
              : Column(
                  children: [
                    for (final stage in stages) ...[
                      _StageBar(
                        stage: stage,
                        maxMinutes: stages.fold<double>(0, (max, s) => s.totalMinutes > max ? s.totalMinutes : max),
                      ),
                      if (stage != stages.last) const SizedBox(height: AppSpacing.space12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _StageBar extends StatelessWidget {
  const _StageBar({required this.stage, required this.maxMinutes});

  final StageMinutes stage;
  final double maxMinutes;

  @override
  Widget build(BuildContext context) {
    final fraction = maxMinutes == 0 ? 0.0 : (stage.totalMinutes / maxMinutes).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            stage.stage,
            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInkColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: kHairlineColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        SizedBox(
          width: 52,
          child: Text(
            stage.totalMinutes == 0 ? '—' : _formatMinutes(stage.totalMinutes),
            textAlign: TextAlign.right,
            style: appBodyStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: stage.totalMinutes == 0 ? kMutedColor : kAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Difficulty spread" histogram — session count per difficulty rating
/// (1-10), styled the same way as the Analytics tab's free-tier
/// `_DifficultyHistogram` (difficulty_analytics_screen.dart).
class _DifficultySpreadChart extends ConsumerWidget {
  const _DifficultySpreadChart({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histogram = ref.watch(difficultyHistogramProvider(userId)).value;
    final maxCount = histogram?.fold<int>(0, (max, c) => c > max ? c : max) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Difficulty spread', style: appBodyStyle(fontSize: 18, color: kInkColor)),
        const SizedBox(height: AppSpacing.space8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
          decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
          child: histogram == null
              ? const AppSkeletonBlock(height: 140)
              : SizedBox(
                  height: 100,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < histogram.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: maxCount == 0 ? 0 : histogram[i] / maxCount,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: histogram[i] == 0 ? kHairlineColor : kAccentColor,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Row(
                        children: [
                          for (var i = 1; i <= 10; i++)
                            Expanded(
                              child: Text(
                                '$i',
                                textAlign: TextAlign.center,
                                style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMutedColor),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// "Project status" chart — Finished vs In Progress, as a simple two-bar
/// comparison scaled to whichever count is larger.
class _ProjectStatusChart extends ConsumerWidget {
  const _ProjectStatusChart({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectStats = ref.watch(projectStatsProvider(userId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Project status', style: appBodyStyle(fontSize: 18, color: kInkColor)),
        const SizedBox(height: AppSpacing.space8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
          decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
          child: projectStats == null
              ? const AppSkeletonBlock(height: 140)
              : Column(
                  children: [
                    _StatusBar(
                      label: 'Finished',
                      count: projectStats.finishedCount,
                      maxCount: projectStats.totalCount,
                      color: kSuccessTextColor,
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    _StatusBar(
                      label: 'In progress',
                      count: projectStats.totalCount - projectStats.finishedCount,
                      maxCount: projectStats.totalCount,
                      color: kAccentColor,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.label, required this.count, required this.maxCount, required this.color});

  final String label;
  final int count;
  final int maxCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInkColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: kHairlineColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}
