import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/hrv/hrv_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';

/// Heart-rate variability in AlloConnect's tile style: ms with a sparkline.
class HrvTile extends StatelessWidget {
  final VitalsStreamResponse? vital;

  /// Overrides the HRV (ms) read from [vital].
  final int? hrvMs;
  final DateTime date;
  final VoidCallback? onLogged;

  const HrvTile({
    super.key,
    this.vital,
    this.hrvMs,
    required this.date,
    this.onLogged,
  });

  Color _color(int ms) {
    if (ms <= 0) return const Color(0xFF8B5CF6);
    if (ms >= 50) return const Color(0xFF10B981);
    if (ms >= 30) return const Color(0xFF8B5CF6);
    return const Color(0xFFF59E0B);
  }

  String _status(int ms) {
    if (ms >= 50) return 'Well recovered';
    if (ms >= 30) return 'Balanced';
    return 'Low — rest up';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final value = hrvMs ?? vital?.value.round() ?? 0;
    final color = _color(value);
    void log() => openVitalLog(context, 'hrv', onLogged: onLogged);

    return VitalTileShell(
      accent: color,
      icon: Icons.monitor_heart_rounded,
      title: 'Heart Rate Variability',
      value: value > 0 ? '$value' : '--',
      unit: 'ms',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: value <= 0,
      emptyMessage: 'No HRV reading recorded',
      emptyIcon: Icons.monitor_heart_outlined,
      emptyLogLabel: 'Log HRV',
      onEmptyLog: isToday ? log : null,
      onTap: () => openVitalPage(context, const HrvSummaryScreen()),
      details: [VitalTileDetail(_status(value), color: color)],
      action: value > 0 && isToday
          ? VitalTileActionChip(color: color, onTap: log)
          : null,
      chart: MiniSparklineChart(
        data: vitalTrendUpTo(const ['hrv'], date),
        color: color,
        height: 50,
      ),
    );
  }
}
