import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

const _clockNumbers = ['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];

// Leaves room for the tick marks and the bold hour numbers outside the data
// area. Shared between the painter (drawing) and the widget (hit-testing).
const _dataInset = 38.0;

/// Two 12-hour rose/coxcomb clocks (AM, stacked above PM) showing session
/// activity by hour of day, styled like an analogue clock face (tick marks,
/// bold numerals, black bezel) — minus the hands, since this shows a
/// distribution rather than a single time. Stacked rather than side by side
/// so each clock gets the full width — bigger, more exaggerated wedges.
/// Each wedge's length scales relative to your single busiest hour across
/// the whole day, so the two clocks stay comparable to each other. Hover
/// (desktop) or tap (touch) a wedge to see the time spent working during
/// that hour — on touch, the tooltip stays until you tap elsewhere.
class HourlyRoseChart extends StatelessWidget {
  const HourlyRoseChart({super.key, required this.hourly, required this.minutes});

  /// Session count by hour of day, index 0-23.
  final List<int> hourly;

  /// Total minutes spent working, index 0-23.
  final List<double> minutes;

  @override
  Widget build(BuildContext context) {
    final maxCount = hourly.fold<int>(0, (max, c) => c > max ? c : max);
    // Stacked rather than side by side so each clock gets the full available
    // width — bigger wedges, easier to read and to tap accurately.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SingleClockRose(
          hours: hourly.sublist(0, 12),
          minutes: minutes.sublist(0, 12),
          maxCount: maxCount,
          label: 'AM',
        ),
        const SizedBox(height: 20),
        _SingleClockRose(
          hours: hourly.sublist(12, 24),
          minutes: minutes.sublist(12, 24),
          maxCount: maxCount,
          label: 'PM',
        ),
      ],
    );
  }
}

class _SingleClockRose extends StatefulWidget {
  const _SingleClockRose({
    required this.hours,
    required this.minutes,
    required this.maxCount,
    required this.label,
  });

  /// 12 session counts, index 0 = the clock's "12" position.
  final List<int> hours;

  /// 12 minute totals, matching [hours].
  final List<double> minutes;
  final int maxCount;
  final String label;

  @override
  State<_SingleClockRose> createState() => _SingleClockRoseState();
}

class _SingleClockRoseState extends State<_SingleClockRose> {
  int? _hoveredIndex;
  Offset? _hoverPosition;

  void _updateHover(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceRadius = math.min(size.width, size.height) / 2;
    final dataRadius = faceRadius - _dataInset;

    final delta = localPosition - center;
    final distance = delta.distance;
    if (distance > dataRadius) {
      if (_hoveredIndex != null) setState(() => _hoveredIndex = null);
      return;
    }

    final angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    final normalized = (angle + 2 * math.pi) % (2 * math.pi);
    const sliceAngle = 2 * math.pi / 12;
    final index = (normalized / sliceAngle).floor() % 12;

    setState(() {
      _hoveredIndex = index;
      _hoverPosition = localPosition;
    });
  }

  void _clearHover() {
    if (_hoveredIndex != null) setState(() => _hoveredIndex = null);
  }

  String _hourLabel(int index) {
    final displayHour = _clockNumbers[index];
    return '$displayHour ${widget.label}';
  }

  String _formatMinutes(double totalMinutes) {
    final minutes = totalMinutes.round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label,
          style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15, color: kInkColor),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kSurfaceColor,
              border: Border.all(color: kBorderColor, width: 3),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final center = Offset(size.width / 2, size.height / 2);
                final faceRadius = math.min(size.width, size.height) / 2;
                final numberRadius = faceRadius - 20;

                return MouseRegion(
                  onHover: (event) => _updateHover(event.localPosition, size),
                  onExit: (_) => _clearHover(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // Tapping a wedge selects it and the tooltip stays put
                    // (rather than flashing and vanishing on release) since
                    // there's no hover on touch devices — tap elsewhere on
                    // the face, or outside the data ring, to dismiss it.
                    onTapDown: (details) => _updateHover(details.localPosition, size),
                    onTapCancel: _clearHover,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: size,
                          painter: _ClockRosePainter(
                            hours: widget.hours,
                            maxCount: widget.maxCount,
                            hoveredIndex: _hoveredIndex,
                          ),
                        ),
                        for (var i = 0; i < 12; i++) _buildHourLabel(i, center, numberRadius),
                        if (_hoveredIndex != null && _hoverPosition != null)
                          _buildTooltip(_hoveredIndex!, size),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourLabel(int index, Offset center, double radius) {
    final angle = (-math.pi / 2) + (2 * math.pi * index / 12);
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    final isHovered = _hoveredIndex == index;
    return Positioned(
      left: x - 12,
      top: y - 10,
      width: 24,
      child: Text(
        _clockNumbers[index],
        textAlign: TextAlign.center,
        style: GoogleFonts.chewy(
          fontSize: isHovered ? 18 : 16,
          fontWeight: FontWeight.bold,
          color: isHovered ? kAccentColor : kInkColor,
        ),
      ),
    );
  }

  Widget _buildTooltip(int index, Size size) {
    final sessionCount = widget.hours[index];
    final sessionLabel = sessionCount == 1 ? '1 session' : '$sessionCount sessions';
    final text = '${_hourLabel(index)}\n${_formatMinutes(widget.minutes[index])} · $sessionLabel';
    // Keep the tooltip near the wedge but clamped inside the circle so it
    // never gets clipped by the clock's bezel.
    const tooltipWidth = 96.0;
    const tooltipHeight = 50.0;
    final position = _hoverPosition!;
    var left = position.dx - tooltipWidth / 2;
    var top = position.dy - tooltipHeight - 14;
    left = left.clamp(0.0, math.max(0.0, size.width - tooltipWidth));
    top = top.clamp(0.0, math.max(0.0, size.height - tooltipHeight));

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.chewy(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ClockRosePainter extends CustomPainter {
  _ClockRosePainter({required this.hours, required this.maxCount, this.hoveredIndex});

  final List<int> hours;
  final int maxCount;
  final int? hoveredIndex;

  static const _rings = 3;

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
      ..color = kMutedColor
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
      ..color = kHairlineColor
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

      final isHovered = hoveredIndex == i;
      final intensity = count == 0 ? 0.12 : 0.35 + (fraction * 0.65);
      canvas.drawPath(
        path,
        Paint()..color = kAccentColor.withValues(alpha: isHovered ? math.min(1.0, intensity + 0.25) : intensity),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = kSurfaceColor
          ..strokeWidth = isHovered ? 2 : 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockRosePainter oldDelegate) =>
      oldDelegate.hours != hours ||
      oldDelegate.maxCount != maxCount ||
      oldDelegate.hoveredIndex != hoveredIndex;
}
