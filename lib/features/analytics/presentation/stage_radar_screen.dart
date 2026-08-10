import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/sparkline.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'hourly_rose_chart.dart';
import 'stage_radar_chart.dart';
import 'tool_bar_row.dart';

/// Pro-only view of average difficulty per stage as a radar/spider chart —
/// gated behind the "Go Pro" box on the Analytics screen.
class StageRadarScreen extends ConsumerWidget {
  const StageRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(difficultyAnalyticsProvider);
    final insightsAsync = ref.watch(projectsProInsightsProvider);
    final difficultyInsightsAsync = ref.watch(difficultyProInsightsProvider);
    final overviewAsync = ref.watch(projectsOverviewProvider);

    return DefaultTextStyle(
      style: appBodyStyle(color: kInkColor),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(
          context,
          'Pro analytics',
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.space16),
              child: Center(child: AppIcon(AppIcons.crown, size: 18, color: kAccentColor)),
            ),
          ],
        ),
        body: SafeArea(
          child: analyticsAsync.when(
            data: (analytics) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(AppIcons.crown, size: 22, color: kAccentColor),
                        const SizedBox(width: AppSpacing.space8),
                        Text(
                          'Difficulty by stage',
                          style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'See which stages are consistently hardest across all your projects.',
                      style: appBodyStyle(fontSize: 15, color: kMutedColor),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'Farther from the center = harder (1–10 scale).',
                      style: appBodyStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: kMutedColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: appFlatCardDecoration(),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: StageRadarChart(stages: analytics.perStage),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    difficultyInsightsAsync.when(
                      data: (insights) => _DifficultyProInsights(insights: insights),
                      loading: () => const AppSkeletonBlock(height: 80),
                      error: (error, _) => AppErrorText('Failed to load insights: $error'),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    insightsAsync.when(
                      data: (insights) => overviewAsync.when(
                        data: (overview) => _ProInsights(insights: insights, overview: overview),
                        loading: () => const AppSkeletonBlock(height: 80),
                        error: (error, _) => AppErrorText('Failed to load insights: $error'),
                      ),
                      loading: () => const AppSkeletonBlock(height: 80),
                      error: (error, _) => AppErrorText('Failed to load insights: $error'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const AppSkeletonScreen(),
            error: (error, _) => AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(difficultyAnalyticsProvider),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: -1,
          onTap: (i) => goToMainTab(context, ref, i),
        ),
      ),
    );
  }
}

class _DifficultyProInsights extends StatelessWidget {
  const _DifficultyProInsights({required this.insights});

  final DifficultyProInsights insights;

  @override
  Widget build(BuildContext context) {
    final comparison = insights.radarComparison;
    final monthly = insights.monthly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comparison != null) ...[
          Row(
            children: [
              const AppIcon(AppIcons.crown, size: 22, color: kAccentColor),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Then vs. now',
                style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Older sessions (grey) vs. your more recent half (orange).',
            style: appBodyStyle(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: appFlatCardDecoration(),
            child: AspectRatio(
              aspectRatio: 1,
              child: StageRadarChart(stages: comparison.recent, compareStages: comparison.older),
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
        ],
        if (monthly.length >= 2) ...[
          Row(
            children: [
              const AppIcon(AppIcons.trendUp, size: 22, color: kAccentColor),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Growth curve',
                style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Average difficulty tackled per month.',
            style: appBodyStyle(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: appFlatCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Sparkline(
                        values: [for (final m in monthly) m.average],
                        width: double.infinity,
                        height: 40,
                        color: kAccentColor,
                        minValue: 1,
                        maxValue: 10,
                      ),
                    ),
                    if (insights.growthPercent != null) ...[
                      const SizedBox(width: AppSpacing.space12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space4),
                        decoration: BoxDecoration(
                          color: insights.growthPercent! >= 0 ? kAccentColor : kHairlineColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${insights.growthPercent! >= 0 ? '+' : ''}'
                          '${insights.growthPercent!.toStringAsFixed(0)}%',
                          style: appBodyStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: insights.growthPercent! >= 0 ? Colors.white : kMutedColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    Text(
                      monthly.first.label,
                      style: appBodyStyle(fontSize: 12, color: kMutedColor),
                    ),
                    const Spacer(),
                    Text(
                      monthly.last.label,
                      style: appBodyStyle(fontSize: 12, color: kMutedColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ProInsights extends StatelessWidget {
  const _ProInsights({required this.insights, required this.overview});

  final ProjectsProInsights insights;
  final ProjectsOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppIcon(AppIcons.crown, size: 22, color: kAccentColor),
            const SizedBox(width: AppSpacing.space8),
            Text(
              'Top tools',
              style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'What you reach for most across every session.',
          style: appBodyStyle(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: AppSpacing.space12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
          decoration: appFlatCardDecoration(),
          child: insights.topTools.isEmpty
              ? Text(
                  'Log a tool during a session to see this.',
                  style: appBodyStyle(fontSize: 14, color: kMutedColor),
                )
              : Column(
                  children: [
                    for (final tool in insights.topTools) ...[
                      ToolBarRow(tool: tool, maxCount: insights.topTools.first.count),
                      const SizedBox(height: AppSpacing.space12),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.space24),
        Text(
          'Practice streak',
          style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Sessions logged over the last 12 weeks.',
          style: appBodyStyle(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: AppSpacing.space12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: appFlatCardDecoration(),
          child: _ActivityHeatmap(days: insights.activity),
        ),
        const SizedBox(height: AppSpacing.space24),
        Text(
          'When you work',
          style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Sessions started, by time of day.',
          style: appBodyStyle(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: AppSpacing.space12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: appFlatCardDecoration(),
          child: HourlyRoseChart(
            hourly: insights.hourlyActivity,
            minutes: insights.hourlyMinutes,
          ),
        ),
        if (insights.durationTrendMinutes.length > 1) ...[
          const SizedBox(height: AppSpacing.space24),
          Text(
            'Session length trend',
            style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Are your sessions getting longer or shorter?',
            style: appBodyStyle(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: appFlatCardDecoration(),
            child: _SessionLengthTrend(minutes: insights.durationTrendMinutes),
          ),
        ],
        if (overview.perProject.any((p) => p.createdAt != null)) ...[
          const SizedBox(height: AppSpacing.space24),
          Text(
            'Project timeline',
            style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'When each project was active — see what overlapped.',
            style: appBodyStyle(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: AppSpacing.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: appFlatCardDecoration(),
            child: _ProjectTimeline(projects: overview.perProject),
          ),
        ],
        const SizedBox(height: AppSpacing.space24),
        Text(
          'Needs attention',
          style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          "Unfinished projects you haven't touched in a while.",
          style: appBodyStyle(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: AppSpacing.space12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
          decoration: appFlatCardDecoration(),
          child: insights.needsAttention.isEmpty
              ? Row(
                  children: [
                    const AppIcon(AppIcons.checkCircle, size: 20, color: kSuccessTextColor),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Text(
                        "No old unfinished projects right now!",
                        style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (final project in insights.needsAttention) ...[
                      _NeedsAttentionRow(project: project),
                      const SizedBox(height: AppSpacing.space12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}


class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.days});

  final List<ActivityDay> days;

  Color _colorFor(int count) {
    if (count <= 0) return kHairlineColor;
    if (count == 1) return kAccentColor.withValues(alpha: 0.35);
    if (count <= 3) return kAccentColor.withValues(alpha: 0.65);
    return kAccentColor;
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = days.where((d) => d.sessionCount > 0).length;
    final weeks = <List<ActivityDay>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, math.min(i + 7, days.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final week in weeks)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space4),
                  child: Column(
                    children: [
                      for (final day in week)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.space4),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _colorFor(day.sessionCount),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        Text(
          '$activeDays active day${activeDays == 1 ? '' : 's'} in the last 12 weeks',
          style: appBodyStyle(fontSize: 13, color: kMutedColor),
        ),
      ],
    );
  }
}

/// Percent change between the average of the first half of [values] and
/// the average of the second half — falls back to first-vs-last when
/// there aren't enough points for a stable half-split.
double? _trendDeltaPercent(List<double> values) {
  if (values.length < 2) return null;

  if (values.length < 4) {
    final first = values.first;
    final last = values.last;
    if (first == 0) return null;
    return (last - first) / first * 100;
  }

  final mid = values.length ~/ 2;
  final firstHalf = values.sublist(0, mid);
  final secondHalf = values.sublist(mid);
  final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
  final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
  if (firstAvg == 0) return null;
  return (secondAvg - firstAvg) / firstAvg * 100;
}

class _SessionLengthTrend extends StatelessWidget {
  const _SessionLengthTrend({required this.minutes});

  final List<double> minutes;

  @override
  Widget build(BuildContext context) {
    final delta = _trendDeltaPercent(minutes);
    // Shorter sessions read as "more efficient", so a negative delta is
    // the "improvement" framing here.
    final isShorter = delta != null && delta < 0;

    return Row(
      children: [
        Expanded(
          child: Sparkline(values: minutes, width: double.infinity, height: 40, color: kAccentColor),
        ),
        if (delta != null) ...[
          const SizedBox(width: AppSpacing.space12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space4),
            decoration: BoxDecoration(
              color: isShorter ? kAccentColor : kHairlineColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
              style: appBodyStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isShorter ? Colors.white : kMutedColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProjectTimeline extends StatelessWidget {
  const _ProjectTimeline({required this.projects});

  final List<ProjectStats> projects;

  @override
  Widget build(BuildContext context) {
    final withDates = projects.where((p) => p.createdAt != null).toList();
    if (withDates.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final rangeStart = withDates.map((p) => p.createdAt!).reduce((a, b) => a.isBefore(b) ? a : b);
    final rangeEnd = withDates
        .map((p) => p.lastActiveAt ?? p.createdAt!)
        .fold(rangeStart, (latest, d) => d.isAfter(latest) ? d : latest);
    final totalSpan = rangeEnd.difference(rangeStart).inMilliseconds;

    return Column(
      children: [
        for (final project in withDates) ...[
          Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  project.title,
                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final end = project.lastActiveAt ?? project.createdAt!;
                    final startFraction = totalSpan == 0
                        ? 0.0
                        : project.createdAt!.difference(rangeStart).inMilliseconds / totalSpan;
                    final endFraction =
                        totalSpan == 0 ? 1.0 : end.difference(rangeStart).inMilliseconds / totalSpan;
                    final barWidth = math.max(
                      (endFraction - startFraction) * constraints.maxWidth,
                      6.0,
                    );
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: kHairlineColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Positioned(
                          left: startFraction * constraints.maxWidth,
                          child: Container(
                            height: 10,
                            width: barWidth,
                            decoration: BoxDecoration(
                              color: kAccentColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
        ],
        Row(
          children: [
            Text(_shortDate(rangeStart), style: appBodyStyle(fontSize: 11, color: kMutedColor)),
            const Spacer(),
            Text(_shortDate(now), style: appBodyStyle(fontSize: 11, color: kMutedColor)),
          ],
        ),
      ],
    );
  }
}

const _timelineMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDate(DateTime date) => '${_timelineMonths[date.month - 1]} ${date.day}';

class _NeedsAttentionRow extends StatelessWidget {
  const _NeedsAttentionRow({required this.project});

  final NeedsAttentionProject project;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppIcon(AppIcons.hourglass, size: 18, color: kAccentColor),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Text(
            project.title,
            style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${project.daysSinceActive}d idle',
          style: appBodyStyle(fontSize: 13, color: kMutedColor),
        ),
      ],
    );
  }
}
