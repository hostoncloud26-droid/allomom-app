import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/my_health/vitals/steps/steps_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';

/// AlloConnect's step tile: today's (or [date]'s) steps, target and distance
/// on the left, a 24-hour bar chart on the right.
class StepTile extends StatelessWidget {
  /// The day's steps reading (controller's `stepsVital` for today, or the
  /// `steps` entry of `fetchVitalsForDate` for a past day).
  final VitalsStreamResponse? vital;

  /// Overrides the step count read from [vital].
  final int? steps;
  final int targetSteps;
  final DateTime date;

  /// Called after an entry is saved from the tile's log prompt.
  final VoidCallback? onLogged;

  const StepTile({
    super.key,
    this.vital,
    this.steps,
    this.targetSteps = 6000,
    required this.date,
    this.onLogged,
  });

  Color _stepColor(double progress) {
    if (progress >= 1.0) return const Color(0xFF00E676);
    if (progress >= 0.7) return Colors.cyan.shade400;
    return Colors.orange.shade400;
  }

  /// A device's per-hour breakdown, read as AlloConnect's
  /// `StepsResponseMapModel` does (`hourly_data`, or camelCase `hourlyData`;
  /// a JSON-encoded list is accepted too). Null when the row has none.
  static List<double>? _deviceHourly(VitalsStreamResponse? v) {
    dynamic raw = v?.data?['hourly_data'] ?? v?.data?['hourlyData'];
    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        raw = null;
      }
    }
    if (raw is! List || raw.isEmpty) return null;
    final hourly = List<double>.filled(24, 0);
    for (final item in raw) {
      if (item is! Map) continue;
      final h = item['hour'];
      final s = item['steps'];
      final hour = h is num ? h.toInt() : int.tryParse('$h');
      final steps = s is num ? s.toDouble() : double.tryParse('$s');
      if (hour != null && steps != null && hour >= 0 && hour < 24) {
        hourly[hour] = steps;
      }
    }
    return hourly;
  }

  /// Steps per hour of [date] for the 24 bars. A device reading carries its
  /// own hourly breakdown (what AlloConnect draws). Allomom's own entries
  /// don't, so the day's entries are placed in the hour they were logged (a
  /// rising series is treated as running totals); with no history, the whole
  /// total sits in the reading's hour, as AlloConnect does for a plain value.
  List<double> _hourly(int total) {
    final device = _deviceHourly(vital);
    if (device != null) return device;

    final hourly = List<double>.filled(24, 0);
    final rows = vitalHistoryOnDay(const ['steps'], date);
    if (rows.isEmpty) {
      if (total > 0 && vital != null) {
        hourly[vital!.createdAt.hour] = total.toDouble();
      }
      return hourly;
    }
    bool cumulative = true;
    for (int i = 1; i < rows.length; i++) {
      if (rows[i].value < rows[i - 1].value) cumulative = false;
    }
    double previous = 0;
    for (final r in rows) {
      final v = cumulative ? (r.value - previous) : r.value;
      previous = r.value;
      if (v > 0) hourly[r.createdAt.hour] += v;
    }
    return hourly;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final current = steps ?? vital?.value.round() ?? 0;
    final target = targetSteps > 0 ? targetSteps : 6000;
    final progress = (current / target).clamp(0.0, 1.0);
    final color = _stepColor(progress);
    final fmt = NumberFormat('#,###');

    // AlloConnect's stride: 0.762 m per step.
    final distanceKm = (current * 0.762) / 1000.0;
    final isDark = context.palette.isDark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return VitalTileShell(
      accent: color,
      icon: Icons.directions_walk_rounded,
      title: 'Step Count',
      value: fmt.format(current),
      unit: 'steps',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: current <= 0,
      emptyMessage: isToday ? 'No steps recorded yet' : 'No steps recorded',
      emptyIcon: Icons.directions_walk_rounded,
      emptyLogLabel: 'Log Steps',
      onEmptyLog: isToday
          ? () => openVitalLog(context, 'steps', onLogged: onLogged)
          : null,
      onTap: () => openVitalPage(context, const StepsSummaryScreen()),
      details: [
        const SizedBox(height: 10),
        Text(
          'Target: ${fmt.format(target)} • ${distanceKm.toStringAsFixed(2)} km',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
      chart: CustomPaint(
        size: Size.infinite,
        painter: _StepBarsPainter(
          hourlySteps: _hourly(current),
          color: color,
          isDark: isDark,
        ),
      ),
    );
  }
}

/// AlloConnect's `_MiniBarChartPainter` from its step tile, verbatim: 24 bars
/// 1.5px apart over a faint full-height track, a bottom-to-top gradient from
/// 30% [color] to [color], 1.5px corners, scaled to the day's busiest hour.
class _StepBarsPainter extends CustomPainter {
  final List<double> hourlySteps;
  final Color color;
  final bool isDark;

  _StepBarsPainter({
    required this.hourlySteps,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlySteps.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    final double maxSteps = hourlySteps.reduce(math.max);
    final double maxVal = maxSteps <= 0 ? 100.0 : maxSteps;

    final int length = hourlySteps.length;
    const double spacing = 1.5;
    final double barWidth = (width - (spacing * (length - 1))) / length;

    final Paint barPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color.withValues(alpha: 0.3), color],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final Paint bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < length; i++) {
      final double x = i * (barWidth + spacing);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, height),
          const Radius.circular(1.5),
        ),
        bgPaint,
      );

      final double val = math.max(0, hourlySteps[i]);
      final double barHeight = (val / maxVal) * (height - 4);
      if (barHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, height - barHeight, barWidth, barHeight),
            const Radius.circular(1.5),
          ),
          barPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StepBarsPainter oldDelegate) {
    return !listEquals(oldDelegate.hourlySteps, hourlySteps) ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
