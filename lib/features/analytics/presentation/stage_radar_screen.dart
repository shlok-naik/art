import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'stage_radar_chart.dart';

/// Pro-only view of average difficulty per stage as a radar/spider chart —
/// gated behind the "Go Pro" box on the Analytics screen.
class StageRadarScreen extends ConsumerWidget {
  const StageRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(difficultyAnalyticsProvider);
    final insightsAsync = ref.watch(projectsProInsightsProvider);

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Stage Difficulty'),
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
                      style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Farther from the center = harder (1–10 scale).',
                      style: GoogleFonts.chewy(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black45,
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
                    insightsAsync.when(
                      data: (insights) => _ProInsights(insights: insights),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => AppErrorText('Failed to load insights: $error'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: AppErrorText('Failed to load analytics: $error'),
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

class _ProInsights extends StatelessWidget {
  const _ProInsights({required this.insights});

  final ProjectsProInsights insights;

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
          style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: appCardDecoration(),
          child: insights.topTools.isEmpty
              ? Text(
                  'Log a tool during a session to see this.',
                  style: GoogleFonts.chewy(fontSize: 14, color: Colors.black54),
                )
              : Column(
                  children: [
                    for (final tool in insights.topTools) ...[
                      _ToolBarRow(tool: tool, maxCount: insights.topTools.first.count),
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
          style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: appCardDecoration(),
          child: _ActivityHeatmap(days: insights.activity),
        ),
      ],
    );
  }
}

class _ToolBarRow extends StatelessWidget {
  const _ToolBarRow({required this.tool, required this.maxCount});

  final ToolUsage tool;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : tool.count / maxCount;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            tool.tool,
            style: GoogleFonts.chewy(fontSize: 14, fontWeight: FontWeight.bold),
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
                      color: Colors.grey.shade200,
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
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            '${tool.count}',
            textAlign: TextAlign.right,
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 14, color: kAccentColor),
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
          style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
