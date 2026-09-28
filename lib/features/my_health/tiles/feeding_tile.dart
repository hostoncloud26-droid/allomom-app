import 'package:flutter/material.dart';

import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';
import 'package:allomom/config/quick_action_images.dart';

/// Feeding tracker in AlloConnect's tile style: the latest session (value,
/// unit, type) with the day's sessions as 24-hour bars. Sessions mix units
/// (mins vs ml), so — as on Allomom's current tile — the headline is the
/// latest session rather than a total.
class FeedingTile extends StatelessWidget {
  /// The latest feeding entry for [date] (otherwise read from the
  /// controller's history for that day).
  final VitalsStreamResponse? vital;
  final DateTime date;
  final VoidCallback? onLogged;

  const FeedingTile({super.key, this.vital, required this.date, this.onLogged});

  static const _accent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final isToday = vitalIsToday(date);
    final dayRows = vitalHistoryOnDay(const ['feeding'], date);
    final latest = dayRows.isNotEmpty ? dayRows.last : vital;
    final hasData = latest != null && latest.value > 0;

    final value = !hasData
        ? '--'
        : (latest.value % 1 == 0
              ? latest.value.toInt().toString()
              : latest.value.toStringAsFixed(1));
    final unit = latest != null && latest.unit.isNotEmpty
        ? latest.unit
        : 'mins';
    final type = latest?.data?['type']?.toString();

    // Minutes and millilitres per session, summed for the day.
    double mins = 0;
    double ml = 0;
    final hourly = List<double>.filled(24, 0);
    for (final r in dayRows) {
      if (r.unit.toLowerCase().contains('ml')) {
        ml += r.value;
      } else {
        mins += r.value;
      }
      hourly[r.createdAt.hour] += 1;
    }
    if (dayRows.isEmpty && hasData) hourly[latest.createdAt.hour] = 1;
    final sessions = dayRows.isNotEmpty ? dayRows.length : (hasData ? 1 : 0);
    final totals = [
      if (mins > 0) '${mins.round()} min',
      if (ml > 0) '${ml.round()} ml',
    ].join(' + ');

    return VitalTileShell(
      accent: _accent,
      icon: Icons.local_drink_rounded,
      image: QuickActionImages.feeding,
      title: 'Feeding Tracker',
      value: value,
      unit: unit,
      lastUpdatedAt: hasData ? latest.createdAt : null,
      isEmpty: !hasData,
      emptyMessage: isToday ? 'No feeds logged yet' : 'No feeds logged',
      emptyIcon: Icons.no_drinks_outlined,
      emptyLogLabel: 'Log Feed',
      onEmptyLog: isToday
          ? () => openVitalLog(context, 'feeding', onLogged: onLogged)
          : null,
      onTap: () => openVitalPage(context, const FeedingTrackerPage()),
      details: [
        if (type != null && type.isNotEmpty) VitalTileDetail(type),
        VitalTileDetail(
          '$sessions feed${sessions == 1 ? '' : 's'}${totals.isNotEmpty ? ' • $totals' : ''}',
          color: _accent,
          topGap: 4,
        ),
      ],
      action: isToday
          ? VitalTileActionChip(
              color: _accent,
              label: 'START',
              pulse: true,
              onTap: () => openVitalPage(context, const FeedingTrackerPage()),
            )
          : null,
      chart: MiniBarChart(values: hourly, color: _accent),
    );
  }
}
