import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/temperature/temperature_analysis_bottom_sheet.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';

/// AlloConnect's temperature tile: the latest skin temperature from the band,
/// with a trend and a "START" chip that measures it live on the AlloWear.
class TemperatureTile extends StatelessWidget {
  final VitalsStreamResponse? vital;
  final DateTime date;
  final VoidCallback? onLogged;

  const TemperatureTile({
    super.key,
    this.vital,
    required this.date,
    this.onLogged,
  });

  static const Color _accent = Color(0xFFFF8A3D);

  Color _color(double celsius) {
    if (celsius <= 0) return _accent;
    if (celsius < 35.5) return Colors.blue.shade400;
    if (celsius <= 37.5) return const Color(0xFF00C853);
    return const Color(0xFFFF5252);
  }

  String _status(double celsius) {
    if (celsius < 35.5) return 'Below usual range';
    if (celsius <= 37.5) return 'Normal';
    return 'Raised — check again';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final value = vital?.value ?? 0;
    final color = _color(value);
    void measure() => showTemperatureMeasureSheet(context, onDone: onLogged);

    return VitalTileShell(
      accent: color,
      icon: Icons.thermostat_rounded,
      title: 'Temperature',
      value: value > 0 ? value.toStringAsFixed(1) : '--',
      unit: '°C',
      lastUpdatedAt: vital?.createdAt,
      isEmpty: value <= 0,
      emptyMessage: 'No temperature recorded',
      emptyIcon: Icons.thermostat_rounded,
      emptyLogLabel: 'Measure',
      onEmptyLog: isToday ? measure : null,
      onTap: isToday ? measure : null,
      details: [if (value > 0) VitalTileDetail(_status(value), color: color)],
      action: isToday
          ? VitalTileActionChip(
              color: color,
              label: 'START',
              icon: Icons.play_arrow_rounded,
              onTap: measure,
            )
          : null,
      chart: MiniSparklineChart(
        data: vitalTrendUpTo(const ['temperature'], date),
        color: color,
        height: 50,
      ),
    );
  }
}
