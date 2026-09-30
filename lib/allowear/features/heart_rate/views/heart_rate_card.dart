import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:allomom/allowear/features/heart_rate/views/widgets/animated_heart_beat_wave.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/heart_rate_summary_screen.dart';
import 'package:allomom/allowear/allowear_controller.dart';

// ─────────────────────────────────────────────
// Public entry point – stays reactive via Obx
// ─────────────────────────────────────────────
class HeartRateCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final bool showBorder;

  const HeartRateCard({
    super.key,
    this.margin,
    this.showShadow = true,
    this.showBorder = true,
  });

  static String formatLastUpdated(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = allowear.hr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);

    return Obx(() {
      final isMonitoring = controller.isMonitoring.value;
      final history = controller.history;
      final hasHistory = history.isNotEmpty;

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOutCubic,
            child: isMonitoring
                ? _HeartRateMonitoringView(
                    controller: controller,
                    isDark: isDark,
                  )
                : (hasHistory
                    ? _HeartRateSummaryView(
                        controller: controller,
                        isDark: isDark,
                      )
                    : _HeartRateIdleView(
                        controller: controller,
                        isDark: isDark,
                      )),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Idle / Stopped view
// ─────────────────────────────────────────────
class _HeartRateIdleView extends StatelessWidget {
  const _HeartRateIdleView({
    required this.controller,
    required this.isDark,
  });

  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Faint bg watermark
          Positioned(
            right: -30,
            bottom: -20,
            child: Opacity(
              opacity: isDark ? 0.04 : 0.03,
              child: const Icon(
                Icons.favorite_rounded,
                size: 160,
                color: Color(0xFFE74C3C),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                _PulsingHeartIcon(isDark: isDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Heart Rate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Black800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2ECC71),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sensor Ready',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Black700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => controller.start(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE74C3C).withOpacity(0.35),
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
                                fontSize: 13)),
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

class _PulsingHeartIcon extends StatefulWidget {
  final bool isDark;
  const _PulsingHeartIcon({required this.isDark});

  @override
  State<_PulsingHeartIcon> createState() => _PulsingHeartIconState();
}

class _PulsingHeartIconState extends State<_PulsingHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacity = Tween<double>(begin: 0.15, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
          width: 58,
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing glow ring
              Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color:
                          const Color(0xFFE74C3C).withOpacity(_opacity.value),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
              // Solid filled circle with white icon
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE74C3C),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Animated Heart Beat – ba-dum rhythm
// ─────────────────────────────────────────────
class _AnimatedHeartBeat extends StatefulWidget {
  final bool isDark;
  const _AnimatedHeartBeat({required this.isDark});

  @override
  State<_AnimatedHeartBeat> createState() => _AnimatedHeartBeatState();
}

class _AnimatedHeartBeatState extends State<_AnimatedHeartBeat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _beat1;
  late Animation<double> _beat2;

  @override
  void initState() {
    super.initState();
    // Total cycle: 1.2 seconds (1200ms)
    // Beat 1: 0-150ms, Beat 2: 300-450ms, Rest: 450-1200ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // First beat: quick expansion and return (0-150ms out of 1200)
    _beat1 = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.125, curve: Curves.easeOut),
      ),
    );

    // Second beat: another quick expansion and return (0.25-0.375 of timeline)
    _beat2 = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.375, curve: Curves.easeOut),
      ),
    );
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
        // Combine both beat animations
        final combinedScale = math.max(_beat1.value, _beat2.value);
        return Transform.scale(
          scale: combinedScale,
          child: Icon(
            Icons.favorite_rounded,
            size: 42,
            color: const Color(0xFFE74C3C),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Summary / Completed view
// ─────────────────────────────────────────────
class _HeartRateSummaryView extends StatelessWidget {
  const _HeartRateSummaryView({
    required this.controller,
    required this.isDark,
  });

  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final history = controller.history;
    final lastBpm = history.isNotEmpty ? history.last : 0;

    return InkWell(
      onTap: () => Get.to(() => const HeartRateSummaryScreen()),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE74C3C).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Color(0xFFE74C3C), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Heart Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Black700,
                      ),
                    ),
                  ],
                ),
                // Start Again Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.start(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 14,
                              color: isDark ? Colors.white60 : Black700),
                          const SizedBox(width: 4),
                          Text(
                            'Start Again',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Black700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Final Value Display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$lastBpm',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: isDark ? Colors.white : Black800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white30 : Black300,
                  ),
                ),
                const Spacer(),
                Text(
                  'Last updated: ${HeartRateCard.formatLastUpdated(controller.lastUpdated.value)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white30 : Black300,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Completed Graph
            SizedBox(
              height: 110,
              child: _LiveHeartRateGraph(
                data: history.toList(),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Monitoring view – lives inside a StatefulWidget
// so it can smoothly react to history changes
// ─────────────────────────────────────────────
class _HeartRateMonitoringView extends StatelessWidget {
  const _HeartRateMonitoringView({
    required this.controller,
    required this.isDark,
  });

  final AllowearMeasurement controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header & Stop Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE74C3C), size: 16),
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
              _StopButton(
                  onTap: () => controller.stop(), isDark: isDark),
            ],
          ),

          const SizedBox(height: 32),

          // ── Central Progress & Heart Unit
          Obx(() => _MeasurementProgressUnit(
                progress: controller.progress.value,
                bpm: controller.reading.value ?? 0,
                isDark: isDark,
              )),

          const SizedBox(height: 32),

          // ── BPM Display
          Obx(() => _AnimatedBpmDisplay(
                bpm: controller.reading.value ?? 0,
                isDark: isDark,
              )),

          const SizedBox(height: 24),

          // ── Waveform
          SizedBox(
            height: 60,
            child: AnimatedHeartBeatWave(
              color: const Color(0xFFE74C3C),
              height: 60,
              speedMultiplier: 1.0,
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
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stop_rounded,
                size: 14, color: isDark ? Colors.white60 : Black700),
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
// Measurement Progress Unit (Ring + Heart)
// ─────────────────────────────────────────────
class _MeasurementProgressUnit extends StatelessWidget {
  final double progress;
  final int bpm;
  final bool isDark;

  const _MeasurementProgressUnit({
    required this.progress,
    required this.bpm,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track
          CustomPaint(
            size: const Size(140, 140),
            painter: _RingTrackPainter(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          // Progress Ring
          CustomPaint(
            size: const Size(140, 140),
            painter: _RingProgressPainter(
              progress: progress,
              color: const Color(0xFFE74C3C),
            ),
          ),
          // Pulsing Heart
          _SyncPulsingHeart(bpm: bpm),
        ],
      ),
    );
  }
}

class _RingTrackPainter extends CustomPainter {
  final Color color;
  _RingTrackPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2 - 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingProgressPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingProgressPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// Synced Pulsing Heart
// ─────────────────────────────────────────────
class _SyncPulsingHeart extends StatefulWidget {
  final int bpm;
  const _SyncPulsingHeart({required this.bpm});

  @override
  State<_SyncPulsingHeart> createState() => _SyncPulsingHeartState();
}

class _SyncPulsingHeartState extends State<_SyncPulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _calculateDuration(widget.bpm),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );
  }

  Duration _calculateDuration(int bpm) {
    final effectiveBpm = bpm > 0 ? bpm : 60;
    // FastOutSlowIn looks best with a slightly slower cycle than real-time ms
    return Duration(milliseconds: (60000 / effectiveBpm / 2).round());
  }

  @override
  void didUpdateWidget(_SyncPulsingHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      _controller.duration = _calculateDuration(widget.bpm);
      if (_controller.isAnimating) _controller.repeat(reverse: true);
    }
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
          color: const Color(0xFFE74C3C).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.favorite_rounded,
          size: 48,
          color: Color(0xFFE74C3C),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated BPM Display
