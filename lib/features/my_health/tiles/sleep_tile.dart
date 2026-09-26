import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';
import 'package:allomom/config/quick_action_images.dart';

/// AlloConnect's sleep tile: duration with bedtime / wake time on the left,
/// the deep / light / REM split on the right.
class SleepTile extends StatelessWidget {
  /// The night's `sleep` (manual, hours) or `sleep_data` (device) reading.
  final VitalsStreamResponse? vital;

  /// Overrides the duration read from [vital].
  final double? sleepHours;
  final double targetSleepHours;
  final DateTime date;
  final VoidCallback? onLogged;

  const SleepTile({
    super.key,
    this.vital,
    this.sleepHours,
    this.targetSleepHours = 8.0,
    required this.date,
    this.onLogged,
  });

  static const _deepColor = Color(0xFF4F46E5);
  static const _lightColor = Color(0xFF0EA5E9);
  static const _remColor = Color(0xFF9333EA);
  static const _awakeColor = Color(0xFFF59E0B);

  Color _sleepColor(double hours) {
    if (hours >= 7.0) return Colors.indigo.shade400;
    if (hours >= 5.0) return Colors.blue.shade400;
    return Colors.amber.shade400;
  }

  static DateTime? _parseTime(dynamic raw) {
    if (raw is DateTime) return raw.toLocal();
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal();
    }
    if (raw is num && raw > 0) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt()).toLocal();
    }
    return null;
  }

  static num? _num(VitalsStreamResponse v, List<String> fields) {
    for (final f in fields) {
      final n = vitalDataNum(v, f);
      if (n != null) return n;
    }
    return null;
  }

  static DateTime? _time(VitalsStreamResponse v, List<String> fields) {
    for (final f in fields) {
      final t = _parseTime(v.data?[f]);
      if (t != null) return t;
    }
    return null;
  }

  /// One stored session, read the way AlloConnect's tile reads a
  /// `sleep_data` row (`SleepResponseMapModel`, snake_case, minutes) and also
  /// in Allomom's camelCase / manual form (`value` in hours, `deepSleep` /
  /// `lightSleep` in hours). Null when it holds no sleep.
  static _SleepSession? _session(VitalsStreamResponse v) {
    DateTime? bed = _time(v, const ['sleep_time', 'sleepTime', 'bedTime']);
    DateTime? wake = _time(v, const ['awake_time', 'awakeTime', 'wakeTime']);

    int minutes =
        (_num(v, const [
                  'total_sleep_duration',
                  'totalSleepDuration',
                  'totalMinutes',
                ]) ??
                0)
            .round();
    if (minutes <= 0 && bed != null && wake != null && wake.isAfter(bed)) {
      minutes = wake.difference(bed).inMinutes;
    }
    if (minutes <= 0) {
      final unit = v.unit.toLowerCase();
      minutes = (unit.contains('min') || v.value > 24)
          ? v.value.round()
          : (v.value * 60).round();
    }
    if (minutes <= 0) return null;

    wake ??= v.createdAt;
    bed ??= wake.subtract(Duration(minutes: minutes));

    double deep = math.max(
      0,
      (_num(v, const ['deep_sleep_duration', 'deepSleepDuration']) ?? 0)
          .toDouble(),
    );
    double light = math.max(
      0,
      (_num(v, const ['light_sleep_duration', 'lightSleepDuration']) ?? 0)
          .toDouble(),
    );
    double rem = math.max(
      0,
      (_num(v, const ['rem_sleep_duration', 'remSleepDuration']) ?? 0)
          .toDouble(),
    );
    double awake = math.max(
      0,
      (_num(v, const ['awake_duration', 'awakeDuration']) ?? 0).toDouble(),
    );

    if (deep + light + rem <= 0) {
      // Allomom's manual log stores a deep / light split in hours. Its log
      // sheet never asks for one, so a 25% deep share is the controller's
      // default, not a measurement -- that falls through to AlloConnect's
      // estimate like any plain value. A split that differs is kept.
      final deepH = vitalDataNum(v, 'deepSleep')?.toDouble();
      final lightH = vitalDataNum(v, 'lightSleep')?.toDouble();
      final hours = minutes / 60.0;
      final isDefaultSplit =
          deepH != null && (deepH - hours * 0.25).abs() < 0.01;
      if (deepH != null &&
          lightH != null &&
          deepH + lightH > 0 &&
          !isDefaultSplit) {
        deep = deepH * 60;
        light = lightH * 60;
      } else {
        // AlloConnect's fallback for a session without stages.
        deep = (minutes * 0.22).roundToDouble();
        rem = (minutes * 0.20).roundToDouble();
        light = math.max(0, minutes - deep - rem);
      }
    }

    return _SleepSession(
      bed: bed,
      wake: wake,
      minutes: minutes,
      deep: deep,
      light: light,
      rem: rem,
      awake: awake,
    );
  }

  /// The whole of [date], as AlloConnect's tile shows it: every session that
  /// ended that day added up, bedtime the earliest, wake time the latest.
  /// Falls back to [vital] alone when the controller holds no history for it.
  _SleepSession? _day() {
    final sessions = <_SleepSession>[];
    final rows = vitalHistoryUpTo(const ['sleep', 'sleep_data'], date);
    for (final r in rows) {
      final s = _session(r);
      if (s != null && DateUtils.isSameDay(s.wake, date)) sessions.add(s);
    }
    if (sessions.isEmpty && vital != null) {
      final s = _session(vital!);
      if (s != null) sessions.add(s);
    }
    if (sessions.isEmpty) return null;
    return sessions.reduce(
      (a, b) => _SleepSession(
        bed: b.bed.isBefore(a.bed) ? b.bed : a.bed,
        wake: b.wake.isAfter(a.wake) ? b.wake : a.wake,
        minutes: a.minutes + b.minutes,
        deep: a.deep + b.deep,
        light: a.light + b.light,
        rem: a.rem + b.rem,
        awake: a.awake + b.awake,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final day = _day();
    // The day's summed sessions, as AlloConnect shows; the page's
    // [sleepHours] (latest entry only) is the fallback.
    int minutes = day?.minutes ?? 0;
    if (minutes <= 0 && sleepHours != null) {
      minutes = (sleepHours! * 60).round();
    }
    minutes = math.max(0, minutes);
    final hours = minutes / 60.0;
    final color = _sleepColor(hours);
    final isDark = context.palette.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    final bed = day?.bed;
    final wake = day?.wake;

    double deep = day?.deep ?? 0;
    double light = day?.light ?? 0;
    double rem = day?.rem ?? 0;
    final awake = day?.awake ?? 0;
    if (day == null && minutes > 0) {
      deep = (minutes * 0.22).roundToDouble();
      rem = (minutes * 0.20).roundToDouble();
      light = math.max(0, minutes - deep - rem);
    }
    // AlloConnect divides each stage by the total sleep minutes.
    double ratio(double v) => minutes > 0 ? v / minutes : 0;

    final timeFormat = DateFormat('hh:mm a');
    final h = minutes ~/ 60;
    final m = minutes % 60;

    return VitalTileShell(
      accent: color,
      icon: Icons.nights_stay_rounded,
      image: QuickActionImages.sleep,
      title: 'Sleep Cycle',
      value: minutes > 0 ? '${h}h ${m}m' : '0h 0m',
      isEmpty: minutes <= 0,
      emptyMessage: 'No sleep data available',
      emptyIcon: Icons.bedtime_off_rounded,
      emptyLogLabel: 'Track Sleep',
      onEmptyLog: isToday
          ? () => openVitalLog(context, 'sleep', onLogged: onLogged)
          : null,
      onTap: () => openVitalPage(context, const SleepSummaryScreen()),
      details: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 10,
              color: color.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                bed != null ? timeFormat.format(bed) : '--',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '|',
              style: TextStyle(
                fontSize: 9,
                color: textColor.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.wb_sunny_outlined,
              size: 10,
              color: Colors.orange.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                wake != null ? timeFormat.format(wake) : '--',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ],
      chartPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      chart: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SleepStageRatioBar(
            deepRatio: ratio(deep),
            lightRatio: ratio(light),
            remRatio: ratio(rem),
            awakeRatio: ratio(awake),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stagePercent(ratio(deep), _deepColor, textColor),
              _stagePercent(ratio(light), _lightColor, textColor),
              _stagePercent(ratio(rem), _remColor, textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stagePercent(double ratio, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          '${(ratio * 100).round()}%',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SleepStageRatioBar extends StatelessWidget {
  final double deepRatio;
  final double lightRatio;
  final double remRatio;
  final double awakeRatio;

  const _SleepStageRatioBar({
    required this.deepRatio,
    required this.lightRatio,
    required this.remRatio,
    required this.awakeRatio,
  });

  @override
  Widget build(BuildContext context) {
    final total = deepRatio + lightRatio + remRatio + awakeRatio;
    if (total <= 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    Widget seg(double r, Color c) => Expanded(
      flex: ((r / total) * 100).round().clamp(1, 100),
      child: Container(color: c),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (deepRatio > 0) seg(deepRatio, SleepTile._deepColor),
            if (lightRatio > 0) seg(lightRatio, SleepTile._lightColor),
            if (remRatio > 0) seg(remRatio, SleepTile._remColor),
            if (awakeRatio > 0) seg(awakeRatio, SleepTile._awakeColor),
          ],
        ),
      ),
    );
  }
}

class _SleepSession {
  final DateTime bed;
  final DateTime wake;
  final int minutes;
  final double deep;
  final double light;
  final double rem;
  final double awake;

  const _SleepSession({
    required this.bed,
    required this.wake,
    required this.minutes,
    required this.deep,
    required this.light,
    required this.rem,
    required this.awake,
  });
}
