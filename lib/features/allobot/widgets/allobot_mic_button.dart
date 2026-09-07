/// The docked mic button, with the listening animation on the button itself.
///
/// The waveform used to live in the card while the mic only swapped its icon,
/// which put the feedback in a different place from the control that caused it.
/// Here the button is what pulses: rings expand out of it while speech is being
/// recognised, so it is obvious the phone is listening and equally obvious it
/// has stopped.
library;

import 'package:flutter/material.dart';

class AlloBotMicButton extends StatefulWidget {
  const AlloBotMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.gradient,
    this.color = const Color(0xFFFF4E6A),
    this.size = 64,
  });

  final bool isListening;
  final VoidCallback onTap;
  final Gradient? gradient;

  /// Used for the pulse rings and as the fallback fill.
  final Color color;

  /// Diameter of the button itself. The rings overflow beyond it.
  final double size;

  @override
  State<AlloBotMicButton> createState() => _AlloBotMicButtonState();
}

class _AlloBotMicButtonState extends State<AlloBotMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isListening) _controller.repeat();
  }

  @override
  void didUpdateWidget(AlloBotMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening == oldWidget.isListening) return;
    if (widget.isListening) {
      _controller.repeat();
    } else {
      // Stopped rather than reset, so the rings fade from where they are
      // instead of snapping shut.
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringExtent = widget.size * 1.9;

    // The rings paint outside the button but must not take up space: this sits
    // in a Scaffold's docked FAB slot, and reporting a 120px size there would
    // widen the notch and push the navigation labels around. OverflowBox keeps
    // the laid-out size at the button's own, so only the painting overflows.
    // The tap target stays the button itself — the rings ignore pointers, and
    // nothing else here absorbs them, so taps outside still reach the bar
    // underneath.
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: OverflowBox(
        maxWidth: ringExtent,
        maxHeight: ringExtent,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (widget.isListening)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => CustomPaint(
                    size: Size.square(ringExtent),
                    painter: _PulsePainter(
                      progress: _controller.value,
                      color: widget.color,
                      innerDiameter: widget.size,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.gradient,
                  color: widget.gradient == null ? widget.color : null,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color
                          .withValues(alpha: widget.isListening ? 0.55 : 0.4),
                      blurRadius: widget.isListening ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isListening ? Icons.pause_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three rings expanding out of the button, each a third of a cycle behind the
/// last, fading as they grow.
class _PulsePainter extends CustomPainter {
  const _PulsePainter({
    required this.progress,
    required this.color,
    required this.innerDiameter,
  });

  final double progress;
  final Color color;

  /// Where a ring starts: the edge of the button, so it reads as coming out of
  /// it rather than floating around it.
  final double innerDiameter;

  static const int _ringCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final startRadius = innerDiameter / 2;
    final endRadius = size.width / 2;

    for (var i = 0; i < _ringCount; i++) {
      final phase = (progress + i / _ringCount) % 1.0;
      final radius = startRadius + (endRadius - startRadius) * phase;

      // Fades out over the ring's life, and eases in over the first tenth so a
      // ring does not appear abruptly at the button's edge.
      final fade = (1 - phase) * (phase < 0.1 ? phase / 0.1 : 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = color.withValues(alpha: 0.45 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.innerDiameter != innerDiameter;
}