// ─────────────────────────────────────────────
class _AnimatedBpmDisplay extends StatelessWidget {
  final int bpm;
  final bool isDark;

  const _AnimatedBpmDisplay({required this.bpm, required this.isDark});

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
              tween: IntTween(begin: 0, end: bpm),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Text(
                  value > 0 ? '$value' : '--',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: isDark ? Colors.white : Black800,
                    fontFamily: 'Manrope',
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'BPM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white30 : Black300,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// The actual graph widget: StatefulWidget so we
// can drive its own AnimationController and get
// a brand-new smooth transition on every point.
// ─────────────────────────────────────────────
class _LiveHeartRateGraph extends StatefulWidget {
  const _LiveHeartRateGraph({
    required this.data,
    required this.isDark,
  });

  final List<int> data;
  final bool isDark;

  @override
  State<_LiveHeartRateGraph> createState() => _LiveHeartRateGraphState();
}

class _LiveHeartRateGraphState extends State<_LiveHeartRateGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _t;

  List<int> _prevData = [];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _t = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _prevData = List.from(widget.data);
    _anim.forward(from: 0);
  }

  @override
  void didUpdateWidget(_LiveHeartRateGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.length != oldWidget.data.length ||
        (widget.data.isNotEmpty &&
            widget.data.last != oldWidget.data.lastOrNull)) {
      _prevData = List.from(oldWidget.data);
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        return _buildChart(widget.data, _t.value);
      },
    );
  }

  Widget _buildChart(List<int> data, double t) {
    if (data.length < 2) return const SizedBox();

    // ── Compute Y bounds purely from live data with breathing room
    final minVal = data.reduce(math.min).toDouble();
    final maxVal = data.reduce(math.max).toDouble();
    final range = (maxVal - minVal).clamp(10.0, double.infinity);
    final padding = range * 0.25; // 25% breathing room on each side
    final minY = minVal - padding;
    final maxY = maxVal + padding;

    // ── Build spots – the newest point slides in using the animation value
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      double y = data[i].toDouble();
      // Animate the last incoming point from the previous last value
      if (i == data.length - 1 && _prevData.isNotEmpty) {
        final prevY = _prevData.last.toDouble();
        y = prevY + (y - prevY) * t;
      }
      spots.add(FlSpot(i.toDouble(), y));
    }

    final maxX = math.max(1.0, (data.length - 1).toDouble());

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        clipData: const FlClipData.all(),
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: const Color(0xFFE74C3C),
            barWidth: 2.5,
            isStrokeCapRound: true,
            preventCurveOverShooting: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isLatest = index == data.length - 1;
                if (isLatest) {
                  // Glowing latest dot
                  return FlDotCirclePainter(
                    radius: 5,
                    color: const Color(0xFFE74C3C),
                    strokeWidth: 2,
                    strokeColor: Colors.white.withOpacity(0.6),
                  );
                }
                // All other dots: invisible
                return FlDotCirclePainter(
                  radius: 0,
                  color: Colors.transparent,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE74C3C)
                      .withOpacity(0.25 * t), // fade in fill with animation
                  const Color(0xFFE74C3C).withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      // No built-in duration — our AnimationController drives everything
      duration: Duration.zero,
    );
  }
}
