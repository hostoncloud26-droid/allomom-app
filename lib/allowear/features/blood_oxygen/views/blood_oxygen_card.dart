import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/features/blood_oxygen/views/widgets/animated_oxygen_wave.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/allowear_controller.dart';

// ─────────────────────────────────────────────
// Blood Oxygen Card – Premium Health Gauge
// Signature animation: Value-based Gauge (80-100%)
// Outer scanning dashed ring for 60s loading phase.
// Deep Blue Theme
// ─────────────────────────────────────────────

class BloodOxygenCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final bool showBorder;

  const BloodOxygenCard({
    super.key,
    this.margin,
    this.showShadow = true,
    this.showBorder = true,
  });

  static const _blue = Color(0xFF2979FF);
  static const _lightBlue = Color(0xFF448AFF);

  static String _spO2Label(int spo2) {
    if (spo2 == 0) return 'Analyzing...';
    if (spo2 >= 95) return 'Optimal';
    if (spo2 >= 90) return 'Borderline';
    return 'Critical';
  }

  static Color _spO2Color(int spo2) {
    if (spo2 == 0) return _blue;
    if (spo2 >= 95) return _blue;
    if (spo2 >= 90) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final controller = allowear.spo2;
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
              ? _SpO2MonitoringView(controller: controller, isDark: isDark)
              : (hasHistory
                  ? _SpO2SummaryView(controller: controller, isDark: isDark)
                  : _SpO2IdleView(controller: controller, isDark: isDark)),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Idle View (Compact)
// ─────────────────────────────────────────────

class _SpO2IdleView extends StatelessWidget {
  const _SpO2IdleView({required this.controller, required this.isDark});
  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BloodOxygenCard._blue.withOpacity(isDark ? 0.12 : 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                _PulsingLungIcon(isDark: isDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Blood Oxygen',
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
                              color: BloodOxygenCard._blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'SpO₂ Ready',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: BloodOxygenCard._blue,
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
                        colors: [BloodOxygenCard._lightBlue, BloodOxygenCard._blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: BloodOxygenCard._blue.withOpacity(0.35),
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

// ─────────────────────────────────────────────
// Monitoring View (Gauge + Scanner + Wave)
// ─────────────────────────────────────────────

class _SpO2MonitoringView extends StatelessWidget {
  const _SpO2MonitoringView({required this.controller, required this.isDark});
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BloodOxygenCard._blue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.air_rounded,
                        color: BloodOxygenCard._blue, size: 16),
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
                ],
              ),
              _StopButton(onTap: () => controller.stop(), isDark: isDark),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Obx(() => _SpO2ValueGauge(
                  spo2Value: controller.reading.value ?? 0,
                  isMonitoring: true,
                  isDark: isDark,
                )),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: AnimatedOxygenWave(
              color: BloodOxygenCard._blue,
              height: 50,
              opacity: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Summary View (Gauge + Insights)
// ─────────────────────────────────────────────

class _SpO2SummaryView extends StatelessWidget {
  const _SpO2SummaryView({required this.controller, required this.isDark});
  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final history = controller.history;
    final last = history.isNotEmpty ? history.last : 0;

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
                      color: BloodOxygenCard._blue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.air_rounded,
                        color: BloodOxygenCard._blue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Blood Oxygen Summary',
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
          const SizedBox(height: 32),
          Center(
            child: _SpO2ValueGauge(
              spo2Value: last,
              isMonitoring: false,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 32),
          _InsightsFooter(controller: controller, isDark: isDark),
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

// ─────────────────────────────────────────────
// SpO2 Value-based Gauge Component
// ─────────────────────────────────────────────

class _SpO2ValueGauge extends StatefulWidget {
  final int spo2Value;
  final bool isMonitoring;
  final bool isDark;

  const _SpO2ValueGauge({
    required this.spo2Value,
    required this.isMonitoring,
    required this.isDark,
  });

  @override
  State<_SpO2ValueGauge> createState() => _SpO2ValueGaugeState();
}

class _SpO2ValueGaugeState extends State<_SpO2ValueGauge>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late Animation<double> _sweepAnimation;

  late AnimationController _loadingController;

  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sweepAnimation = Tween<double>(begin: 0.0, end: _getNormalizedValue(widget.spo2Value)).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeOutCubic),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isMonitoring) {
      _loadingController.repeat();
    }
    _sweepController.forward();
    _previousValue = widget.spo2Value;
  }

  @override
  void didUpdateWidget(_SpO2ValueGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isMonitoring != oldWidget.isMonitoring) {
      if (widget.isMonitoring) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
      }
    }

    if (widget.spo2Value != oldWidget.spo2Value) {
      _sweepAnimation = Tween<double>(
        begin: _getNormalizedValue(_previousValue),
        end: _getNormalizedValue(widget.spo2Value),
      ).animate(CurvedAnimation(parent: _sweepController, curve: Curves.easeOutCubic));
      
      _sweepController.forward(from: 0.0);
      _previousValue = widget.spo2Value;
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  double _getNormalizedValue(int spo2) {
    if (spo2 == 0) return 0.0;
    // Map SpO2 values from 80% to 100% to 0.0 -> 1.0 progress.
    return ((spo2 - 80) / 20).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Loading Scanner Element (Outer Ring)
          if (widget.isMonitoring)
            AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(220, 220),
                  painter: _LoadingDashedRing(
                    phase: _loadingController.value,
                    color: BloodOxygenCard._blue,
                  ),
                );
              },
            ),

          // 2. Health Segmented Track (Inner Ring)
          CustomPaint(
            size: const Size(190, 190),
            painter: _SegmentedHealthTrackPainter(
              isDark: widget.isDark,
            ),
          ),

          // 3. Current Value Indicator (Sweeping Arch)
          AnimatedBuilder(
            animation: _sweepAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(190, 190),
                painter: _HealthValueIndicatorPainter(
                  progress: _sweepAnimation.value,
                  color: BloodOxygenCard._spO2Color(widget.spo2Value),
                ),
              );
            },
          ),

          // 4. Center Typography
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _sweepAnimation,
                builder: (context, child) {
                  // Interpolate the text value
                  final displayValue = widget.spo2Value > 0 ? widget.spo2Value : 0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayValue > 0 ? '$displayValue' : '--',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          color: widget.isDark ? Colors.white : Black800,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: widget.isDark ? Colors.white30 : Black300,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.isMonitoring ? 'Reading...' : BloodOxygenCard._spO2Label(widget.spo2Value),
                  key: ValueKey(widget.isMonitoring ? 'Reading...' : BloodOxygenCard._spO2Label(widget.spo2Value)),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BloodOxygenCard._spO2Color(widget.spo2Value),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Painters & Animated Icons
// ─────────────────────────────────────────────

class _PulsingLungIcon extends StatefulWidget {
  final bool isDark;
  const _PulsingLungIcon({required this.isDark});

  @override
  State<_PulsingLungIcon> createState() => _PulsingLungIconState();
}

class _PulsingLungIconState extends State<_PulsingLungIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: BloodOxygenCard._blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.air_rounded, color: BloodOxygenCard._blue, size: 24),
      ),
    );
  }
}

