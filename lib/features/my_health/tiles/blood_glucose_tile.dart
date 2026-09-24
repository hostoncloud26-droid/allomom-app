import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/blood_glucose/blood_glucose_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';

/// Blood glucose in AlloConnect's tile style: mg/dL, meal phase and a
/// sparkline. Allomom stores it under `glucose` (older rows:
/// `blood_glucose`); both are read.
class BloodGlucoseTile extends StatelessWidget {
  final VitalsStreamResponse? vital;

  /// Overrides the mg/dL read from [vital].
  final double? glucose;
  final DateTime date;
  final VoidCallback? onLogged;

  const BloodGlucoseTile({
    super.key,
    this.vital,
    this.glucose,
    required this.date,
    this.onLogged,
  });

  static const _keys = ['glucose', 'blood_glucose'];

  bool _isFasting(String? phase) =>
      phase == null || phase.toLowerCase().contains('fast');

  Color _color(double g, bool fasting) {
    if (g <= 0) return const Color(0xFFF59E0B);
    if (g < 70) return Colors.blue.shade400;
    final limit = fasting ? 100 : 140;
    if (g <= limit) return const Color(0xFF10B981);
    if (g <= limit + 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _status(double g, bool fasting) {
    if (g < 70) return 'Low';
    return g <= (fasting ? 100 : 140) ? 'Normal' : 'Elevated';
  }

  String _phaseLabel(String? phase) {
    if (phase == null || phase.isEmpty) return 'Fasting';
    final s = phase.replaceAll('_', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    // Fall back to the day's own row when the caller's map only knew
    // `blood_glucose` and the entry was stored under `glucose`.
    final reading =
        vital ??
        () {
          final day = vitalHistoryOnDay(_keys, date);
          return day.isEmpty ? null : day.last;
        }();
    final value = glucose ?? reading?.value ?? 0.0;
    final phase = reading?.data?['mealPhase']?.toString();
    final fasting = _isFasting(phase);
    final color = _color(value, fasting);
    void log() => openVitalLog(context, 'glucose', onLogged: onLogged);

    return VitalTileShell(
      accent: color,
      icon: Icons.bloodtype_rounded,
      title: 'Blood Glucose',
      value: value > 0 ? value.toStringAsFixed(0) : '--',
      unit: 'mg/dL',
      lastUpdatedAt: reading?.createdAt,
      isEmpty: value <= 0,
      emptyMessage: 'No glucose reading recorded',
      emptyIcon: Icons.bloodtype_outlined,
      emptyLogLabel: 'Log Glucose',
      onEmptyLog: isToday ? log : null,
      onTap: () => openVitalPage(context, const BloodGlucoseSummaryScreen()),
      details: [
        VitalTileDetail(_phaseLabel(phase)),
        VitalTileDetail(_status(value, fasting), color: color, topGap: 4),
      ],
      chart: MiniSparklineChart(
        data: vitalTrendUpTo(_keys, date),
        color: color,
        height: 50,
      ),
    );
  }
}
