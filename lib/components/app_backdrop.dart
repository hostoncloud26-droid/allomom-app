import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';

/// The soft, slowly drifting pastel wash the main shell sits on: a blush to
/// lavender to mint gradient, a few blurred colour glows, and a faint scatter
/// of hearts, stars and dots.
///
/// Pages inside it paint their scaffold with [scaffoldColor], which is
/// transparent under an enabled backdrop and their own colour anywhere else.
/// [enabled] switches it off without rebuilding the subtree, so the shell can
/// show it on Home only and keep the other tabs' state.
class AppBackdrop extends StatefulWidget {
  const AppBackdrop({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  /// Whether [context] sits under an enabled [AppBackdrop].
  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BackdropScope>()?.enabled ??
      false;

  /// Transparent when [context] sits under an enabled [AppBackdrop], else
  /// [fallback].
  static Color scaffoldColor(BuildContext context, Color fallback) =>
      isActive(context) ? Colors.transparent : fallback;

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDrift();
  }

  @override
  void didUpdateWidget(AppBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _syncDrift();
  }

  /// Drifts only while shown, and never when the system asks for reduced motion.
  void _syncDrift() {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _BackdropScope(
      enabled: widget.enabled,
      child: Stack(
        children: [
          if (widget.enabled)
            Positioned.fill(
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: _baseGradient(palette)),
                  child: AnimatedBuilder(
                    animation: _drift,
                    builder: (context, _) => CustomPaint(
                      painter: _BackdropPainter(
                        t: _drift.value,
                        isDark: palette.isDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }

  LinearGradient _baseGradient(AppPalette palette) => palette.isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1E1519), Color(0xff17151F), Color(0xff121716)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F3), Color(0xFFFBF6FF), Color(0xFFF1FAF8)],
          stops: [0.0, 0.55, 1.0],
        );
}

class _BackdropScope extends InheritedWidget {
  const _BackdropScope({required this.enabled, required super.child});

  final bool enabled;

  @override
  bool updateShouldNotify(_BackdropScope oldWidget) =>
      oldWidget.enabled != enabled;
}

/// A colour glow: where it sits (as a fraction of the screen), how far it
/// wanders, and its size relative to the screen width.
class _Glow {
  const _Glow(this.color, this.x, this.y, this.radius, this.phase);

  final Color color;
  final double x;
  final double y;
  final double radius;
  final double phase;
}

const _glows = [
  _Glow(primaryColor, 0.05, 0.10, 0.75, 0.0),
  _Glow(Color(0xFFB69CFF), 0.95, 0.22, 0.70, 0.25),
  _Glow(Color(0xFF7FDCCB), 0.10, 0.62, 0.65, 0.5),
  _Glow(Color(0xFFFFB98A), 0.90, 0.88, 0.70, 0.75),
];

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.t, required this.isDark});

  final double t;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    final glowAlpha = isDark ? 0.14 : 0.22;

    for (final glow in _glows) {
      final a = angle + glow.phase * 2 * math.pi;
      final center = Offset(
        size.width * (glow.x + 0.06 * math.sin(a)),
        size.height * (glow.y + 0.03 * math.cos(a)),
      );
      final radius = size.width * glow.radius;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            glow.color.withValues(alpha: glowAlpha),
            glow.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    _paintSparkles(canvas, size, angle);
  }

  /// A fixed, sparse scatter of tiny shapes that bob gently in place.
  void _paintSparkles(Canvas canvas, Size size, double angle) {
    final ink = (isDark ? Colors.white : primaryColor).withValues(
      alpha: isDark ? 0.05 : 0.09,
    );
    final paint = Paint()..color = ink;
    final rnd = math.Random(7);

    for (var i = 0; i < 18; i++) {
      final base = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height,
      );
      final bob = 4 * math.sin(angle + i);
      final pos = base.translate(0, bob);
      final s = 4 + rnd.nextDouble() * 6;
      switch (i % 3) {
        case 0:
          canvas.drawCircle(pos, s * 0.45, paint);
        case 1:
          canvas.drawPath(_star(pos, s), paint);
        default:
          canvas.drawPath(_heart(pos, s), paint);
      }
    }
  }

  Path _star(Offset c, double r) {
    // A four-point sparkle.
    final q = r * 0.28;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + q, c.dy - q, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + q, c.dy + q, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - q, c.dy + q, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - q, c.dy - q, c.dx, c.dy - r)
      ..close();
  }

  Path _heart(Offset c, double s) {
    final w = s;
    final h = s * 0.9;
    return Path()
      ..moveTo(c.dx, c.dy + h * 0.5)
      ..cubicTo(
        c.dx - w,
        c.dy - h * 0.1,
        c.dx - w * 0.5,
        c.dy - h,
        c.dx,
        c.dy - h * 0.35,
      )
      ..cubicTo(
        c.dx + w * 0.5,
        c.dy - h,
        c.dx + w,
        c.dy - h * 0.1,
        c.dx,
        c.dy + h * 0.5,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.t != t || old.isDark != isDark;
}
