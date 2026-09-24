// Month view, mirroring AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/views/monthly_blood_oxygen_view.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../models/blood_glucose_models.dart';
import '../widgets/blood_glucose_widgets.dart';

class MonthlyBloodGlucoseView extends StatefulWidget {
  final VoidCallback onChanged;

  const MonthlyBloodGlucoseView({super.key, required this.onChanged});

  @override
  State<MonthlyBloodGlucoseView> createState() =>
      _MonthlyBloodGlucoseViewState();
}

class _MonthlyBloodGlucoseViewState extends State<MonthlyBloodGlucoseView> {
  List<VitalsStreamResponse> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 29);
    final result = await loadGlucoseHistory(from, now);
    if (!mounted) return;
    setState(() {
      _history = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    if (_isLoading && _history.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: VitalsEmptyState(
          title: 'No monthly data',
          subtitle: 'Tap Add Glucose to log readings and see long-term trends.',
          icon: Icons.calendar_month_rounded,
          iconColor: kGlucoseColor,
        ),
      );
    }

    final days = DailyGlucoseAggregate.lastDays(_history, 30);
    final readings = days.expand((d) => d.readings).toList();
    final stats = GlucoseStats(readings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthlySummary(stats, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildMonthlyChart(days, isDarkMode, textColor),
        const SizedBox(height: 24),
        GlucoseStatGrid(stats: stats, averageLabel: 'Monthly average'),
        const SizedBox(height: 32),
        _buildStabilityMetrics(stats, isDarkMode, textColor),
        const SizedBox(height: 32),
        const GlucoseSectionTitle('Readings'),
        const SizedBox(height: 16),
        GlucoseReadingsList(readings: readings, onChanged: widget.onChanged),
      ],
    );
  }

  Widget _buildMonthlySummary(
    GlucoseStats stats,
    bool isDark,
    Color textColor,
  ) {
    final fastingOk = (stats.fastingAvg ?? 0) < kGlucoseFastingTarget;
    final postOk = (stats.postMealAvg ?? 0) < kGlucosePostMealTarget;
    final allOk = fastingOk && postOk;
    final color = allOk ? Colors.green.shade400 : Colors.orange.shade400;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2433) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Monthly Glucose Average',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatMgDl(stats.avg),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'mg/dL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                allOk ? Icons.check_circle_rounded : Icons.info_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  allOk
                      ? 'Averages within pregnancy targets'
                      : !fastingOk
                      ? 'Fasting average above ${kGlucoseFastingTarget.toInt()} mg/dL'
                      : 'Post-meal average above ${kGlucosePostMealTarget.toInt()} mg/dL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(
    List<DailyGlucoseAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    final maxVal = data
        .where((d) => d.hasData)
        .map((d) => d.stats.max)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = ((maxVal > 160 ? maxVal + 10 : 160) / 20).ceilToDouble() * 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlucoseSectionTitle('30-Day Trend'),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          decoration: glucoseCardDecoration(isDark),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: kGlucoseFastingTarget,
                    color: Colors.orange.withValues(alpha: 0.35),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  HorizontalLine(
                    y: kGlucosePostMealTarget,
                    color: Colors.red.withValues(alpha: 0.25),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx % 7 == 0 && idx < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('d/M').format(data[idx].date),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY,
              barGroups: data.asMap().entries.map((e) {
                final agg = e.value;
                final allInTarget =
                    agg.hasData && agg.readings.every((r) => r.isInTarget);
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: agg.hasData ? agg.avg : 0,
                      color: !agg.hasData
                          ? Colors.transparent
                          : (allInTarget
                                    ? kGlucoseColor
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.8),
                      width: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStabilityMetrics(
    GlucoseStats stats,
    bool isDark,
    Color textColor,
  ) {
    final percentage = stats.inTargetPercent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: glucoseCardDecoration(isDark, radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time in target',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: kGlucoseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: kGlucoseColor.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(kGlucoseColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your monthly score is the share of readings within the pregnancy '
            'targets: fasting / pre-meal below '
            '${kGlucoseFastingTarget.toInt()} mg/dL, post-meal below '
            '${kGlucosePostMealTarget.toInt()} mg/dL, and not below '
            '${kGlucoseLow.toInt()} mg/dL.',
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
