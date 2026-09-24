// Week view, mirroring AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/views/weekly_blood_oxygen_view.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../models/hemoglobin_models.dart';
import '../widgets/hemoglobin_widgets.dart';

class WeeklyHemoglobinView extends StatefulWidget {
  final VoidCallback onChanged;

  const WeeklyHemoglobinView({super.key, required this.onChanged});

  @override
  State<WeeklyHemoglobinView> createState() => _WeeklyHemoglobinViewState();
}

class _WeeklyHemoglobinViewState extends State<WeeklyHemoglobinView> {
  List<VitalsStreamResponse> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 6);
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
          title: 'No data this week',
          subtitle: 'Tap Add Hemoglobin to log a lab result — readings will appear here.',
          icon: Icons.bar_chart_rounded,
          iconColor: kHemoglobinColor,
        ),
      );
    }

    final days = DailyHemoglobinAggregate.lastDays(_history, 7);
    final withData = days.where((d) => d.hasData).toList();
    final readings = withData.expand((d) => d.readings).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklySummary(readings, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildWeeklyChart(days, isDarkMode, textColor),
        const SizedBox(height: 32),
        _buildConsistencyCard(withData.length, isDarkMode, textColor),
        const SizedBox(height: 32),
        const HbSectionTitle('Readings'),
        const SizedBox(height: 16),
        HbReadingsList(readings: readings, onChanged: widget.onChanged),
      ],
    );
  }

  Widget _buildWeeklySummary(
    List<HemoglobinReading> readings,
    bool isDark,
    Color textColor,
  ) {
    final values = readings.map((r) => r.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final category = hbCategoryFor(avg);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: hbCardDecoration(isDark, radius: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            'Weekly Avg',
            avg.toStringAsFixed(1),
            Colors.blue,
            textColor,
          ),
          _buildMetric(
            'Weekly Min',
            min.toStringAsFixed(1),
            Colors.orange,
            textColor,
          ),
          _buildMetric(
            'Status',
            category == HbCategory.normal ? 'Normal' : 'Watch',
            category.color,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value,
    Color color,
    Color textColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 20,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    List<DailyHemoglobinAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        if (data[i].hasData) FlSpot(i.toDouble(), data[i].avg),
    ];
    final values = spots.map((s) => s.y);
    final minY = [
      8.0,
      ...values.map((v) => v - 1),
    ].reduce((a, b) => a < b ? a : b).floorToDouble();
    final maxY = [
      16.0,
      ...values.map((v) => v + 1),
    ].reduce((a, b) => a > b ? a : b).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HbSectionTitle('7-Day Trend'),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          decoration: hbCardDecoration(isDark),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: kHbBandMin,
                    y2: kHbBandMax,
                    color: const Color(0xFF10B981).withValues(alpha: 0.06),
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
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value % 2 == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (val == idx.toDouble() &&
                          idx >= 0 &&
                          idx < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat(
                              'E',
                            ).format(data[idx].date).toUpperCase(),
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
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: spots.length > 2,
                  color: kHemoglobinColor,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: kHemoglobinColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyCard(int activeDays, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2433) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kHemoglobinColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: kHemoglobinColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monitoring Consistency',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You logged hemoglobin on $activeDays of the last 7 days. '
                  'Log each new lab result to keep your trend up to date.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
