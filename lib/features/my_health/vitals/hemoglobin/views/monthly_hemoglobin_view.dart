// Month view, mirroring AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/views/monthly_blood_oxygen_view.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../models/hemoglobin_models.dart';
import '../widgets/hemoglobin_widgets.dart';

class MonthlyHemoglobinView extends StatefulWidget {
  final VoidCallback onChanged;

  const MonthlyHemoglobinView({super.key, required this.onChanged});

  @override
  State<MonthlyHemoglobinView> createState() => _MonthlyHemoglobinViewState();
}

class _MonthlyHemoglobinViewState extends State<MonthlyHemoglobinView> {
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
    final result = await loadHemoglobinHistory(from, now);
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
          subtitle: 'Tap Add Hemoglobin to log lab results and see long-term trends.',
          icon: Icons.calendar_month_rounded,
          iconColor: kHemoglobinColor,
        ),
      );
    }

    final days = DailyHemoglobinAggregate.lastDays(_history, 30);
    final withData = days.where((d) => d.hasData).toList();
    final readings = withData.expand((d) => d.readings).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthlySummary(readings, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildMonthlyChart(days, isDarkMode, textColor),
        const SizedBox(height: 32),
        _buildStabilityMetrics(readings, isDarkMode, textColor),
        const SizedBox(height: 32),
        const HbSectionTitle('Readings'),
        const SizedBox(height: 16),
        HbReadingsList(readings: readings, onChanged: widget.onChanged),
      ],
    );
  }

  Widget _buildMonthlySummary(
    List<HemoglobinReading> readings,
    bool isDark,
    Color textColor,
  ) {
    final values = readings.map((r) => r.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final category = hbCategoryFor(avg);
    final inRange = category == HbCategory.normal;

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
            'Monthly Hemoglobin Average',
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
                avg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'g/dL',
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
                inRange ? Icons.check_circle_rounded : Icons.info_rounded,
                color: category.color,
                size: 14,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  inRange
                      ? 'Within the healthy pregnancy range'
                      : '${category.label} on average',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: category.color,
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
    List<DailyHemoglobinAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    final maxVal = data.map((d) => d.max).reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal > 16 ? maxVal + 1 : 16.0).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HbSectionTitle('30-Day Trend'),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          decoration: hbCardDecoration(isDark),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 11,
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
                    reservedSize: 30,
                    interval: 4,
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
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: agg.hasData ? agg.avg : 0,
                      color: agg.hasData
                          ? hbCategoryFor(agg.avg).color.withValues(alpha: 0.85)
                          : Colors.transparent,
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
    List<HemoglobinReading> readings,
    bool isDark,
    Color textColor,
  ) {
    final normal = readings.where((r) => r.isNormal).length;
    final percentage = readings.isEmpty ? 0.0 : normal / readings.length * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: hbCardDecoration(isDark, radius: 28),
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
                'Readings in healthy range',
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
                  color: kHemoglobinColor,
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
              backgroundColor: kHemoglobinColor.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(kHemoglobinColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your monthly score is the share of readings at or above 11 g/dL, '
            'the healthy level in pregnancy.',
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
