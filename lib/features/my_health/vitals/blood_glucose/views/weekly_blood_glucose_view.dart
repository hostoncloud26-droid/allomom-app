// Week view, mirroring AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/views/weekly_blood_oxygen_view.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../models/blood_glucose_models.dart';
import '../widgets/blood_glucose_widgets.dart';

class WeeklyBloodGlucoseView extends StatefulWidget {
  final VoidCallback onChanged;

  const WeeklyBloodGlucoseView({super.key, required this.onChanged});

  @override
  State<WeeklyBloodGlucoseView> createState() => _WeeklyBloodGlucoseViewState();
}

class _WeeklyBloodGlucoseViewState extends State<WeeklyBloodGlucoseView> {
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
          title: 'No data this week',
          subtitle: 'Tap Add Glucose to log a reading — it will appear here.',
          icon: Icons.bar_chart_rounded,
          iconColor: kGlucoseColor,
        ),
      );
    }

    final days = DailyGlucoseAggregate.lastDays(_history, 7);
    final readings = days.expand((d) => d.readings).toList();
    final stats = GlucoseStats(readings);
    final activeDays = days.where((d) => d.hasData).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklySummary(stats, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildWeeklyChart(days, isDarkMode, textColor),
        const SizedBox(height: 24),
        GlucoseStatGrid(stats: stats, averageLabel: 'Weekly average'),
        const SizedBox(height: 32),
        _buildConsistencyCard(activeDays, isDarkMode, textColor),
        const SizedBox(height: 32),
        const GlucoseSectionTitle('Smart Insights'),
        const SizedBox(height: 16),
        ...glucoseInsightsFor(stats),
        const SizedBox(height: 20),
        const GlucoseSectionTitle('Readings'),
        const SizedBox(height: 16),
        GlucoseReadingsList(readings: readings, onChanged: widget.onChanged),
      ],
    );
  }

  Widget _buildWeeklySummary(GlucoseStats stats, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: glucoseCardDecoration(isDark, radius: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            'Weekly Avg',
            formatMgDl(stats.avg),
            Colors.blue,
            textColor,
          ),
          _buildMetric(
            'Weekly High',
            formatMgDl(stats.max),
            Colors.orange,
            textColor,
          ),
          _buildMetric(
            'In Target',
            '${stats.inTargetPercent.toInt()}%',
            Colors.green,
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
    List<DailyGlucoseAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    // Fasting and post-meal plotted as two lines of daily averages.
    List<FlSpot> spotsFor(bool postMeal) => [
      for (var i = 0; i < data.length; i++)
        if ((postMeal ? data[i].stats.postMealAvg : data[i].stats.fastingAvg) !=
            null)
          FlSpot(
            i.toDouble(),
            postMeal ? data[i].stats.postMealAvg! : data[i].stats.fastingAvg!,
          ),
    ];
    final fasting = spotsFor(false);
    final post = spotsFor(true);
    final values = [...fasting, ...post].map((s) => s.y);
    final minY =
        ([60.0, ...values.map((v) => v - 10)].reduce((a, b) => a < b ? a : b) /
                20)
            .floorToDouble() *
        20;
    final maxY =
        ([160.0, ...values.map((v) => v + 10)].reduce((a, b) => a > b ? a : b) /
                20)
            .ceilToDouble() *
        20;

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
      spots: spots,
      isCurved: spots.length > 2,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlucoseSectionTitle('7-Day Trend'),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          decoration: glucoseCardDecoration(isDark),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: kGlucoseBandMin,
                    y2: kGlucoseBandMax,
                    color: const Color(0xFF10B981).withValues(alpha: 0.06),
                  ),
                ],
              ),
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
                    interval: 20,
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
                if (fasting.isNotEmpty) line(fasting, kGlucoseColor),
                if (post.isNotEmpty) line(post, const Color(0xFF10B981)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot('Fasting / pre-meal', kGlucoseColor, textColor),
            const SizedBox(width: 16),
            _legendDot('Post-meal', const Color(0xFF10B981), textColor),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.5),
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
              color: kGlucoseColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: kGlucoseColor,
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
                  'You checked your glucose on $activeDays of the last 7 days.',
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
