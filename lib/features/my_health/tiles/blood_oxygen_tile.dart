import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_analysis_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';
import 'package:allomom/config/quick_action_images.dart';

/// AlloConnect's blood-oxygen tile: SpO₂ % with a sparkline. The "START"
/// chip measures live on the connected AlloWear, as on AlloConnect.
class BloodOxygenTile extends StatelessWidget {
  final VitalsStreamResponse? vital;

  /// Overrides the SpO₂ read from [vital].
  final int? spo2;
  final DateTime date;
  final VoidCallback? onLogged;

  const BloodOxygenTile({
    super.key,
    this.vital,
    this.spo2,
    required this.date,
    this.onLogged,
  });

  Color _color(int spo2) {
    if (spo2 <= 0) return const Color(0xFF00B8D4);
    if (spo2 >= 95) return const Color(0xFF00B8D4);
    if (spo2 >= 90) return const Color(0xFF4CAF50);
    if (spo2 >= 85) return const Color(0xFFFFB300);
    return const Color(0xFFFF5252);
  }

  String _status(int spo2) {
    if (spo2 >= 95) return 'Normal';
    if (spo2 >= 90) return 'Slightly low';
    return 'Low — check again';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final value = spo2 ?? vital?.value.round() ?? 0;
    final color = _color(value);
    void log() => openVitalLog(context, 'blood_oxygen', onLogged: onLogged);

    return VitalTileShell(
      accent: color,
      icon: Icons.opacity_rounded,
      image: QuickActionImages.bloodOxygen,
      title: 'Blood Oxygen',
      value: value > 0 ? '$value' : '--',
      unit: '% SpO₂',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: value <= 0,
      emptyMessage: 'No SpO₂ reading recorded',
      emptyIcon: Icons.opacity_rounded,
      emptyLogLabel: 'Log SpO₂',
      onEmptyLog: isToday ? log : null,
      onTap: () => openVitalPage(context, const BloodOxygenSummaryScreen()),
      details: [VitalTileDetail(_status(value), color: color)],
      // AlloConnect's "START": a live reading from the connected AlloWear.
      action: isToday
          ? VitalTileActionChip(
              color: color,
              label: 'START',
              icon: Icons.play_arrow_rounded,
              onTap: () =>
                  showBloodOxygenMeasureSheet(context, onDone: onLogged),
            )
          : null,
      chart: MiniSparklineChart(
        data: vitalTrendUpTo(const ['blood_oxygen', 'spo2'], date),
        color: color,
        height: 50,
      ),
    );
  }
}
