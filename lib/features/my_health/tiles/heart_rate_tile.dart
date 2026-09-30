import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/heart_rate/heart_rate_analysis_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/heart_rate_summary_screen.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';
import 'package:allomom/config/quick_action_images.dart';

/// AlloConnect's heart-rate tile: bpm with a sparkline of recent readings,
/// and its "START" chip — a live AlloWear reading, or the phone camera when no
/// band is connected. Typing a reading in stays on the empty state and the
/// summary screen's Add.
class HeartRateTile extends StatelessWidget {
  final VitalsStreamResponse? vital;

  /// Overrides the bpm read from [vital].
  final int? bpm;
  final DateTime date;
  final VoidCallback? onLogged;

  const HeartRateTile({
    super.key,
    this.vital,
    this.bpm,
    required this.date,
    this.onLogged,
  });

  Color _color(int bpm) {
    if (bpm <= 0) return const Color(0xFFFF5252);
    if (bpm < 60) return Colors.blue.shade400;
    if (bpm <= 100) return const Color(0xFF00E676);
    if (bpm <= 120) return Colors.orange.shade400;
    return const Color(0xFFFF5252);
  }

  String _status(int bpm) {
    if (bpm < 60) return 'Below resting range';
    if (bpm <= 100) return 'Normal resting rate';
    return 'Elevated';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final value = bpm ?? vital?.value.round() ?? 0;
    final color = _color(value);
    final canLog = isToday;
    void log() => openVitalLog(context, 'heart_rate', onLogged: onLogged);

    return VitalTileShell(
      accent: color,
      icon: Icons.favorite_rounded,
      image: QuickActionImages.heartRate,
      title: 'Heart Rate',
      value: value > 0 ? '$value' : '--',
      unit: 'bpm',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: value <= 0,
      emptyMessage: 'No heart rate recorded',
      emptyIcon: Icons.favorite_border_rounded,
      emptyLogLabel: 'Log Heart Rate',
      onEmptyLog: canLog ? log : null,
      onTap: () => openVitalPage(context, const HeartRateSummaryScreen()),
      details: [VitalTileDetail(_status(value), color: color)],
      action: canLog
          ? VitalTileActionChip(
              color: color,
              label: 'START',
              icon: Icons.play_arrow_rounded,
              onTap: () => showHeartRateMeasureSheet(context, onDone: onLogged),
            )
          : null,
      chart: MiniSparklineChart(
        data: vitalTrendUpTo(const ['heart_rate'], date),
        color: color,
        height: 50,
      ),
    );
  }
}
