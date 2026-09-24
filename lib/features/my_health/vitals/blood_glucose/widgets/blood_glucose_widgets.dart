// Shared pieces of the blood glucose Day / Week / Month views, styled after
// AlloConnect's blood oxygen and blood pressure views.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../blood_glucose_entry_sheet.dart';
import '../models/blood_glucose_models.dart';

/// Glucose rows (both `glucose` and legacy `blood_glucose`) between [from]
/// and [to], newest first.
Future<List<VitalsStreamResponse>> loadGlucoseHistory(
  DateTime from,
  DateTime to,
) async {
  final vitals = HealthVitalsController.instance;
  final results = <VitalsStreamResponse>[];
  final seen = <String>{};
  for (final key in kGlucoseKeys) {
    final rows = await vitals.getVitalsHistory(
      vitals.userId,
      key,
      fromDate: from,
      toDate: to,
    );
    for (final r in rows) {
      if (seen.add(r.id)) results.add(r);
    }
  }
  results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return results;
}

BoxDecoration glucoseCardDecoration(bool isDark, {double radius = 24}) =>
    BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
      ),
    );

String formatMgDl(double? v) => v == null ? '--' : v.toStringAsFixed(0);

class GlucoseSectionTitle extends StatelessWidget {
  final String text;
  const GlucoseSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}

class GlucoseStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const GlucoseStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Average / Fasting avg / Post-meal avg / In target, the stats row every
/// glucose view shows.
class GlucoseStatGrid extends StatelessWidget {
  final GlucoseStats stats;
  final String averageLabel;

  const GlucoseStatGrid({
    super.key,
    required this.stats,
    this.averageLabel = 'Average',
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        GlucoseStatCard(
          label: averageLabel,
          value: '${formatMgDl(stats.avg)} mg/dL',
          icon: Icons.analytics_outlined,
          color: Colors.blue,
        ),
        GlucoseStatCard(
          label: 'Fasting avg (< ${kGlucoseFastingTarget.toInt()})',
          value: '${formatMgDl(stats.fastingAvg)} mg/dL',
          icon: Icons.wb_sunny_rounded,
          color: kGlucoseColor,
        ),
        GlucoseStatCard(
          label: 'Post-meal avg (< ${kGlucosePostMealTarget.toInt()})',
          value: '${formatMgDl(stats.postMealAvg)} mg/dL',
          icon: Icons.restaurant_rounded,
          color: const Color(0xFF10B981),
        ),
        GlucoseStatCard(
          label: 'Readings in target',
          value: '${stats.inTargetPercent.toInt()}%',
          icon: Icons.track_changes_rounded,
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}

class GlucoseInsightItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const GlucoseInsightItem({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart insights for a set of readings, gestational-diabetes framing.
List<Widget> glucoseInsightsFor(GlucoseStats stats) {
  final items = <Widget>[];
  final readings = stats.readings;
  final lows = readings.where((r) => r.category == GlucoseCategory.low);
  final highs = readings.where(
    (r) =>
        r.category == GlucoseCategory.aboveTarget ||
        r.category == GlucoseCategory.high,
  );
  final fastingHigh = readings.where(
    (r) => !r.isPostMeal && r.value >= kGlucoseFastingTarget,
  );
  final postHigh = readings.where(
    (r) => r.isPostMeal && r.value >= kGlucosePostMealTarget,
  );

  if (highs.isEmpty && lows.isEmpty) {
    items.add(
      const GlucoseInsightItem(
        text: 'All your readings are within the pregnancy targets. Keep it up!',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
    );
  }
  if (fastingHigh.isNotEmpty) {
    items.add(
      GlucoseInsightItem(
        text:
            '${fastingHigh.length} fasting / pre-meal '
            '${fastingHigh.length == 1 ? 'reading was' : 'readings were'} '
            '${kGlucoseFastingTarget.toInt()} mg/dL or above. Share these with '
            'your doctor to check for gestational diabetes.',
        icon: Icons.info_outline_rounded,
        color: Colors.orange,
      ),
    );
  }
  if (postHigh.isNotEmpty) {
    items.add(
      GlucoseInsightItem(
        text:
            '${postHigh.length} post-meal '
            '${postHigh.length == 1 ? 'reading was' : 'readings were'} '
            '${kGlucosePostMealTarget.toInt()} mg/dL or above. Smaller meals, '
            'fewer refined carbs and a short walk after eating can help.',
        icon: Icons.restaurant_rounded,
        color: Colors.deepOrange,
      ),
    );
  }
  if (lows.isNotEmpty) {
    items.add(
      const GlucoseInsightItem(
        text:
            'Low reading detected (below 70 mg/dL). Eat a small snack and '
            'tell your doctor if it happens again.',
        icon: Icons.warning_amber_rounded,
        color: Colors.blue,
      ),
    );
  }
  items.add(
    const GlucoseInsightItem(
      text: 'Check post-meal glucose about 2 hours after you start eating.',
      icon: Icons.lightbulb_outline_rounded,
      color: Colors.blue,
    ),
  );
  return items;
}

/// Readings, newest first, each editable through the entry sheet.
class GlucoseReadingsList extends StatelessWidget {
  final List<GlucoseReading> readings;
  final VoidCallback onChanged;
  final bool showDate;

  const GlucoseReadingsList({
    super.key,
    required this.readings,
    required this.onChanged,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = List<GlucoseReading>.from(readings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: sorted.map((r) {
        final category = r.category;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showDate
                          ? DateFormat('d MMM · h:mm a').format(r.timestamp)
                          : DateFormat('h:mm a').format(r.timestamp),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${glucosePhaseLabel(r.mealPhase)} · ${category.label}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                formatMgDl(r.value),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: kGlucoseColor,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'mg/dL',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (r.isEditable) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final changed = await showBloodGlucoseEntrySheet(
                          context,
                          existing: r.vital,
                        );
                        if (changed == true) onChanged();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Colors.orange.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
