import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
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
      style: GoogleFonts.chewy(color: kInkColor),
      child: Scaffold(
        appBar: appThemedAppBar(context, '👑 Pro-exclusive  Analytics'),
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
                        const Icon(Icons.workspace_premium, color: kAccentColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Difficulty by stage',
                          style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'See which stages are consistently hardest across all your projects.',
                      style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Farther from the center = harder (1–10 scale).',
                      style: GoogleFonts.chewy(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: kMutedColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: appCardDecoration(),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: StageRadarChart(stages: analytics.perStage),
                      ),
                    ),
                    const SizedBox(height: 24),
                    difficultyInsightsAsync.when(
                      data: (insights) => _DifficultyProInsights(insights: insights),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => AppErrorText('Failed to load insights: $error'),
                    ),
                    const SizedBox(height: 24),
                    insightsAsync.when(
                      data: (insights) => overviewAsync.when(
                        data: (overview) => _ProInsights(insights: insights, overview: overview),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => AppErrorText('Failed to load insights: $error'),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => AppErrorText('Failed to load insights: $error'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
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
              const Icon(Icons.workspace_premium, color: kAccentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Then vs. now',
                style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Older sessions (grey) vs. your more recent half (orange).',
            style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: appCardDecoration(),
            child: AspectRatio(
              aspectRatio: 1,
              child: StageRadarChart(stages: comparison.recent, compareStages: comparison.older),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (monthly.length >= 2) ...[
          Row(
            children: [
              const Icon(Icons.trending_up, color: kAccentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Growth curve',
                style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Average difficulty tackled per month.',
            style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: appCardDecoration(),
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
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: insights.growthPercent! >= 0 ? kAccentColor : Colors.black12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${insights.growthPercent! >= 0 ? '+' : ''}'
                          '${insights.growthPercent!.toStringAsFixed(0)}%',
                          style: GoogleFonts.chewy(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: insights.growthPercent! >= 0 ? Colors.white : kMutedColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      monthly.first.label,
                      style: GoogleFonts.chewy(fontSize: 12, color: kMutedColor),
                    ),
                    const Spacer(),
                    Text(
                      monthly.last.label,
                      style: GoogleFonts.chewy(fontSize: 12, color: kMutedColor),
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
            const Icon(Icons.workspace_premium, color: kAccentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Top tools',
              style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'What you reach for most across every session.',
          style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: appCardDecoration(),
          child: insights.topTools.isEmpty
              ? Text(
                  'Log a tool during a session to see this.',
                  style: GoogleFonts.chewy(fontSize: 14, color: kMutedColor),
                )
              : Column(
                  children: [
                    for (final tool in insights.topTools) ...[
                      ToolBarRow(tool: tool, maxCount: insights.topTools.first.count),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 24),
        Text(
          'Practice streak',
          style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          'Sessions logged over the last 12 weeks.',
          style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: appCardDecoration(),
          child: _ActivityHeatmap(days: insights.activity),
        ),
        const SizedBox(height: 24),
        Text(
          'When you work',
          style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          'Sessions started, by time of day.',
          style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: appCardDecoration(),
          child: HourlyRoseChart(
            hourly: insights.hourlyActivity,
            minutes: insights.hourlyMinutes,
          ),
        ),
        if (insights.durationTrendMinutes.length > 1) ...[
          const SizedBox(height: 24),
          Text(
            'Session length trend',
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Are your sessions getting longer or shorter?',
            style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: appCardDecoration(),
            child: _SessionLengthTrend(minutes: insights.durationTrendMinutes),
          ),
        ],
        if (overview.perProject.any((p) => p.createdAt != null)) ...[
          const SizedBox(height: 24),
          Text(
            'Project timeline',
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'When each project was active — see what overlapped.',
            style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: appCardDecoration(),
            child: _ProjectTimeline(projects: overview.perProject),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Needs attention',
          style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          "Unfinished projects you haven't touched in a while.",
          style: GoogleFonts.chewy(fontSize: 15, color: kMutedColor),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: appCardDecoration(),
          child: insights.needsAttention.isEmpty
              ? Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "No old unfinished projects right now!",
                        style: GoogleFonts.chewy(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (final project in insights.needsAttention) ...[
                      _NeedsAttentionRow(project: project),
                      const SizedBox(height: 12),
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
    if (count <= 0) return Colors.grey.shade200;
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
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: [
                      for (final day in week)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
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
        const SizedBox(height: 10),
        Text(
          '$activeDays active day${activeDays == 1 ? '' : 's'} in the last 12 weeks',
          style: GoogleFonts.chewy(fontSize: 13, color: kMutedColor),
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isShorter ? kAccentColor : Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
              style: GoogleFonts.chewy(
                fontWeight: FontWeight.bold,
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
                  style: GoogleFonts.chewy(fontSize: 13, fontWeight: FontWeight.bold),
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
                            color: Colors.grey.shade200,
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
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Text(_shortDate(rangeStart), style: GoogleFonts.chewy(fontSize: 11, color: kMutedColor)),
            const Spacer(),
            Text(_shortDate(now), style: GoogleFonts.chewy(fontSize: 11, color: kMutedColor)),
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
        const Icon(Icons.hourglass_bottom, color: kAccentColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            project.title,
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${project.daysSinceActive}d idle',
          style: GoogleFonts.chewy(fontSize: 13, color: kMutedColor),
        ),
      ],
    );
  }
}
