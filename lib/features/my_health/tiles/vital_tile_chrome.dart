// Shared chrome for the My Health vital tiles, ported from AlloConnect's
// `interactive_tile_widgets.dart` / `vitals_empty_state.dart` so every tile
// has the same spring card, sparkline, header and empty state.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/blood_glucose/blood_glucose_entry_sheet.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_add_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/blood_pressure_add_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/body_composition/body_composition_entry_sheet.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/edit_heart_rate_dialog.dart';
import 'package:allomom/features/my_health/vitals/hemoglobin/hemoglobin_entry_sheet.dart';
import 'package:allomom/features/my_health/vitals/hrv/hrv_entry_dialog.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/steps/steps_entry_sheet.dart';
import 'package:allomom/features/my_health/vitals/stress/stress_entry_sheet.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────

/// Whether [date] is today.
bool vitalIsToday(DateTime date) => DateUtils.isSameDay(date, DateTime.now());

/// "Just now", "5m ago", "3h ago", "2d ago".
String vitalTimeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.isNegative || difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}

/// Every stored entry for any of [keys], oldest first, recorded on or before
/// the end of [date]. Read from the in-memory history of
/// [HealthVitalsController] (which holds every row loaded for the user).
List<VitalsStreamResponse> vitalHistoryUpTo(List<String> keys, DateTime date) {
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  final controller = HealthVitalsController.instance;
  final seen = <String>{};
  final rows = <VitalsStreamResponse>[];
  for (final key in keys) {
    for (final v in controller.getHistory(key)) {
      if (v.createdAt.isAfter(endOfDay)) continue;
      if (v.id.isNotEmpty && !seen.add(v.id)) continue;
      rows.add(v);
    }
  }
  rows.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return rows;
}

/// Entries for any of [keys] recorded on [date], oldest first.
List<VitalsStreamResponse> vitalHistoryOnDay(List<String> keys, DateTime date) {
  return vitalHistoryUpTo(
    keys,
    date,
  ).where((v) => DateUtils.isSameDay(v.createdAt, date)).toList();
}

/// The last [limit] values for any of [keys] up to [date] — the sparkline
/// series AlloConnect draws on its tiles.
List<double> vitalTrendUpTo(
  List<String> keys,
  DateTime date, {
  int limit = 8,
  double Function(VitalsStreamResponse v)? valueOf,
}) {
  final rows = vitalHistoryUpTo(keys, date);
  final values = rows.map(valueOf ?? (v) => v.value).toList();
  if (values.length > limit) return values.sublist(values.length - limit);
  return values;
}

/// Reads a number out of a vital's `data` map.
num? vitalDataNum(VitalsStreamResponse? vital, String field) {
  final raw = vital?.data?[field];
  if (raw is num) return raw;
  if (raw is String) return num.tryParse(raw);
  return null;
}

// ─── Interactive spring card ──────────────────────────────────────────────

/// A glassy card that springs when pressed, with a light haptic and a glow in
/// [glowColor]. Ported from AlloConnect's `InteractiveSpringCard`.
class InteractiveSpringCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color glowColor;
  final double borderRadius;
  final double scaleFactor;

  const InteractiveSpringCard({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor = Colors.cyan,
    this.borderRadius = 24.0,
    this.scaleFactor = 0.96,
  });

  @override
  State<InteractiveSpringCard> createState() => _InteractiveSpringCardState();
}

class _InteractiveSpringCardState extends State<InteractiveSpringCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.elasticOut,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDarkMode = p.isDark;
    final glow = widget.glowColor;

    final backgroundColor = isDarkMode
        ? p.card.withValues(alpha: 0.92)
        : Colors.white;
    final borderColor = glow.withValues(alpha: isDarkMode ? 0.12 : 0.08);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed ? glow.withValues(alpha: 0.4) : borderColor,
              width: _isPressed ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(
                  alpha: _isPressed
                      ? (isDarkMode ? 0.25 : 0.12)
                      : (isDarkMode ? 0.12 : 0.04),
                ),
                blurRadius: _isPressed ? 24 : 16,
                spreadRadius: _isPressed ? 2 : 0,
                offset: _isPressed ? const Offset(0, 4) : const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sparkline ────────────────────────────────────────────────────────────

