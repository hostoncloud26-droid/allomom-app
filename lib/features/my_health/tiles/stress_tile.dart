import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/stress/stress_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';
import 'package:allomom/config/quick_action_images.dart';

/// AlloConnect's stress-load tile: a 0–100 score, its label and a sparkline.
class StressTile extends StatelessWidget {
  final VitalsStreamResponse? vital;

  /// Overrides the score read from [vital].
  final int? stress;
  final DateTime date;
  final VoidCallback? onLogged;

  const StressTile({
    super.key,
    this.vital,
    this.stress,
    required this.date,
    this.onLogged,
  });

  static int _normalize(int raw) => raw <= 0 ? 0 : raw.clamp(1, 100).toInt();

  static Color _color(int s) {
    if (s <= 0) return Colors.blueGrey.shade400;
    if (s <= 15) return const Color(0xFF10B981);
    if (s <= 30) return const Color(0xFF84CC16);
    if (s <= 50) return const Color(0xFF0EA5E9);
    if (s <= 70) return const Color(0xFFF59E0B);
    if (s <= 85) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  static String _label(int s) {
    if (s <= 0) return 'No Stress Data';
    if (s <= 15) return 'Calm';
    if (s <= 30) return 'Relaxed';
    if (s <= 50) return 'Normal';
    if (s <= 70) return 'Slightly tense';
    if (s <= 85) return 'Tense';
    return 'Overwhelmed';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final value = _normalize(stress ?? vital?.value.round() ?? 0);
    final color = _color(value);

    return VitalTileShell(
      accent: color,
      icon: Icons.psychology_alt_rounded,
      image: QuickActionImages.stress,
      title: 'Stress Load',
      value: value > 0 ? '$value' : '--',
      unit: '/100',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: value <= 0,
      emptyMessage: 'No stress score recorded',
      emptyIcon: Icons.spa_outlined,
      emptyLogLabel: 'Log Stress',
      onEmptyLog: isToday
          ? () => openVitalLog(context, 'stress', onLogged: onLogged)
          : null,
      onTap: () => openVitalPage(context, const StressSummaryScreen()),
      details: [VitalTileDetail(_label(value), color: color)],
      chart: MiniSparklineChart(
        data: vitalTrendUpTo(const ['stress'], date),
        color: color,
        height: 50,
      ),
    );
  }
}
