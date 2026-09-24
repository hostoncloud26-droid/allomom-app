import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/blood_pressure/blood_pressure_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';

/// AlloConnect's blood-pressure tile: sys/dia with pulse on the left and
/// overlaid systolic / diastolic sparklines on the right.
class BloodPressureTile extends StatelessWidget {
  final VitalsStreamResponse? vital;

  /// Override the values read from [vital]'s data.
  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final DateTime date;
  final VoidCallback? onLogged;

  const BloodPressureTile({
    super.key,
    this.vital,
    this.systolic,
    this.diastolic,
    this.pulse,
    required this.date,
    this.onLogged,
  });

  Color _color(int sys, int dia) {
    if (sys <= 0) return const Color(0xFFFF5252);
    if (sys < 120 && dia < 80) return const Color(0xFF00E676);
    if (sys < 130 && dia < 80) return Colors.cyan.shade400;
    if (sys < 140 || dia < 90) return Colors.amber.shade400;
    return const Color(0xFFFF5252);
  }

  String _status(int sys, int dia) {
    if (sys < 120 && dia < 80) return 'Normal';
    if (sys < 130 && dia < 80) return 'Elevated';
    if (sys < 140 || dia < 90) return 'High — stage 1';
    return 'High — stage 2';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final sys =
        systolic ??
        vitalDataNum(vital, 'systolic')?.round() ??
        vital?.value.round() ??
        0;
    final dia = diastolic ?? vitalDataNum(vital, 'diastolic')?.round() ?? 0;
    final pulseVal = pulse ?? vitalDataNum(vital, 'pulse')?.round();
    final hasReading = sys > 0 && dia > 0;
    final color = _color(sys, dia);

    const keys = ['blood_pressure'];
    final sysTrend = vitalTrendUpTo(
      keys,
      date,
      valueOf: (v) => (vitalDataNum(v, 'systolic') ?? v.value).toDouble(),
    );
    final diaTrend = vitalTrendUpTo(
      keys,
      date,
      valueOf: (v) => (vitalDataNum(v, 'diastolic') ?? 80).toDouble(),
    );

    return VitalTileShell(
      accent: color,
      icon: Icons.favorite_outline_rounded,
      title: 'Blood Pressure',
      value: hasReading ? '$sys/$dia' : '--/--',
      unit: 'mmHg',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: !hasReading,
      emptyMessage: 'No blood pressure recorded',
      emptyIcon: Icons.favorite_border_rounded,
      emptyLogLabel: 'Log BP',
      onEmptyLog: isToday
          ? () => openVitalLog(context, 'blood_pressure', onLogged: onLogged)
          : null,
      onTap: () => openVitalPage(context, const BloodPressureSummaryScreen()),
      details: [
        if (pulseVal != null && pulseVal > 0)
          VitalTileDetail('Pulse: $pulseVal bpm'),
        VitalTileDetail(_status(sys, dia), color: color, topGap: 4),
      ],
      chart: Stack(
        children: [
          MiniSparklineChart(
            data: diaTrend,
            color: Colors.blue.shade300,
            height: 50,
          ),
          MiniSparklineChart(data: sysTrend, color: color, height: 50),
        ],
      ),
    );
  }
}
