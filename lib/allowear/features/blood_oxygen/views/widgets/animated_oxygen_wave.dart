import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedOxygenWave extends StatefulWidget {
  final Color color;
  final double height;
  final double opacity;

  const AnimatedOxygenWave({
    super.key,
    required this.color,
    this.height = 60,
    this.opacity = 0.5,
  });

  @override
  State<AnimatedOxygenWave> createState() => _AnimatedOxygenWaveState();
}

class _AnimatedOxygenWaveState extends State<AnimatedOxygenWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
            painter: _OxygenWavePainter(
              color: widget.color.withOpacity(widget.opacity),
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _OxygenWavePainter extends CustomPainter {
  final Color color;
  final double progress;

  _OxygenWavePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    for (double x = 0; x <= width; x++) {
      // Smooth sine wave representing breathing
      final double relativeX = x / width;
      final double normalizedX = (relativeX + progress) * 2 * math.pi * 2;
      final double y = centerY + math.sin(normalizedX) * (height / 3);
      
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OxygenWavePainter oldDelegate) => true;
}
