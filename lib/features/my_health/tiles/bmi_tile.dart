import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/body_composition/body_composition_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';

/// AlloConnect's BMI tile: the score, weight • height and category on the
/// left, a weight sparkline on the right. Keeps Allomom's weight-gain line
/// (change since the first recorded weight).
class BMITile extends StatelessWidget {
  /// Latest `weight` reading on or before [date].
  final VitalsStreamResponse? weightVital;

  /// Latest `height` reading on or before [date].
  final VitalsStreamResponse? heightVital;

  /// Override the values read from the vitals (kg / cm, or metres).
  final double? weightKg;
  final double? heightCm;
  final DateTime date;
  final VoidCallback? onLogged;

  const BMITile({
    super.key,
    this.weightVital,
    this.heightVital,
    this.weightKg,
    this.heightCm,
    required this.date,
    this.onLogged,
  });

  Color _color(double bmi) {
    if (bmi <= 0) return const Color(0xFF00C853);
    if (bmi < 18.5) return Colors.blue.shade400;
    if (bmi < 25) return const Color(0xFF00E676);
    if (bmi < 30) return Colors.amber.shade400;
    return const Color(0xFFFF5252);
  }

  String _category(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy Progress';
    if (bmi < 30) return 'Overweight';
    return 'Obese Scale';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final weight = weightKg ?? weightVital?.value ?? 0.0;
    double height =
        heightCm ??
        heightVital?.value ??
        vitalDataNum(weightVital, 'height')?.toDouble() ??
        0.0;
    if (height > 0 && height < 3) height *= 100; // metres → cm
    final heightM = height / 100;
    final bmi = weight > 0 && heightM > 0 ? weight / (heightM * heightM) : 0.0;
    final color = _color(bmi);

    final weights = vitalHistoryUpTo(const ['weight'], date);
    String? gain;
    if (weights.length >= 2) {
      final diff = weights.last.value - weights.first.value;
      gain =
          '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg since first log';
    }
    final trend = weights.map((v) => v.value).toList();

    return VitalTileShell(
      accent: color,
      icon: Icons.scale_rounded,
      title: 'BMI',
      value: bmi > 0 ? bmi.toStringAsFixed(1) : '--',
      unit: 'score',
      lastUpdatedAt: weightVital?.createdAt,
      isEmpty: weight <= 0,
      emptyMessage: 'No weight recorded',
      emptyIcon: Icons.monitor_weight_outlined,
      emptyLogLabel: 'Log Weight',
      onEmptyLog: isToday
          ? () => openVitalLog(context, 'weight', onLogged: onLogged)
          : null,
      onTap: () => openVitalPage(context, const BodyCompositionSummaryScreen()),
      details: [
        VitalTileDetail(
          height > 0
              ? '${weight.toStringAsFixed(1)} kg • ${height.toStringAsFixed(0)} cm'
              : '${weight.toStringAsFixed(1)} kg • add height',
        ),
        if (bmi > 0) VitalTileDetail(_category(bmi), color: color, topGap: 4),
        if (gain != null) VitalTileDetail(gain, topGap: 4),
      ],
      chart: MiniSparklineChart(
        data: trend.length > 12 ? downsampleTrendData(trend) : trend,
        color: color,
        height: 50,
      ),
    );
  }
}
