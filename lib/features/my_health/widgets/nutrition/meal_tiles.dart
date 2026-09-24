import 'package:flutter/material.dart';

import 'package:allomom/models/vitals_stream_model.dart';

import 'health_tile_parts.dart';

String? _detailsOf(VitalsStreamResponse v) {
  final d = v.data;
  if (d == null) return null;
  for (final k in const ['items', 'details', 'drink']) {
    final s = d[k]?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
  }
  return null;
}

/// Breakfast / lunch / dinner tile in AlloConnect's style: the day's kcal as
/// a big figure and the latest description once something is logged, a
/// "Track Breakfast"-style call to action otherwise.
class MealTile extends StatelessWidget {
  final String label;
  final Color color;

  /// That day's rows for this meal, newest first.
  final List<VitalsStreamResponse> entries;

  final String emptyHint;
  final String fallbackDetails;
  final bool readOnly;
  final VoidCallback onOpen;
  final VoidCallback onLog;

  const MealTile({
    super.key,
    required this.label,
    required this.color,
    required this.entries,
    required this.emptyHint,
    required this.fallbackDetails,
    required this.onOpen,
    required this.onLog,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = entries.isNotEmpty;
    return HealthTilePressable(
      onTap: onOpen,
      child: hasData ? _tracked(context) : _empty(context),
    );
  }

  Widget _tracked(BuildContext context) {
    final textColor = tileTextColor(context);
    final kcal = entries.fold<double>(0, (s, v) => s + v.value);
    final details = _detailsOf(entries.first) ?? fallbackDetails;

    return HealthTileCard(
      key: const ValueKey('tracked'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthTileHeader(
            title: label,
            accent: color,
            trailing: [HealthTileBadge(text: 'TRACKED', color: color)],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HealthTileBigValue(value: '${kcal.round()}', unit: 'kcal'),
                    const SizedBox(height: 8),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              if (!readOnly)
                HealthTilePill(
                  label: 'Add',
                  icon: Icons.add_rounded,
                  color: color,
                  onTap: onLog,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return HealthTileCard(
      key: const ValueKey('empty'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthTileHeader(title: label, accent: color, muted: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HealthTileEmptyCopy(
                  title: readOnly ? 'No $label logged' : 'Track $label',
                  hint: emptyHint,
                ),
              ),
              const SizedBox(width: 16),
              if (!readOnly)
                HealthTilePill(
                  label: 'Log',
                  icon: Icons.add_rounded,
                  color: color,
                  filled: true,
                  onTap: onLog,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Snacks tile: how many snacks were had that day, their total kcal and the
/// latest one.
class SnacksTile extends StatelessWidget {
  /// That day's `snacks` rows, newest first.
  final List<VitalsStreamResponse> entries;
  final bool readOnly;
  final VoidCallback onOpen;
  final VoidCallback onLog;

  static const Color color = Color(0xFFEC407A); // Colors.pink.shade400

  const SnacksTile({
    super.key,
    required this.entries,
    required this.onOpen,
    required this.onLog,
    this.readOnly = false,
  });

  /// Portions logged, honouring `data['count']` where a flow wrote one.
  int get _count => entries.fold<int>(0, (sum, v) {
        final c = v.data?['count'];
        return sum + (c is num && c > 0 ? c.toInt() : 1);
      });

  @override
  Widget build(BuildContext context) {
    return HealthTilePressable(
      onTap: onOpen,
      child: entries.isNotEmpty ? _tracked(context) : _empty(context),
    );
  }

  Widget _tracked(BuildContext context) {
    final textColor = tileTextColor(context);
    final count = _count;
    final kcal = entries.fold<double>(0, (s, v) => s + v.value);
    final details = _detailsOf(entries.first) ?? 'Mindful Snack';

    return HealthTileCard(
      key: const ValueKey('tracked'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthTileHeader(
            title: 'Snacks',
            accent: color,
            trailing: [HealthTileBadge(text: '$count HAD', color: color)],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HealthTileBigValue(
                      value: '$count',
                      unit: count == 1 ? 'snack' : 'snacks',
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
                          '${kcal.round()} kcal total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Latest: $details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              if (!readOnly)
                HealthTilePill(
                  label: 'Add',
                  icon: Icons.add_rounded,
                  color: color,
                  onTap: onLog,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return HealthTileCard(
      key: const ValueKey('empty'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HealthTileHeader(title: 'Snacks', accent: color, muted: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HealthTileEmptyCopy(
                  title: readOnly ? 'No Snacks logged' : 'Track Snacks',
                  hint: 'Snack mindfully to keep your energy balanced.',
                ),
              ),
              const SizedBox(width: 16),
              if (!readOnly)
                HealthTilePill(
                  label: 'Log',
                  icon: Icons.add_rounded,
                  color: color,
                  filled: true,
                  onTap: onLog,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
