import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/body_composition/models/body_composition_models.dart';
import 'package:allomom/features/my_health/vitals/body_composition/views/body_composition_chart_card.dart';

class BodyCompositionPeriodView extends StatelessWidget {
  final List<BodyCompositionAggregate> history;
  final BodyCompositionDateFilter filter;
  final double initialHeight;
  final double initialWeight;
  final bool showTitle;

  const BodyCompositionPeriodView({
    super.key,
    required this.history,
    required this.filter,
    required this.initialHeight,
    required this.initialWeight,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final heightValues = history.map((item) => item.height ?? 0).toList();
    final weightValues = history.map((item) => item.weight ?? 0).toList();
    final dates = history.map((item) => item.date).toList();
    final heightSummary = BodyCompositionModels.summarize(
      heightValues,
      fallbackLatest: initialHeight > 0 ? initialHeight : null,
    );
    final weightSummary = BodyCompositionModels.summarize(
      weightValues,
      fallbackLatest: initialWeight > 0 ? initialWeight : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            filter == BodyCompositionDateFilter.weekly
                ? 'Weekly Overview'
                : 'Monthly Overview',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _MetricSummaryCard(
                title: 'Height',
                latest: heightSummary.latest,
                minimum: heightSummary.minimum,
                maximum: heightSummary.maximum,
                change: heightSummary.change,
                unit: 'cm',
                color: const Color(0xFF00BCD4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricSummaryCard(
                title: 'Weight',
                latest: weightSummary.latest,
                minimum: weightSummary.minimum,
                maximum: weightSummary.maximum,
                change: weightSummary.change,
                unit: 'kg',
                color: const Color(0xFFFF8A65),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        BodyCompositionChartCard(
          title: filter == BodyCompositionDateFilter.weekly
              ? 'Weekly Height Graph'
              : 'Monthly Height Graph',
          subtitle: filter == BodyCompositionDateFilter.weekly
              ? 'Recorded height values across the last 7 days.'
              : 'Recorded height values across the last 30 days.',
          values: heightValues,
          dates: dates,
          unit: 'cm',
          color: const Color(0xFF00BCD4),
          filter: filter,
          height: 230,
        ),
        const SizedBox(height: 20),
        BodyCompositionChartCard(
          title: filter == BodyCompositionDateFilter.weekly
              ? 'Weekly Weight Graph'
              : 'Monthly Weight Graph',
          subtitle: filter == BodyCompositionDateFilter.weekly
              ? 'Recorded weight values across the last 7 days.'
              : 'Recorded weight values across the last 30 days.',
          values: weightValues,
          dates: dates,
          unit: 'kg',
          color: const Color(0xFFFF8A65),
          filter: filter,
          height: 230,
        ),
      ],
    );
  }
}

class _MetricSummaryCard extends StatelessWidget {
  final String title;
  final double? latest;
  final double? minimum;
  final double? maximum;
  final double? change;
  final String unit;
  final Color color;

  const _MetricSummaryCard({
    required this.title,
    required this.latest,
    required this.minimum,
    required this.maximum,
    required this.change,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final decimals = unit == 'cm' ? 0 : 1;
    final changeText =
        '${(change ?? 0) > 0 ? '+' : ''}${(change ?? 0).toStringAsFixed(decimals)} $unit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white,
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
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            latest == null
                ? '--'
                : '${latest!.toStringAsFixed(decimals)} $unit',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Low: ${minimum == null ? '--' : minimum!.toStringAsFixed(decimals)} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'High: ${maximum == null ? '--' : maximum!.toStringAsFixed(decimals)} $unit',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Change: $changeText',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
