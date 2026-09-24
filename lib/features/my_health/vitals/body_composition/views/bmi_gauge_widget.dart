import 'dart:math' as math;
import 'package:flutter/material.dart';

class BmiGaugeWidget extends StatelessWidget {
  final double bmi;
  final double size;

  const BmiGaugeWidget({super.key, required this.bmi, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.85,
      child: CustomPaint(painter: _BmiGaugePainter(bmi: bmi)),
    );
  }
}

class _BmiGaugePainter extends CustomPainter {
  final double bmi;

  _BmiGaugePainter({required this.bmi});

  // Maps a BMI value to an angle in radians (from pi / 180° at left to 0 / 0° at right)
  double _bmiToAngle(double value) {
    if (value <= 0) return math.pi;
    final clamped = value.clamp(14.0, 36.0);

    if (clamped <= 18.5) {
      const minVal = 14.0;
      const maxVal = 18.5;
      final t = (clamped - minVal) / (maxVal - minVal);
      return math.pi - (t * (math.pi - 0.72 * math.pi));
    } else if (clamped <= 25.0) {
      const minVal = 18.5;
      const maxVal = 25.0;
      final t = (clamped - minVal) / (maxVal - minVal);
      return 0.72 * math.pi - (t * (0.72 * math.pi - 0.28 * math.pi));
    } else if (clamped <= 30.0) {
      const minVal = 25.0;
      const maxVal = 30.0;
      final t = (clamped - minVal) / (maxVal - minVal);
      return 0.28 * math.pi - (t * (0.28 * math.pi - 0.10 * math.pi));
    } else {
      const minVal = 30.0;
      const maxVal = 36.0;
      final t = (clamped - minVal) / (maxVal - minVal);
      return 0.10 * math.pi - (t * 0.10 * math.pi);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.68);
    final radius = (size.width / 2) - 18;
    final strokeWidth = 8.0;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final angle18_5 = _bmiToAngle(18.5);
    final angle25_0 = _bmiToAngle(25.0);
    final angle30_0 = _bmiToAngle(30.0);

    final paintArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background track
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawArc(arcRect, -math.pi, math.pi, false, bgPaint);

    // Segments with colors
    final segments = [
      _ArcSegment(
        startAngle: -math.pi,
        sweepAngle: math.pi - angle18_5,
        color: const Color(0xFF00D2FF), // Cyan/Blue
      ),
      _ArcSegment(
        startAngle: -angle18_5,
        sweepAngle: angle18_5 - angle25_0,
        color: const Color(0xFF00E676), // Green
      ),
      _ArcSegment(
        startAngle: -angle25_0,
        sweepAngle: angle25_0 - angle30_0,
        color: const Color(0xFFFFC107), // Amber/Yellow
      ),
      _ArcSegment(
        startAngle: -angle30_0,
        sweepAngle: angle30_0,
        color: const Color(0xFFFF5252), // Coral/Red
      ),
    ];

    for (final seg in segments) {
      paintArc.color = seg.color;
      canvas.drawArc(arcRect, seg.startAngle, seg.sweepAngle, false, paintArc);
    }

    // Draw markers along the arc
    _drawMarkerText(canvas, '16', center, radius + 11, _bmiToAngle(16));
    _drawMarkerText(canvas, '18.5', center, radius + 11, _bmiToAngle(18.5));
    _drawMarkerText(canvas, '25', center, radius + 11, _bmiToAngle(25.0));
    _drawMarkerText(canvas, '30', center, radius + 11, _bmiToAngle(30.0));

    // Draw needle
    final needleAngle = -_bmiToAngle(bmi > 0 ? bmi : 22.0);
    final needleLength = radius - 8;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Pivot dot
    final pivotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, pivotPaint);

    // Center text below pivot: "Healthy Range" & "18.5 – 24.9"
    final textPainterLabel = TextPainter(
      text: TextSpan(
        text: 'Healthy Range',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterLabel.paint(
      canvas,
      Offset(center.dx - textPainterLabel.width / 2, center.dy + 8),
    );

    final textPainterRange = TextPainter(
      text: const TextSpan(
        text: '18.5 – 24.9',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterRange.paint(
      canvas,
      Offset(center.dx - textPainterRange.width / 2, center.dy + 22),
    );
  }

  void _drawMarkerText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double angleRad,
  ) {
    final x = center.dx + radius * math.cos(-angleRad);
    final y = center.dy + radius * math.sin(-angleRad);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BmiGaugePainter oldDelegate) {
    return oldDelegate.bmi != bmi;
  }
}

class _ArcSegment {
  final double startAngle;
  final double sweepAngle;
  final Color color;

  _ArcSegment({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
  });
}
