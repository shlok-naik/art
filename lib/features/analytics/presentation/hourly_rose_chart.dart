import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

const _clockNumbers = ['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];

/// Two 12-hour rose/coxcomb clocks (AM and PM) showing session activity by
/// hour of day, styled like an analogue clock face (tick marks, bold
/// numerals, black bezel) — minus the hands, since this shows a
/// distribution rather than a single time. Each wedge's length scales
/// relative to your single busiest hour across the whole day, so the two
/// clocks stay comparable to each other.
class HourlyRoseChart extends StatelessWidget {
  const HourlyRoseChart({super.key, required this.hourly});

  /// Session count by hour of day, index 0-23.
  final List<int> hourly;

  @override
  Widget build(BuildContext context) {
    final maxCount = hourly.fold<int>(0, (max, c) => c > max ? c : max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SingleClockRose(
            hours: hourly.sublist(0, 12),
            maxCount: maxCount,
            label: 'AM',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SingleClockRose(
            hours: hourly.sublist(12, 24),
            maxCount: maxCount,
            label: 'PM',
          ),
        ),
      ],
    );
  }
}

class _SingleClockRose extends StatelessWidget {
  const _SingleClockRose({required this.hours, required this.maxCount, required this.label});

  /// 12 session counts, index 0 = the clock's "12" position.
  final List<int> hours;
  final int maxCount;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: kBorderColor, width: 3),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final center = Offset(size.width / 2, size.height / 2);
                final faceRadius = math.min(size.width, size.height) / 2;
                final numberRadius = faceRadius - 20;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: size,
                      painter: _ClockRosePainter(hours: hours, maxCount: maxCount),
                    ),
                    for (var i = 0; i < 12; i++) _hourLabel(i, center, numberRadius),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _hourLabel(int index, Offset center, double radius) {
    final angle = (-math.pi / 2) + (2 * math.pi * index / 12);
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    return Positioned(
      left: x - 12,
      top: y - 10,
      width: 24,
      child: Text(
        _clockNumbers[index],
        textAlign: TextAlign.center,
        style: GoogleFonts.chewy(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }
}

class _ClockRosePainter extends CustomPainter {
  _ClockRosePainter({required this.hours, required this.maxCount});

  final List<int> hours;
  final int maxCount;

  static const _rings = 3;
  // Leaves room for the tick marks and the bold hour numbers outside the
  // data area.
  static const _dataInset = 38.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceRadius = math.min(size.width, size.height) / 2;
    final dataRadius = faceRadius - _dataInset;

    // Minute-style tick marks around the rim, like a real clock face.
    final majorTickPaint = Paint()
      ..color = kBorderColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;

    for (var tick = 0; tick < 60; tick++) {
      final isMajor = tick % 5 == 0;
      final angle = (-math.pi / 2) + (2 * math.pi * tick / 60);
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * (faceRadius - 4);
      final inner = center +
          Offset(math.cos(angle), math.sin(angle)) * (faceRadius - (isMajor ? 12 : 7));
      canvas.drawLine(inner, outer, isMajor ? majorTickPaint : minorTickPaint);
    }

    // Concentric guide rings for the data.
    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var ring = 1; ring <= _rings; ring++) {
      canvas.drawCircle(center, dataRadius * ring / _rings, gridPaint);
    }

    const sliceAngle = 2 * math.pi / 12;
    const minFraction = 0.1;

    for (var i = 0; i < 12; i++) {
      final count = hours[i];
      final fraction = maxCount == 0 ? 0.0 : count / maxCount;
      final wedgeRadius = dataRadius * (count == 0 ? minFraction : math.max(fraction, minFraction));
      // Wedge for hour i spans from that hour's mark to the next (e.g. "3"
      // covers 3:00-4:00), matching how people think of "the 3pm hour"
      // rather than centering the wedge on the number.
      final startAngle = (-math.pi / 2) + (i * sliceAngle);

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: wedgeRadius), startAngle, sliceAngle, false)
        ..close();

      final intensity = count == 0 ? 0.12 : 0.35 + (fraction * 0.65);
      canvas.drawPath(path, Paint()..color = kAccentColor.withValues(alpha: intensity));
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockRosePainter oldDelegate) =>
      oldDelegate.hours != hours || oldDelegate.maxCount != maxCount;
}
