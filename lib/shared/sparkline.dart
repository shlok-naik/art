import 'package:flutter/material.dart';

/// Minimal line-chart trend of a series of values, oldest (left) to newest
/// (right). Pass [minValue]/[maxValue] to fix the scale (e.g. the 1-10
/// difficulty slider); omit them to auto-scale to the series' own range.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.width,
    required this.height,
    required this.color,
    this.minValue,
    this.maxValue,
  });

  final List<double> values;
  final double width;
  final double height;
  final Color color;
  final double? minValue;
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
          minValue: minValue,
          maxValue: maxValue,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  final List<double> values;
  final Color color;
  final double? minValue;
  final double? maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, dotPaint);
      return;
    }

    final lo = minValue ?? values.reduce((a, b) => a < b ? a : b);
    final hi = maxValue ?? values.reduce((a, b) => a > b ? a : b);
    final range = hi - lo;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final normalized = range == 0 ? 0.5 : ((values[i] - lo) / range).clamp(0.0, 1.0);
      final y = size.height * (1 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.minValue != minValue ||
      oldDelegate.maxValue != maxValue;
}
