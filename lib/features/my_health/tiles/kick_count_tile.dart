import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'vital_tile_chrome.dart';
import 'package:allomom/config/quick_action_images.dart';

/// Baby kicks in AlloConnect's tile style: the day's total against the
/// count-to-10 goal, with the last 7 days as bars. Only meaningful in
/// pregnancy — renders nothing when [isPregnant] (default: the profile's
/// `MainController.instance.isPregnant`) is false.
class KickCountTile extends StatelessWidget {
  /// Overrides the day's total (otherwise summed from every kick entry
  /// recorded on [date]).
  final int? kicks;

  /// The latest kick entry, used when no total can be summed.
  final VitalsStreamResponse? vital;
  final int targetKicks;
  final DateTime date;
  final bool? isPregnant;
  final VoidCallback? onLogged;

  const KickCountTile({
    super.key,
    this.kicks,
    this.vital,
    this.targetKicks = 10,
    required this.date,
    this.isPregnant,
    this.onLogged,
  });

  static const _keys = ['kick_count', 'kicks'];
  static const _accent = Color(0xFFFF4E6A);

  @override
  Widget build(BuildContext context) {
    final main = MainController.instance;
    if (!(isPregnant ?? main.isPregnant)) return const SizedBox.shrink();

    final isToday = vitalIsToday(date);
    final dayRows = vitalHistoryOnDay(_keys, date);
    final summed = dayRows.fold<double>(0, (s, v) => s + v.value).round();
    final total =
        kicks ??
        (dayRows.isNotEmpty
            ? summed
            : (vital != null && DateUtils.isSameDay(vital!.createdAt, date)
                  ? vital!.value.round()
                  : 0));
    final last = dayRows.isNotEmpty ? dayRows.last : vital;
    final goal = targetKicks > 0 ? targetKicks : 10;
    final reached = total >= goal;
    final color = reached ? const Color(0xFF00C853) : _accent;

    // Daily totals for the 7 days ending on [date].
    final week = List<double>.generate(7, (i) {
      final day = DateTime(date.year, date.month, date.day - (6 - i));
      return vitalHistoryOnDay(
        _keys,
        day,
      ).fold<double>(0, (s, v) => s + v.value);
    });
    if (kicks != null) week[6] = kicks!.toDouble();

    final gestWeek = main.currentGestationalWeek;
    final sessions = dayRows.length;

    return VitalTileShell(
      accent: color,
      icon: Icons.pets_rounded,
      image: QuickActionImages.kickCount,
      title: 'Kick Counter',
      value: total > 0 ? '$total' : '0',
      unit: 'kicks',
      lastUpdatedAt: total > 0 ? last?.createdAt : null,
      isEmpty: total <= 0,
      emptyMessage: isToday ? 'No kicks counted yet' : 'No kicks logged',
      emptyIcon: Icons.pets_outlined,
      emptyLogLabel: 'Log Kicks',
      onEmptyLog: isToday
          ? () => openVitalLog(context, 'kick_count', onLogged: onLogged)
          : null,
      onTap: () => openVitalPage(context, const KickCounterPage()),
      details: [
        VitalTileDetail(
          'Goal: $goal kicks${sessions > 0 ? ' • $sessions session${sessions == 1 ? '' : 's'}' : ''}',
        ),
        VitalTileDetail(
          reached
              ? 'Goal reached'
              : (gestWeek > 0
                    ? 'Week $gestWeek of pregnancy'
                    : 'Keep counting'),
          color: color,
          topGap: 4,
        ),
      ],
      action: isToday
          ? VitalTileActionChip(
              color: color,
              label: 'COUNT',
              pulse: true,
              onTap: () => openVitalPage(context, const KickCounterPage()),
            )
          : null,
      chart: Column(
        children: [
          Expanded(
            child: MiniBarChart(values: week, color: color, spacing: 4),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = DateTime(date.year, date.month, date.day - (6 - i));
              return Text(
                DateFormat('E').format(day).substring(0, 1),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: i == 6 ? 0.9 : 0.45),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
