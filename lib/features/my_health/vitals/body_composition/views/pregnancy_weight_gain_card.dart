// Allomom-only card (not in AlloConnect): carries the pregnancy weight-gain
// insight from the old BmiTrackerDetailPage into the ported Body Composition
// screen, styled like the AlloConnect cards around it.
//
// Guidance follows the IOM 2009 recommendations by starting BMI:
// total gain and 2nd/3rd-trimester weekly rate, with 0.5–2 kg in the
// first trimester.
import 'package:flutter/material.dart';
import 'package:allomom/models/vitals_stream_model.dart';

class PregnancyWeightGainCard extends StatelessWidget {
  /// Weight entries sorted oldest → newest.
  final List<VitalsStreamResponse> weightHistory;
  final double heightCm;
  final int gestationalWeek;
  final VoidCallback? onLogWeight;

  const PregnancyWeightGainCard({
    super.key,
    required this.weightHistory,
    required this.heightCm,
    required this.gestationalWeek,
    this.onLogWeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);
    final accent = Theme.of(context).primaryColor;
    final cardBg = isDarkMode ? const Color(0xFF151D2A) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final entries = weightHistory.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final week = gestationalWeek.clamp(0, 42);

    final baseline = entries.isNotEmpty ? entries.first.value : 0.0;
    final latest = entries.isNotEmpty ? entries.last.value : 0.0;
    final gained = entries.length >= 2 ? latest - baseline : 0.0;

    final startBmi = heightCm > 0 && baseline > 0
        ? baseline / ((heightCm / 100) * (heightCm / 100))
        : 0.0;
    final band = _GainBand.forBmi(startBmi);
    final expected = band.expectedAtWeek(week);

    final _GainStatus status;
    if (entries.length < 2) {
      status = _GainStatus(
        label: 'Log more to track',
        color: const Color(0xFF90A4AE),
        icon: Icons.timeline_rounded,
      );
    } else if (gained < expected.$1) {
      status = _GainStatus(
        label: 'Below range',
        color: const Color(0xFF42A5F5),
        icon: Icons.trending_down_rounded,
      );
    } else if (gained > expected.$2) {
      status = _GainStatus(
        label: 'Above range',
        color: const Color(0xFFFFB300),
        icon: Icons.trending_up_rounded,
      );
    } else {
      status = _GainStatus(
        label: 'On track',
        color: const Color(0xFF00C853),
        icon: Icons.check_circle_rounded,
      );
    }

    final gainedText = entries.length >= 2
        ? '${gained >= 0 ? '+' : ''}${gained.toStringAsFixed(1)}'
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDarkMode ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pregnant_woman_rounded,
                  color: accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pregnancy Weight Gain',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              if (week > 0)
                Text(
                  'Week $week',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          gainedText,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entries.isEmpty
                          ? 'No weight logged yet'
                          : 'Since first log (${baseline.toStringAsFixed(1)} kg)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, color: status.color, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  label: 'Expected by now',
                  value:
                      '${expected.$1.toStringAsFixed(1)}–${expected.$2.toStringAsFixed(1)} kg',
                  isDarkMode: isDarkMode,
                  textColor: textColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  label: 'Total recommended',
                  value: '${_fmt(band.totalLow)}–${_fmt(band.totalHigh)} kg',
                  isDarkMode: isDarkMode,
                  textColor: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            startBmi > 0
                ? 'Based on a starting BMI of ${startBmi.toStringAsFixed(1)} (${band.label}). Discuss your goal with your doctor.'
                : 'Add your height to personalise this range. Discuss your goal with your doctor.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          if (entries.isEmpty && onLogWeight != null) ...[
            const SizedBox(height: 12),
            Material(
              color: accent.withValues(alpha: isDarkMode ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onLogWeight,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: Text(
                    'Log your weight',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget _miniStat({
    required String label,
    required String value,
    required bool isDarkMode,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GainBand {
  final String label;
  final double totalLow;
  final double totalHigh;
  final double weeklyLow;
  final double weeklyHigh;

  const _GainBand(
    this.label,
    this.totalLow,
    this.totalHigh,
    this.weeklyLow,
    this.weeklyHigh,
  );

  static _GainBand forBmi(double bmi) {
    if (bmi > 0 && bmi < 18.5) {
      return const _GainBand('underweight', 12.5, 18, 0.44, 0.58);
    }
    if (bmi >= 25 && bmi < 30) {
      return const _GainBand('overweight', 7, 11.5, 0.23, 0.33);
    }
    if (bmi >= 30) {
      return const _GainBand('obese', 5, 9, 0.17, 0.27);
    }
    // Normal, or unknown BMI.
    return const _GainBand('normal', 11.5, 16, 0.35, 0.50);
  }

  /// Expected cumulative gain range (kg) at [week].
  (double, double) expectedAtWeek(int week) {
    if (week <= 0) return (0, 0);
    if (week <= 13) {
      final t = week / 13;
      return (0.5 * t, 2.0 * t);
    }
    final extra = (week - 13).toDouble();
    final low = (0.5 + extra * weeklyLow).clamp(0.0, totalLow);
    final high = (2.0 + extra * weeklyHigh).clamp(0.0, totalHigh);
    return (low, high);
  }
}

class _GainStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _GainStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}
