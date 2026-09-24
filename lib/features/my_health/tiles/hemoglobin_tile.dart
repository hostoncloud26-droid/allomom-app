import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/hemoglobin/hemoglobin_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';

/// Hemoglobin in AlloConnect's tile style: g/dL with a sparkline. Hemoglobin
/// is a standing value, so pass the latest reading on or before [date].
class HemoglobinTile extends StatelessWidget {
  final VitalsStreamResponse? vital;

  /// Overrides the g/dL read from [vital].
  final double? hemoglobin;
  final DateTime date;
  final VoidCallback? onLogged;

  const HemoglobinTile({
    super.key,
    this.vital,
    this.hemoglobin,
    required this.date,
    this.onLogged,
  });

  // Pregnancy thresholds: ≥ 11 adequate, 10–11 mild, < 10 low.
  Color _color(double g) {
    if (g <= 0) return const Color(0xFF9333EA);
    if (g >= 11) return const Color(0xFF10B981);
    if (g >= 10) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _status(double g) {
    if (g >= 11) return 'Adequate';
    if (g >= 10) return 'Mildly low';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final value = hemoglobin ?? vital?.value ?? 0.0;
    final color = _color(value);
    void log() => openVitalLog(context, 'hemoglobin', onLogged: onLogged);

    return VitalTileShell(
      accent: color,
      icon: Icons.water_drop_rounded,
      title: 'Hemoglobin',
      value: value > 0 ? value.toStringAsFixed(1) : '--',
      unit: 'g/dL',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: value <= 0,
      emptyMessage: 'No hemoglobin recorded',
      emptyIcon: Icons.water_drop_outlined,
      emptyLogLabel: 'Log Hb',
      onEmptyLog: isToday ? log : null,
      onTap: () => openVitalPage(context, const HemoglobinSummaryScreen()),
      details: [VitalTileDetail(_status(value), color: color)],
      action: value > 0 && isToday
          ? VitalTileActionChip(color: color, onTap: log)
          : null,
      chart: MiniSparklineChart(
        data: vitalTrendUpTo(const ['hemoglobin'], date),
        color: color,
        height: 50,
      ),
    );
  }
}
