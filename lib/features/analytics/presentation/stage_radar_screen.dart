import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';

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
                        child: _StageRadarChart(stages: analytics.perStage),
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

class _StageRadarChart extends StatelessWidget {
  const _StageRadarChart({required this.stages});

  final List<StageDifficulty> stages;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height / 2);
        final labelInset = 34.0;
        final radius = math.min(size.width, size.height) / 2 - labelInset;

        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: size,
              painter: _RadarChartPainter(stages: stages),
            ),
            for (var i = 0; i < stages.length; i++)
              _radarLabel(stages[i].stage, i, stages.length, center, radius, labelInset),
            for (var i = 0; i < stages.length; i++)
              _radarValueLabel(stages[i].average, i, stages.length, center, radius),
          ],
        );
      },
    );
  }

  Widget _radarValueLabel(double? average, int index, int total, Offset center, double radius) {
    if (average == null) return const SizedBox.shrink();

    final angle = (-math.pi / 2) + (2 * math.pi * index / total);
    final normalized = (average / 10).clamp(0.0, 1.0);
    // Sit just outside the data point, well short of the stage-name ring.
    final valueRadius = radius * normalized + 12;
    final x = center.dx + valueRadius * math.cos(angle);
    final y = center.dy + valueRadius * math.sin(angle);

    return Positioned(
      left: x - 16,
      top: y - 9,
      width: 32,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          average.toStringAsFixed(1),
          textAlign: TextAlign.center,
          style: GoogleFonts.chewy(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: kAccentColor,
          ),
        ),
      ),
    );
  }

  Widget _radarLabel(
    String label,
    int index,
    int total,
    Offset center,
    double radius,
    double labelInset,
  ) {
    final angle = (-math.pi / 2) + (2 * math.pi * index / total);
    final labelRadius = radius + labelInset - 6;
    final x = center.dx + labelRadius * math.cos(angle);
    final y = center.dy + labelRadius * math.sin(angle);

    return Positioned(
      left: x - 40,
      top: y - 10,
      width: 80,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.chewy(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter({required this.stages});

  final List<StageDifficulty> stages;

  static const _rings = 4;
  static const _labelInset = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _labelInset;
    final count = stages.length;
    if (count < 3) return;

    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Concentric rings.
    for (var ring = 1; ring <= _rings; ring++) {
      final ringRadius = radius * ring / _rings;
      final path = Path();
      for (var i = 0; i <= count; i++) {
        final angle = (-math.pi / 2) + (2 * math.pi * (i % count) / count);
        final point = center + Offset(math.cos(angle), math.sin(angle)) * ringRadius;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Spokes.
    for (var i = 0; i < count; i++) {
      final angle = (-math.pi / 2) + (2 * math.pi * i / count);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(center, point, gridPaint);
    }

    // Data polygon — N/A stages plot at the center (0).
    final dataPaint = Paint()
      ..color = kAccentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final dataStroke = Paint()
      ..color = kAccentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dataPath = Path();
    for (var i = 0; i < count; i++) {
      final average = stages[i].average ?? 0;
      final normalized = (average / 10).clamp(0.0, 1.0);
      final angle = (-math.pi / 2) + (2 * math.pi * i / count);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius * normalized;
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStroke);

    // Data point dots.
    final dotPaint = Paint()..color = kAccentColor;
    for (var i = 0; i < count; i++) {
      final average = stages[i].average ?? 0;
      final normalized = (average / 10).clamp(0.0, 1.0);
      final angle = (-math.pi / 2) + (2 * math.pi * i / count);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius * normalized;
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) => oldDelegate.stages != stages;
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
