import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/sparkline.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';

/// Pro-only view of average difficulty per stage as a radar/spider chart —
/// gated behind the "Go Pro" box on the Analytics screen.
class StageRadarScreen extends ConsumerWidget {
  const StageRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(difficultyAnalyticsProvider);
    final progressAsync = ref.watch(progressOverTimeProvider);

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
                    const SizedBox(height: 20),
                    progressAsync.when(
                      data: (progress) => _ProgressPreviewCard(progress: progress),
                      loading: () => const SizedBox.shrink(),
                      error: (error, _) => AppErrorText('Growth card failed to load: $error'),
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

/// Percent change between the average of the first half of [values] and
/// the average of the second half — a simple, readable "trending up/down"
/// signal. Falls back to first-vs-last when there aren't enough points for
/// a stable half-split. Returns null when there's nothing meaningful to
/// compare (fewer than 2 points, or a zero baseline).
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

class _ProgressPreviewCard extends StatelessWidget {
  const _ProgressPreviewCard({required this.progress});

  final ProgressOverTime progress;

  @override
  Widget build(BuildContext context) {
    if (progress.difficultyTrend.isEmpty && progress.durationTrendMinutes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: kAccentColor, size: 28),
              const SizedBox(width: 10),
              Text(
                'Your Growth',
                style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'See how you\'re trending across every project.',
            style: GoogleFonts.chewy(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          if (progress.difficultyTrend.isNotEmpty)
            _TrendRow(
              label: 'Tackling harder work',
              values: progress.difficultyTrend,
              higherIsBetter: true,
            ),
          if (progress.difficultyTrend.isNotEmpty && progress.durationTrendMinutes.isNotEmpty)
            const SizedBox(height: 12),
          if (progress.durationTrendMinutes.isNotEmpty)
            _TrendRow(
              label: 'Getting faster',
              values: progress.durationTrendMinutes,
              higherIsBetter: false,
            ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.label, required this.values, required this.higherIsBetter});

  final String label;
  final List<double> values;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final delta = _trendDeltaPercent(values);
    final isImprovement = delta == null ? null : (higherIsBetter ? delta > 0 : delta < 0);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              if (values.length > 1)
                Sparkline(values: values, width: 120, height: 28, color: kAccentColor),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (delta != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isImprovement ?? false) ? kAccentColor : Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}%',
              style: GoogleFonts.chewy(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: (isImprovement ?? false) ? Colors.white : Colors.black54,
              ),
            ),
          ),
      ],
    );
  }
}
