import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/body_composition/models/body_composition_models.dart';
import 'package:allomom/features/my_health/vitals/body_composition/views/body_composition_chart_card.dart';

class HeightHistoryView extends StatelessWidget {
  final List<BodyCompositionAggregate> history;
  final BodyCompositionDateFilter filter;
  final double initialHeight;

  const HeightHistoryView({
    super.key,
    required this.history,
    required this.filter,
    required this.initialHeight,
  });

  @override
  Widget build(BuildContext context) {
    final values = history.map((item) => item.height ?? 0).toList();
    final dates = history.map((item) => item.date).toList();
    final summary = BodyCompositionModels.summarize(
      values,
      fallbackLatest: initialHeight > 0 ? initialHeight : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricSummaryRow(
          latest: summary.latest,
          minimum: summary.minimum,
          maximum: summary.maximum,
          change: summary.change,
          unit: 'cm',
          color: const Color(0xFF00BCD4),
          labels: const ['Current', 'Lowest', 'Highest'],
        ),
        const SizedBox(height: 24),
        BodyCompositionChartCard(
          title: 'Height Graph',
          subtitle:
              'Monitor recorded height entries for the selected date range.',
          values: values,
          dates: dates,
          unit: 'cm',
          color: const Color(0xFF00BCD4),
          filter: filter,
          height: 260,
        ),
      ],
    );
  }
}

class MetricSummaryRow extends StatelessWidget {
  final double? latest;
  final double? minimum;
  final double? maximum;
  final double? change;
  final String unit;
  final Color color;
  final List<String> labels;

  const MetricSummaryRow({
    super.key,
    required this.latest,
    required this.minimum,
    required this.maximum,
    required this.change,
    required this.unit,
    required this.color,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cards = [
      [labels[0], latest],
      [labels[1], minimum],
      [labels[2], maximum],
    ];

    return Column(
      children: [
        Row(
          children: cards.map((entry) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: entry == cards.last ? 0 : 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (entry[0] as String),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry[1] == null
                            ? '--'
                            : '${(entry[1] as double).toStringAsFixed(unit == 'cm' ? 0 : 1)} $unit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Change: ${(change ?? 0) > 0 ? '+' : ''}${(change ?? 0).toStringAsFixed(unit == 'cm' ? 0 : 1)} $unit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
