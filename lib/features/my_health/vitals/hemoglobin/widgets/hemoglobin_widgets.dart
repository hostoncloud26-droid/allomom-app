// Shared pieces of the hemoglobin Day / Week / Month views, styled after
// AlloConnect's blood oxygen and blood pressure views.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../hemoglobin_entry_sheet.dart';
import '../models/hemoglobin_models.dart';

/// Hemoglobin rows between [from] and [to], newest first.
Future<List<VitalsStreamResponse>> loadHemoglobinHistory(
  DateTime from,
  DateTime to,
) {
  final vitals = HealthVitalsController.instance;
  return vitals.getVitalsHistory(
    vitals.userId,
    'hemoglobin',
    fromDate: from,
    toDate: to,
  );
}

BoxDecoration hbCardDecoration(bool isDark, {double radius = 24}) =>
    BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
      ),
    );

class HbSectionTitle extends StatelessWidget {
  final String text;
  const HbSectionTitle(this.text, {super.key});

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

class HbStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const HbStatCard({
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

class HbStatGrid extends StatelessWidget {
  final List<HbStatCard> cards;
  const HbStatGrid({super.key, required this.cards});

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
      children: cards,
    );
  }
}

class HbInsightItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const HbInsightItem({
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

/// Smart insights for a hemoglobin level, pregnancy framing.
List<Widget> hbInsightsFor(double avg) {
  final category = hbCategoryFor(avg);
  final items = <Widget>[];
  switch (category) {
    case HbCategory.normal:
      items.add(
        const HbInsightItem(
          text:
              'Your hemoglobin is in the healthy pregnancy range. Keep up your '
              'iron and folic acid tablets.',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
      );
    case HbCategory.mild:
      items.add(
        const HbInsightItem(
          text:
              'Slightly low hemoglobin (mild anaemia). Add iron-rich foods like '
              'greens, dates, jaggery and pulses, with a vitamin C source.',
          icon: Icons.info_outline_rounded,
          color: Colors.orange,
        ),
      );
    case HbCategory.moderate:
      items.add(
        const HbInsightItem(
          text:
              'Moderate anaemia. Please talk to your doctor about your iron '
              'supplements and a repeat test.',
          icon: Icons.warning_amber_rounded,
          color: Colors.deepOrange,
        ),
      );
    case HbCategory.severe:
      items.add(
        const HbInsightItem(
          text:
              'Severe anaemia. Contact your doctor or health worker as soon as '
              'possible.',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
        ),
      );
  }
  items.add(
    const HbInsightItem(
      text:
          'Take iron tablets with water or lemon juice, not with tea, coffee or '
          'milk, which block absorption.',
      icon: Icons.lightbulb_outline_rounded,
      color: Colors.blue,
    ),
  );
  return items;
}

/// Readings, newest first, each editable through the entry sheet.
class HbReadingsList extends StatelessWidget {
  final List<HemoglobinReading> readings;
  final VoidCallback onChanged;
  final bool showDate;

  const HbReadingsList({
    super.key,
    required this.readings,
    required this.onChanged,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = List<HemoglobinReading>.from(readings)
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
                        Text(
                          category.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                r.value.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: kHemoglobinColor,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'g/dL',
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
                        final changed = await showHemoglobinEntrySheet(
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
