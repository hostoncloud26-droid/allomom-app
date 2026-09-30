import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/features/hrv/views/widgets/animated_hrv_wave.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/allowear_controller.dart';

// ─────────────────────────────────────────────
// HRV Card – Heart Rate Variability themed
// Signature animation: Expanding Ripples (3min)
// around a balance icon. Orbiting idle animation.
// ─────────────────────────────────────────────

class HrvCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final bool showBorder;

  const HrvCard({
    super.key,
    this.margin,
    this.showShadow = true,
    this.showBorder = true,
  });

  static const _emerald = Color(0xFF00C896);
  static const _violet = Color(0xFF7C4DFF);
  static const _amber = Color(0xFFFFAB40);

  static String _fmt(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static String _hrvLabel(int hrv) {
    if (hrv >= 70) return 'Excellent';
    if (hrv >= 50) return 'Good';
    if (hrv >= 30) return 'Fair';
    return 'Low';
  }

  static Color _hrvColor(int hrv) {
    if (hrv >= 70) return _emerald;
    if (hrv >= 50) return _violet;
    if (hrv >= 30) return _amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final controller = allowear.hrv;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);

    return Obx(() {
      final isMonitoring = controller.isMonitoring.value;
      final hasHistory = controller.history.isNotEmpty;

      return Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
          border: showBorder
              ? Border.all(
                  color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  width: 1,
                )
              : null,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic,
          child: isMonitoring
              ? _HrvMonitoringView(controller: controller, isDark: isDark)
              : (hasHistory
                  ? _HrvSummaryView(controller: controller, isDark: isDark)
                  : _HrvIdleView(controller: controller, isDark: isDark)),
        ),
      );
    });
  }
}

class _HrvIdleView extends StatelessWidget {
  const _HrvIdleView({required this.controller, required this.isDark});
  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -20,
            child: Opacity(
              opacity: isDark ? 0.05 : 0.03,
              child: const Icon(
                Icons.monitor_heart_rounded,
                size: 120,
                color: Color(0xFF7C4DFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                const _OrbitingHrvIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HRV',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Black800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C4DFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Balanced State',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C4DFF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => controller.start(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF6200EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 5),
                        Text('Start',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HrvMonitoringView extends StatelessWidget {
  const _HrvMonitoringView({required this.controller, required this.isDark});
  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monitor_heart_rounded,
                    color: Color(0xFF7C4DFF), size: 16),
              ),
              const SizedBox(width: 10),
              Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      controller.status.value,
                      key: ValueKey(controller.status.value),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Black700,
                      ),
                    ),
                  )),
              const Spacer(),
              _StopButton(onTap: () => controller.stop(), isDark: isDark),
            ],
          ),
          const SizedBox(height: 32),
          Obx(() => _HrvRipplePulseUnit(
                progress: controller.progress.value,
                isDark: isDark,
              )),
          const SizedBox(height: 32),
          Obx(() => _HrvValueDisplay(
                hrv: controller.reading.value ?? 0,
                isDark: isDark,
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: AnimatedHrvWave(
              color: const Color(0xFF7C4DFF),
              height: 60,
              opacity: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _StopButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stop_rounded, size: 14, color: isDark ? Colors.white60 : Black700),
            const SizedBox(width: 4),
            Text(
              'Stop',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : Black700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HrvRipplePulseUnit extends StatefulWidget {
  final double progress;
  final bool isDark;

  const _HrvRipplePulseUnit({
    required this.progress,
    required this.isDark,
  });

  @override
  State<_HrvRipplePulseUnit> createState() => _HrvRipplePulseUnitState();
}

class _HrvRipplePulseUnitState extends State<_HrvRipplePulseUnit>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rippleCtrl,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(140, 140),
                painter: _RipplePainter(
                  phase: _rippleCtrl.value,
                  progress: widget.progress,
                  color: const Color(0xFF7C4DFF),
                  isDark: widget.isDark,
                ),
              );
            },
          ),
          _HrvBalanceIcon(isDark: widget.isDark),
          
          // Small progress indicator at top edge to still view the overall 3 min progress loosely
          if (widget.progress > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: -15,
              child: Center(
                child: Text(
                  '${(widget.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C4DFF),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double phase;
  final double progress;
  final Color color;
  final bool isDark;

  _RipplePainter({
    required this.phase,
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      // Offset each ring's phase by 1/3
      final currentPhase = (phase + (i / 3.0)) % 1.0;
      final radius = 20.0 + (maxRadius - 20.0) * currentPhase;
      
      // Fade out as it expands
      final opacity = (1.0 - currentPhase).clamp(0.0, 1.0) * 0.4;
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawCircle(center, radius, paint);
    }

    // Outer boundary to show overall limit (faint)
    final boundaryPaint = Paint()
      ..color = color.withOpacity(isDark ? 0.1 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, maxRadius, boundaryPaint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.phase != phase || old.progress != progress;
}

class _HrvBalanceIcon extends StatefulWidget {
  final bool isDark;
  const _HrvBalanceIcon({required this.isDark});

  @override
  State<_HrvBalanceIcon> createState() => _HrvBalanceIconState();
}

class _HrvBalanceIconState extends State<_HrvBalanceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF7C4DFF).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.balance_rounded,
          size: 40,
          color: Color(0xFF7C4DFF),
        ),
      ),
    );
  }
}

