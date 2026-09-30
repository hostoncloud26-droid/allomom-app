import 'package:flutter/material.dart';
import 'package:allomom/allowear/features/heart_rate/views/widgets/heartbeat_wave_painter.dart';

class AnimatedHeartBeatWave extends StatefulWidget {
  final Color color;
  final double height;
  final double speedMultiplier;
  final double opacity;

  const AnimatedHeartBeatWave({
    super.key,
    required this.color,
    this.height = 100,
    this.speedMultiplier = 1.0,
    this.opacity = 0.5,
  });

  @override
  State<AnimatedHeartBeatWave> createState() => _AnimatedHeartBeatWaveState();
}

class _AnimatedHeartBeatWaveState extends State<AnimatedHeartBeatWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.speedMultiplier).round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(AnimatedHeartBeatWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedMultiplier != widget.speedMultiplier) {
      _controller.duration =
          Duration(milliseconds: (2000 / widget.speedMultiplier).round());
      if (_controller.isAnimating) {
        _controller.repeat();
      }
    }
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
            painter: HeartBeatWavePainter(
              color: widget.color.withOpacity(widget.opacity),
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}
