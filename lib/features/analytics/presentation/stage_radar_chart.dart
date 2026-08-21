import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../providers.dart';

/// Radar/spider chart of average difficulty per stage. Shared between the
/// full Stage Difficulty (Pro) screen and the blurred preview teaser shown
/// on the free Difficulty screen.
class StageRadarChart extends StatelessWidget {
  const StageRadarChart({
    super.key,
    required this.stages,
    this.showStageNames = true,
    this.showValues = true,
    this.showChart = true,
    this.compareStages,
  });

  final List<StageDifficulty> stages;

  /// Stage-name labels (Sketching, Coloring, ...) — these are fixed
  /// categories, not real data, so they're safe to show even in a teaser.
  final bool showStageNames;

  /// The numeric value badges — the actual data, worth keeping hidden in a
  /// teaser. Text doesn't blur cleanly, so this is an on/off switch rather
  /// than something blurred along with the chart.
  final bool showValues;

  /// Set false to render only the (unblurred) labels — used to layer crisp
  /// labels on top of a separately-blurred chart-only render of this widget.
  final bool showChart;

  /// Optional second dataset (e.g. "older" data) drawn as a fainter outline
  /// polygon behind [stages], for a before/after comparison view.
  final List<StageDifficulty>? compareStages;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height / 2);
        final labelInset = _RadarChartPainter._labelInset;
        final radius = math.min(size.width, size.height) / 2 - labelInset;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (showChart)
              CustomPaint(
                size: size,
                painter: _RadarChartPainter(stages: stages, compareStages: compareStages),
              ),
            if (showStageNames)
              for (var i = 0; i < stages.length; i++)
                _radarLabel(stages[i].stage, i, stages.length, center, radius, labelInset),
            if (showValues)
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
          color: kSurfaceColor,
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
    // NB: previously `radius + labelInset - 6` — since radius is already
    // `half - labelInset`, that simplified to `half - 6`, placing labels
    // right at the outer edge regardless of labelInset, so they got clipped.
    // A fixed, smaller offset keeps real margin before the edge.
    final labelRadius = radius + 14;
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
  _RadarChartPainter({required this.stages, this.compareStages});

  final List<StageDifficulty> stages;
  final List<StageDifficulty>? compareStages;

  static const _rings = 4;
  static const _labelInset = 46.0;

  Path _polygonPath(List<StageDifficulty> data, Offset center, double radius, int count) {
    final path = Path();
    for (var i = 0; i < count; i++) {
      final average = i < data.length ? (data[i].average ?? 0) : 0.0;
      final normalized = (average / 10).clamp(0.0, 1.0);
      final angle = (-math.pi / 2) + (2 * math.pi * i / count);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius * normalized;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _labelInset;
    final count = stages.length;
    if (count < 3) return;

    final gridPaint = Paint()
      ..color = kHairlineColor
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

    // Comparison polygon (e.g. "older" data), drawn faint and behind.
    final compare = compareStages;
    if (compare != null) {
      final comparePaint = Paint()
        ..color = kInkColor.withValues(alpha: 0.26)
        ..style = PaintingStyle.fill;
      final compareStroke = Paint()
        ..color = kInkColor.withValues(alpha: 0.45)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final comparePath = _polygonPath(compare, center, radius, count);
      canvas.drawPath(comparePath, comparePaint);
      canvas.drawPath(comparePath, compareStroke);
    }

    // Data polygon — N/A stages plot at the center (0).
    final dataPaint = Paint()
      ..color = kAccentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final dataStroke = Paint()
      ..color = kAccentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dataPath = _polygonPath(stages, center, radius, count);
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
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) =>
      oldDelegate.stages != stages || oldDelegate.compareStages != compareStages;
}