class _HrvValueDisplay extends StatelessWidget {
  final int hrv;
  final bool isDark;

  const _HrvValueDisplay({required this.hrv, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: hrv),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Text(
                  value > 0 ? '$value' : '--',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: isDark ? Colors.white : Black800,
                    fontFamily: 'Manrope',
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              'ms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white30 : Black300,
              ),
            ),
          ],
        ),
        if (hrv > 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: HrvCard._hrvColor(hrv).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              HrvCard._hrvLabel(hrv),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: HrvCard._hrvColor(hrv),
              ),
            ),
          ),
      ],
    );
  }
}

class _HrvSummaryView extends StatelessWidget {
  const _HrvSummaryView({required this.controller, required this.isDark});
  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final history = controller.history;
    final last = history.isNotEmpty ? history.last : 0;
    final avg = history.isEmpty
        ? 0
        : (history.fold(0, (a, b) => a + b) / history.length).round();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monitor_heart_rounded,
                        color: Color(0xFF7C4DFF), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('HRV Summary',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Black700)),
                ],
              ),
              GestureDetector(
                onTap: () => controller.start(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: isDark ? Colors.white60 : Black700),
                      const SizedBox(width: 4),
                      Text('Start Again',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : Black700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _HrvRipplePulseUnit(progress: 1.0, isDark: isDark),
              const SizedBox(width: 24),
              Expanded(
                child: _HrvValueDisplay(hrv: last, isDark: isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF7C4DFF).withOpacity(isDark ? 0.2 : 0.1)),
            ),
            child: Row(
              children: [
                _InsightChip(label: 'Avg', value: '${avg}ms', color: const Color(0xFF7C4DFF), isDark: isDark),
                const Spacer(),
                _InsightChip(label: 'Entries', value: '${history.length}', color: const Color(0xFF7C4DFF), isDark: isDark),
                const Spacer(),
                _InsightChip(label: 'Status', value: HrvCard._hrvLabel(last), color: HrvCard._hrvColor(last), isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _InsightChip({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Black300)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _OrbitingHrvIcon extends StatefulWidget {
  const _OrbitingHrvIcon();

  @override
  State<_OrbitingHrvIcon> createState() => _OrbitingHrvIconState();
}

class _OrbitingHrvIconState extends State<_OrbitingHrvIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glow
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          // Rotating Aura/Dot
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Transform.rotate(
                angle: _ctrl.value * 2 * math.pi,
                child: Stack(
                  children: [
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7C4DFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Icon(Icons.balance_rounded, color: Color(0xFF7C4DFF), size: 24),
        ],
      ),
    );
  }
}
