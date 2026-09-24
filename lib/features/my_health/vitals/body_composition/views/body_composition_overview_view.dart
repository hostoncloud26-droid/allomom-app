import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/body_composition/models/body_composition_models.dart';

class BodyCompositionOverviewView extends StatelessWidget {
  final List<BodyCompositionAggregate> weeklyHistory;
  final List<BodyCompositionAggregate> monthlyHistory;
  final double initialHeight;
  final double initialWeight;

  const BodyCompositionOverviewView({
    super.key,
    required this.weeklyHistory,
    required this.monthlyHistory,
    required this.initialHeight,
    required this.initialWeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);
    final latestSource = monthlyHistory.isNotEmpty
        ? monthlyHistory
        : weeklyHistory;
    final latest = latestSource.isNotEmpty ? latestSource.last : null;
    final latestHeight =
        latest?.height ?? (initialHeight > 0 ? initialHeight : null);
    final latestWeight =
        latest?.weight ?? (initialWeight > 0 ? initialWeight : null);
    final bmi = latestHeight != null && latestWeight != null && latestHeight > 0
        ? latestWeight / ((latestHeight / 100) * (latestHeight / 100))
        : null;

    final heightValues = latestSource.map((item) => item.height ?? 0).toList();
    final weightValues = latestSource.map((item) => item.weight ?? 0).toList();
    final heightSummary = BodyCompositionModels.summarize(
      heightValues,
      fallbackLatest: latestHeight,
    );
    final weightSummary = BodyCompositionModels.summarize(
      weightValues,
      fallbackLatest: latestWeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverviewHero(
          bmi: bmi,
          latestHeight: latestHeight,
          latestWeight: latestWeight,
          textColor: textColor,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SummaryStatCard(
                label: 'Height',
                value: latestHeight == null
                    ? '--'
                    : latestHeight.toStringAsFixed(0),
                unit: 'cm',
                delta: heightSummary.change,
                color: const Color(0xFF00BCD4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStatCard(
                label: 'Weight',
                value: latestWeight == null
                    ? '--'
                    : latestWeight.toStringAsFixed(1),
                unit: 'kg',
                delta: weightSummary.change,
                color: const Color(0xFFFF8A65),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewHero extends StatelessWidget {
  final double? bmi;
  final double? latestHeight;
  final double? latestWeight;
  final Color textColor;
  final bool isDarkMode;

  const _OverviewHero({
    required this.bmi,
    required this.latestHeight,
    required this.latestWeight,
    required this.textColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bmiColor = _bmiColor(bmi);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF132033), const Color(0xFF0D1726)]
              : [const Color(0xFFF4FBFF), const Color(0xFFFFF5F0)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: bmiColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Composition Snapshot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bmiColor.withValues(alpha: 0.12),
                  border: Border.all(color: bmiColor.withValues(alpha: 0.24)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bmi?.toStringAsFixed(1) ?? '--',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'BMI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: textColor.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bmiColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        bmi == null
                            ? 'Waiting for measurements'
                            : BodyCompositionModels.bmiCategory(bmi!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: bmiColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Latest measurements are combined here so you can compare height, weight, and BMI together.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _heroMetric(
                  'Height',
                  latestHeight == null
                      ? '--'
                      : '${latestHeight!.toStringAsFixed(0)} cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _heroMetric(
                  'Weight',
                  latestWeight == null
                      ? '--'
                      : '${latestWeight!.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _bmiColor(double? bmi) {
    if (bmi == null) return const Color(0xFF90A4AE);
    if (bmi < 18.5) return const Color(0xFF42A5F5);
    if (bmi < 25) return const Color(0xFF00C853);
    if (bmi < 30) return const Color(0xFFFFB300);
    return const Color(0xFFFF5252);
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double? delta;
  final Color color;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final deltaValue = delta ?? 0;
    final deltaPrefix = deltaValue > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(color: textColor),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$deltaPrefix${deltaValue.toStringAsFixed(unit == 'cm' ? 0 : 1)} $unit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
