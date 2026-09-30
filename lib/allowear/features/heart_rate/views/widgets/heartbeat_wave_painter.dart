import 'package:flutter/material.dart';

class HeartBeatBackground extends StatelessWidget {
  final Color color;

  const HeartBeatBackground({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: HeartBeatWavePainter(
        color: color,
        progress: 0.0, // Fixed progress
      ),
    );
  }
}

class HeartBeatWavePainter extends CustomPainter {
  final Color color;
  final double progress;

  HeartBeatWavePainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height * 0.55; // More centered position

    // ECG wave parameters
    const cycleWidth = 200.0;
    final offset = progress * cycleWidth;

    // Draw the line from left to right
    for (double x = -cycleWidth; x < width + cycleWidth; x += 1) {
      double currentX = x;
      // Calculate relative X within one cycle, adjusted by progress
      double relX = (currentX + offset) % cycleWidth;
      double y = centerY;

      if (relX < 20) {
        // Baseline
        y = centerY;
      } else if (relX < 35) {
        // P wave
        double t = (relX - 20) / 15;
        y = centerY - (10 * (1 - (2 * t - 1).abs()));
      } else if (relX < 50) {
        // Baseline
        y = centerY;
      } else if (relX < 55) {
        // Q wave
        double t = (relX - 50) / 5;
        y = centerY + (8 * t);
      } else if (relX < 65) {
        // R wave
        double t = (relX - 55) / 10;
        y = centerY + 8 - (88 * t); // Increased peak height
      } else if (relX < 75) {
        // R wave down
        double t = (relX - 65) / 10;
        y = (centerY - 80) + (88 * t); // Increased peak height
      } else if (relX < 80) {
        // S wave
        double t = (relX - 75) / 5;
        y = centerY + (8 * (1 - t));
      } else if (relX < 100) {
        // Baseline
        y = centerY;
      } else if (relX < 130) {
        // T wave
        double t = (relX - 100) / 30;
        y = centerY - (18 * (1 - (2 * t - 1).abs()));
      } else {
        // Baseline
        y = centerY;
      }

      if (x == -cycleWidth) {
        path.moveTo(currentX, y);
      } else {
        path.lineTo(currentX, y);
      }
    }

    canvas.drawPath(path, paint);

    // Optional: Add a second, thinner wave for more depth
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final backgroundPath = Path();
    const bgCycleWidth = 280.0;
    final bgOffset = 0.0; // Fixed

    for (double x = -bgCycleWidth; x < width + bgCycleWidth; x += 2) {
      double currentX = x;
      double relX = (currentX + bgOffset) % bgCycleWidth;
      double y = centerY + 25; // Slightly lower

      // Simple sine-like wave for background texture
      if (relX < 40) {
        y += 0;
      } else if (relX < 70) {
        double t = (relX - 40) / 30;
        y -= 20 * (1 - (2 * t - 1).abs());
      } else {
        y += 0;
      }

      if (x == -bgCycleWidth) {
        backgroundPath.moveTo(currentX, y);
      } else {
        backgroundPath.lineTo(currentX, y);
      }
    }
    canvas.drawPath(backgroundPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant HeartBeatWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
