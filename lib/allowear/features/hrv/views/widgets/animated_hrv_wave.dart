import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedHrvWave extends StatefulWidget {
  final Color color;
  final double height;
  final double opacity;

  const AnimatedHrvWave({
    super.key,
    required this.color,
    this.height = 60,
    this.opacity = 0.5,
  });

  @override
  State<AnimatedHrvWave> createState() => _AnimatedHrvWaveState();
}

class _AnimatedHrvWaveState extends State<AnimatedHrvWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: _HrvWavePainter(
              color: widget.color.withOpacity(widget.opacity),
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _HrvWavePainter extends CustomPainter {
  final Color color;
  final double progress;

  _HrvWavePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // A more chaotic/variable wave for HRV
    for (double x = 0; x <= width; x += 2) {
      final double relativeX = x / width;
      final double wave1 = math.sin((relativeX + progress) * 2 * math.pi * 3);
      final double wave2 = math.cos((relativeX - progress * 1.5) * 2 * math.pi * 5);
      final double y = centerY + (wave1 * 0.6 + wave2 * 0.4) * (height / 4);
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HrvWavePainter oldDelegate) => true;
}
