import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/sparkline.dart';
import '../../pro/presentation/pro_screen.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../projects/presentation/session_details_form.dart' show kSessionStages;
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'stage_radar_chart.dart';

class DifficultyAnalyticsScreen extends ConsumerWidget {
  const DifficultyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(difficultyAnalyticsProvider);
    final timeAsync = ref.watch(timeAnalyticsProvider);

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Difficulty'),
        body: SafeArea(
          child: analyticsAsync.when(
            data: (analytics) {
              if (analytics.perProject.isEmpty) {
                return Center(
                  child: Text(
                    'No difficulty data yet — log a session to see analytics here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chewy(fontSize: 16),
                  ),
                );
              }
              final hardest = analytics.perProject.first;
              final rest = analytics.perProject.skip(1).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hardest project',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    _HardestProjectHero(
                      project: hardest,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(project: hardest.project),
                        ),
                      ),
                    ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Other projects',
                        style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      for (final project in rest) ...[
                        _ProjectDifficultyRow(
                          project: project,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(project: project.project),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Difficulty distribution',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: appCardDecoration(),
                      child: _DifficultyHistogram(histogram: analytics.histogram),
                    ),
                    const SizedBox(height: 20),
                    timeAsync.maybeWhen(
                      data: (time) {
                        final callout = _difficultyVsSpeedCallout(analytics.perStage, time.perStage);
                        if (callout == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _CalloutCard(text: callout),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    Text(
                      'Average difficulty per stage',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: appCardDecoration(),
                      child: Column(
                        children: [
                          for (final stage in analytics.perStage) ...[
                            _StageBarRow(stage: stage),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RadarChartTeaser(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProScreen()),
                      ),
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

class _HardestProjectHero extends StatelessWidget {
  const _HardestProjectHero({required this.project, required this.onTap});

  final ProjectDifficulty project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kAccentColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor, width: kBorderWidth),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.title,
                    style: GoogleFonts.chewy(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${project.sessionCount} session${project.sessionCount == 1 ? '' : 's'}',
                    style: GoogleFonts.chewy(fontSize: 14, color: Colors.white70),
                  ),
                  if (project.history.length > 1) ...[
                    const SizedBox(height: 10),
                    Sparkline(
                      values: project.history,
                      width: 140,
                      height: 32,
                      color: Colors.white,
                      minValue: 1,
                      maxValue: 10,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              project.average.toStringAsFixed(1),
              style: GoogleFonts.chewy(
                fontWeight: FontWeight.bold,
                fontSize: 40,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDifficultyRow extends StatelessWidget {
  const _ProjectDifficultyRow({required this.project, required this.onTap});

  final ProjectDifficulty project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: appCardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.title,
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${project.sessionCount} session${project.sessionCount == 1 ? '' : 's'}',
                    style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (project.history.length > 1)
              Sparkline(
                values: project.history,
                width: 60,
                height: 24,
                color: kAccentColor,
                minValue: 1,
                maxValue: 10,
              ),
            const SizedBox(width: 12),
            Text(
              '${project.average.toStringAsFixed(1)} / 10',
              style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18, color: kAccentColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageBarRow extends StatelessWidget {
  const _StageBarRow({required this.stage});

  final StageDifficulty stage;

  @override
  Widget build(BuildContext context) {
    final average = stage.average;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            stage.stage,
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
                    width: average == null ? 0 : constraints.maxWidth * (average / 10).clamp(0, 1),
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
          width: 46,
          child: Text(
            average == null ? 'N/A' : average.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: GoogleFonts.chewy(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: average == null ? Colors.black38 : kAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// A short "your hardest stage is also your slowest" style insight,
/// combining difficulty and time-per-stage data that's already computed
/// elsewhere. Null if there isn't enough data to say anything meaningful.
String? _difficultyVsSpeedCallout(List<StageDifficulty> difficulty, List<StageTime> time) {
  StageDifficulty? hardest;
  for (final stage in difficulty) {
    if (stage.average == null) continue;
    if (hardest == null || stage.average! > hardest.average!) hardest = stage;
  }

  StageTime? slowest;
  for (final stage in time) {
    if (stage.averageMinutes == null) continue;
    if (slowest == null || stage.averageMinutes! > slowest.averageMinutes!) slowest = stage;
  }

  if (hardest == null || slowest == null) return null;

  if (hardest.stage == slowest.stage) {
    return '${hardest.stage} is both your hardest and slowest stage.';
  }
  return '${hardest.stage} is your hardest stage — ${slowest.stage} takes you the longest.';
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kAccentTintColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor, width: kBorderWidth),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: kAccentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.chewy(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DifficultyHistogram extends StatelessWidget {
  const _DifficultyHistogram({required this.histogram});

  /// Session count per difficulty rating, index 0 = difficulty 1.
  final List<int> histogram;

  @override
  Widget build(BuildContext context) {
    final maxCount = histogram.fold<int>(0, (max, c) => c > max ? c : max);
    return SizedBox(
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
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: maxCount == 0 ? 0 : histogram[i] / maxCount,
                        child: Container(
                          decoration: BoxDecoration(
                            color: histogram[i] == 0 ? Colors.grey.shade200 : kAccentColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 1; i <= 10; i++)
                Expanded(
                  child: Text(
                    '$i',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chewy(fontSize: 11, color: Colors.black45),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sample values (not the user's real data) with a deliberately wide spread
/// so the radar chart's shape reads clearly through the blur.
final _sampleStages = [
  for (var i = 0; i < kSessionStages.length; i++)
    StageDifficulty(stage: kSessionStages[i], average: _sampleValues[i % _sampleValues.length]),
];
const _sampleValues = [7.5, 3.0, 8.5, 4.5, 9.0, 2.5, 6.0, 5.0];

/// Blurred preview of the Pro-only stage radar chart, with a lock-and-CTA
/// overlay. Uses sample data (not the user's real numbers) so the shape is
/// legible without giving away real analytics for free.
class _RadarChartTeaser extends StatelessWidget {
  const _RadarChartTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: appCardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: IgnorePointer(
                    child: StageRadarChart(stages: _sampleStages),
                  ),
                ),
              ),
              Container(color: Colors.white.withValues(alpha: 0.35)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: kAccentColor, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'See your top tools and practice streak.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Go Pro',
                        style: GoogleFonts.chewy(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kAccentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