/// A miniature Bezier sparkline with a gradient fill and a glowing end dot.
/// With no data it draws a faint placeholder wave, like AlloConnect.
class MiniSparklineChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double strokeWidth;
  final double? minY;
  final double? maxY;

  const MiniSparklineChart({
    super.key,
    required this.data,
    required this.color,
    this.height = 36.0,
    this.strokeWidth = 2.0,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    // A single reading still deserves a line: draw it flat.
    final series = data.isEmpty
        ? const [0.3, 0.4, 0.35, 0.45, 0.38, 0.5, 0.45]
        : (data.length == 1 ? [data.first, data.first] : data);
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: SparklinePainter(
          data: series,
          color: data.isEmpty ? color.withValues(alpha: 0.2) : color,
          strokeWidth: strokeWidth,
          isPlaceholder: data.isEmpty,
          minY: minY,
          maxY: maxY,
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double strokeWidth;
  final bool isPlaceholder;
  final double? minY;
  final double? maxY;

  SparklinePainter({
    required this.data,
    required this.color,
    required this.strokeWidth,
    required this.isPlaceholder,
    this.minY,
    this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final width = size.width;
    final height = size.height;

    double minVal = minY ?? data.reduce((a, b) => a < b ? a : b);
    double maxVal = maxY ?? data.reduce((a, b) => a > b ? a : b);
    for (final val in data) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    double delta = maxVal - minVal;
    if (delta == 0) delta = 1.0;

    final points = <Offset>[];
    final stepX = width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final relativeY = (data[i] - minVal) / delta;
      final y = height - 4 - (relativeY * (height - 8));
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    final fillPath = Path()
      ..moveTo(points[0].dx, height)
      ..lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = p0.dx + (p1.dx - p0.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }
    fillPath
      ..lineTo(points.last.dx, height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: isPlaceholder ? 0.05 : 0.22),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    if (!isPlaceholder) {
      final lastPoint = points.last;
      canvas.drawCircle(
        lastPoint,
        6.0,
        Paint()..color = color.withValues(alpha: 0.3),
      );
      canvas.drawCircle(lastPoint, 3.0, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.isPlaceholder != isPlaceholder;
  }
}

/// Downsamples [rawData] to [targetPoints] bucket averages.
List<double> downsampleTrendData(
  List<double> rawData, {
  int targetPoints = 12,
}) {
  if (rawData.isEmpty) return [];
  if (rawData.length <= targetPoints) return List.from(rawData);

  final result = <double>[];
  final bucketSize = rawData.length / targetPoints;
  for (int i = 0; i < targetPoints; i++) {
    final start = (i * bucketSize).floor();
    int end = ((i + 1) * bucketSize).floor();
    if (end > rawData.length) end = rawData.length;
    if (start >= end) {
      result.add(rawData[start.clamp(0, rawData.length - 1)]);
      continue;
    }
    double sum = 0;
    for (int j = start; j < end; j++) {
      sum += rawData[j];
    }
    result.add(sum / (end - start));
  }
  return result;
}

// ─── Tile layout ──────────────────────────────────────────────────────────

/// The layout every AlloConnect vital tile shares: on the left an icon chip +
/// title, a large value with its unit, a "time ago" line, optional detail
/// lines and an optional action chip; on the right a 75px panel holding a
/// chart. When [isEmpty] the value is dimmed and the right panel becomes a
/// "Log …" / "Not logged" prompt, as on AlloConnect's sleep tile.
class VitalTileShell extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String value;
  final String? unit;
  final DateTime? lastUpdatedAt;
  final List<Widget> details;
  final Widget? action;
  final Widget chart;
  final EdgeInsetsGeometry chartPadding;
  final VoidCallback? onTap;

  /// Nothing recorded for the day.
  final bool isEmpty;
  final String emptyMessage;

  /// Opens the log sheet from the empty panel (null hides the prompt).
  final VoidCallback? onEmptyLog;
  final String emptyLogLabel;
  final IconData emptyIcon;

  const VitalTileShell({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    this.unit,
    this.lastUpdatedAt,
    this.details = const [],
    this.action,
    required this.chart,
    this.chartPadding = const EdgeInsets.all(8),
    this.onTap,
    this.isEmpty = false,
    this.emptyMessage = 'No data recorded',
    this.onEmptyLog,
    this.emptyLogLabel = 'Log',
    this.emptyIcon = Icons.do_not_disturb_on_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final headerColor = isEmpty ? Colors.grey.shade400 : accent;
    final timeStr = !isEmpty && lastUpdatedAt != null
        ? vitalTimeAgo(lastUpdatedAt!)
        : '';

    return InteractiveSpringCard(
      glowColor: isEmpty ? accent.withValues(alpha: 0.5) : accent,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: headerColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: headerColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isEmpty
                                ? textColor.withValues(alpha: 0.3)
                                : textColor,
                            letterSpacing: -1,
                          ),
                        ),
                        if (unit != null && unit!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            unit!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: accent.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: accent.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      emptyMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ] else
                    ...details,
                  if (action != null) ...[const SizedBox(height: 12), action!],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: isEmpty
                  ? _EmptyPanel(
                      accent: accent,
                      isDark: isDark,
                      onLog: onEmptyLog,
                      logLabel: emptyLogLabel,
                      icon: emptyIcon,
                    )
                  : Container(
                      height: 75,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.black.withValues(alpha: 0.01),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: chartPadding,
                      child: chart,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final VoidCallback? onLog;
  final String logLabel;
  final IconData icon;

  const _EmptyPanel({
    required this.accent,
    required this.isDark,
    required this.onLog,
    required this.logLabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final canLog = onLog != null;
    final panel = Container(
      height: 75,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canLog ? Icons.add_circle_outline_rounded : icon,
              size: 20,
              color: accent.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 4),
            Text(
              canLog ? logLabel : 'Not logged',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: accent.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
    if (!canLog) return panel;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onLog,
      child: panel,
    );
  }
}

/// The small outlined action chip AlloConnect puts under a tile's value
/// (its "START" button). Here it opens Allomom's log sheet.
class VitalTileActionChip extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool pulse;

  const VitalTileActionChip({
    super.key,
    required this.color,
    required this.onTap,
    this.label = 'LOG',
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pulse)
              _PulseDot(color: color)
            else
              Icon(Icons.add_rounded, size: 14, color: color),
            SizedBox(width: pulse ? 8 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<double> _animation = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// A small detail line under a tile's value (e.g. "Pulse: 72 bpm").
class VitalTileDetail extends StatelessWidget {
  final String text;
  final Color? color;
  final double topGap;

  const VitalTileDetail(this.text, {super.key, this.color, this.topGap = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color ?? textColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ─── Empty state (full-screen) ────────────────────────────────────────────

/// A pulsing icon with a title, subtitle and optional action — AlloConnect's
/// `VitalsEmptyState`, for a whole section with no readings.
class VitalsEmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData icon;
  final Color? iconColor;

  const VitalsEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
    this.icon = Icons.favorite_rounded,
    this.iconColor,
  });

  @override
  State<VitalsEmptyState> createState() => _VitalsEmptyStateState();
}

class _VitalsEmptyStateState extends State<VitalsEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<double> _animation = Tween<double>(
    begin: 1.0,
    end: 1.2,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final color = widget.iconColor ?? const Color(0xFFFF5252);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(widget.icon, color: color, size: 48),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.5),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (widget.onAction != null) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.actionLabel ?? 'Action',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pushes [page] with a MaterialPageRoute, the way my_health_page does.
void openVitalPage(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

/// Opens the entry sheet for [key] — the ported AlloConnect sheet for each
/// vital, or Allomom's generic log sheet (locked to [key]) for the vitals
/// without one (kick count, feeding) — and calls [onLogged] when an entry
/// was saved.
Future<void> openVitalLog(
  BuildContext context,
  String key, {
  VoidCallback? onLogged,
}) async {
  final bool? saved;
  switch (key) {
    case 'steps':
      saved = await showStepsEntrySheet(context);
    case 'sleep':
      saved = await showSleepEntrySheet(context);
    case 'heart_rate':
      saved = await showHeartRateEntryDialog(context);
    case 'hrv':
      saved = await showHrvEntryDialog(context);
    case 'blood_oxygen':
      saved = await showBloodOxygenAddSheet(context);
    case 'blood_pressure':
      saved = await showBloodPressureAddSheet(context);
    case 'stress':
      saved = await showStressEntrySheet(context);
    case 'weight':
      saved = await showBodyCompositionEntrySheet(
        context,
        metric: BodyCompositionMetric.weight,
      );
    case 'height':
      saved = await showBodyCompositionEntrySheet(
        context,
        metric: BodyCompositionMetric.height,
      );
    case 'hemoglobin':
      saved = await showHemoglobinEntrySheet(context);
    case 'glucose':
      saved = await showBloodGlucoseEntrySheet(context);
    default:
      saved = await VitalLogBottomSheet.show(
        context,
        initialKey: key,
        lockKey: true,
      );
  }
  if (saved == true) onLogged?.call();
}

// ─── Mini bar chart ───────────────────────────────────────────────────────

/// Rounded vertical bars over a faint track, with a gradient in [color] —
/// AlloConnect's 24-hour step bars, reused for kicks and feeds.
class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double spacing;

  const MiniBarChart({
    super.key,
    required this.values,
    required this.color,
    this.spacing = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MiniBarChartPainter(
        values: values,
        color: color,
        isDark: context.palette.isDark,
        spacing: spacing,
      ),
    );
  }
}

class _MiniBarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool isDark;
  final double spacing;

  _MiniBarChartPainter({
    required this.values,
    required this.color,
    required this.isDark,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final width = size.width;
    final height = size.height;

    final maxRaw = values.reduce((a, b) => a > b ? a : b);
    final maxVal = maxRaw <= 0 ? 100.0 : maxRaw;
    final length = values.length;
    final barWidth = (width - (spacing * (length - 1))) / length;
    final radius = Radius.circular(barWidth < 6 ? 1.5 : 3);

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color.withValues(alpha: 0.3), color],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < length; i++) {
      final x = i * (barWidth + spacing);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, barWidth, height), radius),
        bgPaint,
      );
      final barHeight = (values[i].clamp(0, maxVal) / maxVal) * (height - 4);
      if (barHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, height - barHeight, barWidth, barHeight),
            radius,
          ),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.spacing != spacing;
  }
}