class _SegmentedHealthTrackPainter extends CustomPainter {
  final bool isDark;
  _SegmentedHealthTrackPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // We want a 240 degree gauge (start: 150deg, sweep: 240deg)
    final startAngle = math.pi * 0.833; // 150 degrees
    final totalSweep = math.pi * 1.333; // 240 degrees
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Segment 1 (80-89% -> bottom 50% of the gauge)
    paint.color = isDark ? Colors.redAccent.withOpacity(0.2) : Colors.red.shade100;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, totalSweep * 0.5, false, paint);

    // Segment 2 (90-94% -> next 25% of the gauge)
    paint.color = isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.shade100;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle + (totalSweep * 0.5), totalSweep * 0.25, false, paint);

    // Segment 3 (95-100% -> top 25% of the gauge)
    paint.color = isDark ? BloodOxygenCard._blue.withOpacity(0.2) : BloodOxygenCard._blue.withOpacity(0.3);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle + (totalSweep * 0.75), totalSweep * 0.25, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HealthValueIndicatorPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0 representing 80 to 100
  final Color color;
  
  _HealthValueIndicatorPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final startAngle = math.pi * 0.833; // 150 degrees
    final totalSweep = math.pi * 1.333; // 240 degrees

    final sweepAngle = totalSweep * progress;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw the active fill arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Draw the bright glowing tip (the needle)
    final tipAngle = startAngle + sweepAngle;
    final dotX = center.dx + radius * math.cos(tipAngle);
    final dotY = center.dy + radius * math.sin(tipAngle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final dotShadow = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset(dotX, dotY), 8, dotShadow);
    canvas.drawCircle(Offset(dotX, dotY), 6, dotPaint);
  }

  @override
  bool shouldRepaint(_HealthValueIndicatorPainter old) => old.progress != progress || old.color != color;
}

class _LoadingDashedRing extends CustomPainter {
  final double phase; // 0.0 to 1.0 (rotation)
  final Color color;

  _LoadingDashedRing({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4; // Outer ring margin

    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // We'll draw 12 dashes around the circle
    final int dashCount = 12;
    final double dashSpacing = (2 * math.pi) / dashCount;
    final double dashLength = dashSpacing * 0.4;
    
    // Rotate the entire canvas based on the phase
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(phase * 2 * math.pi);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < dashCount; i++) {
      final angle = i * dashSpacing;
      // Make them pulse slightly based on phase
      final opacityMultiplier = (0.5 + 0.5 * math.sin((phase * math.pi * 4) + i)).clamp(0.2, 1.0);
      paint.color = color.withOpacity(opacityMultiplier * 0.8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashLength,
        false,
        paint,
      );
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoadingDashedRing old) => old.phase != phase;
}

// ─────────────────────────────────────────────
// Footer Summary
// ─────────────────────────────────────────────

class _InsightsFooter extends StatelessWidget {
  final AllowearMeasurement controller;
  final bool isDark;

  const _InsightsFooter({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final history = controller.history;
    final min = history.isEmpty ? 0 : history.reduce(math.min);
    final max = history.isEmpty ? 0 : history.reduce(math.max);
    final avg = history.isEmpty
        ? 0
        : (history.fold(0, (a, b) => a + b) / history.length).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BloodOxygenCard._blue.withOpacity(isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: BloodOxygenCard._blue.withOpacity(isDark ? 0.2 : 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InsightChip(label: 'Min', value: '$min%', color: Colors.amber, isDark: isDark),
          _InsightChip(label: 'Avg', value: '$avg%', color: BloodOxygenCard._lightBlue, isDark: isDark),
          _InsightChip(label: 'Max', value: '$max%', color: BloodOxygenCard._blue, isDark: isDark),
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
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
