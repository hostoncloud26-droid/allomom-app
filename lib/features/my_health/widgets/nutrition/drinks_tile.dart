import 'package:flutter/material.dart';

import 'package:allomom/models/vitals_stream_model.dart';

import 'health_tile_parts.dart';

/// Drinks tile ("Drinks & Brews") in AlloConnect's style: cups had that day,
/// their kcal and the latest one, with Tea / Coffee / Other quick logs below.
class DrinksTile extends StatelessWidget {
  /// That day's `drinks` rows, newest first.
  final List<VitalsStreamResponse> entries;
  final bool readOnly;
  final VoidCallback onOpen;

  /// Called with 'Tea', 'Coffee' or 'Other' and that chip's icon.
  final void Function(String name, IconData icon) onLog;

  static const Color color = Color(0xFFFF8F00); // Colors.amber.shade800

  const DrinksTile({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onLog,
    this.readOnly = false,
  });

  int get _count => entries.fold<int>(0, (sum, v) {
        final c = v.data?['count'];
        return sum + (c is num && c > 0 ? c.toInt() : 1);
      });

  String _latestDetails() {
    final d = entries.first.data;
    final s = (d?['details'] ?? d?['drink'])?.toString().trim();
    return (s == null || s.isEmpty) ? 'Warm Sip' : s;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = entries.isNotEmpty;
    final textColor = tileTextColor(context);

    return HealthTilePressable(
      onTap: onOpen,
      child: HealthTileCard(
        key: ValueKey(hasData ? 'tracked_drinks' : 'empty_drinks'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HealthTileHeader(
              title: 'Drinks & Brews',
              accent: color,
              muted: !hasData,
              trailing: hasData
                  ? [HealthTileBadge(text: '$_count HAD', color: color)]
                  : const [],
            ),
            SizedBox(height: hasData ? 18 : 16),
            if (hasData)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HealthTileBigValue(
                    value: '$_count',
                    unit: _count == 1 ? 'drink' : 'drinks',
                    unitSize: 16,
                    unitAlpha: 0.8,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entries.fold<double>(0, (s, v) => s + v.value).round()} kcal total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latest: ${_latestDetails()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              )
            else
              HealthTileEmptyCopy(
                title: readOnly ? 'No Drinks logged' : 'Track Drinks',
                hint:
                    'Log hot sips & cold brews to balance your calorie budget.',
              ),
            if (!readOnly) ...[
              const SizedBox(height: 20),
              Container(height: 1, color: tileBorderColor(context)),
              const SizedBox(height: 16),
              Row(
                children: [
                  HealthTileQuickAction(
                    label: 'Tea',
                    icon: Icons.emoji_food_beverage_rounded,
                    color: Colors.teal.shade600,
                    onTap: () =>
                        onLog('Tea', Icons.emoji_food_beverage_rounded),
                  ),
                  const SizedBox(width: 8),
                  HealthTileQuickAction(
                    label: 'Coffee',
                    icon: Icons.coffee_rounded,
                    color: Colors.brown.shade400,
                    onTap: () => onLog('Coffee', Icons.coffee_rounded),
                  ),
                  const SizedBox(width: 8),
                  HealthTileQuickAction(
                    label: 'Other',
                    icon: Icons.local_bar_rounded,
                    color: Colors.orange.shade700,
                    onTap: () => onLog('Other', Icons.local_bar_rounded),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
