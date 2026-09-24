import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/models/blood_oxygen_models.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';

class WeeklyBloodOxygenView extends StatefulWidget {
  final String userId;

  const WeeklyBloodOxygenView({
    super.key,
    required this.userId,
  });

  @override
  State<WeeklyBloodOxygenView> createState() => _WeeklyBloodOxygenViewState();
}

class _WeeklyBloodOxygenViewState extends State<WeeklyBloodOxygenView> {
  final RxList<VitalsStreamResponse> _history = <VitalsStreamResponse>[].obs;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      _isLoading.value = true;
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 7));

      _history.value = await HealthVitalsController.instance.getVitalsHistory(
        widget.userId,
        'blood_oxygen',
        fromDate: from,
        toDate: now,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Obx(() {
      if (_isLoading.value && _history.isEmpty) {
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final aggregates = DailyBloodOxygenAggregate.fromHistory(_history);

      if (aggregates.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: VitalsEmptyState(
            title: 'No data this week',
            subtitle:
                'Tap Add SpO₂ to log a reading, or wear your device to see your weekly trend.',
            icon: Icons.bar_chart_rounded,
          ),
        );
      }

      final raw7Days = List.generate(7, (index) {
        final date = DateTime.now().subtract(Duration(days: index));
        final match = aggregates.firstWhere(
          (a) =>
              DateFormat('yyyy-MM-dd').format(a.date) ==
              DateFormat('yyyy-MM-dd').format(date),
          orElse: () => DailyBloodOxygenAggregate(
            date: date,
            avgSpO2: 0,
            minSpO2: 100,
            maxSpO2: 0,
            readings: [],
          ),
        );
        return match;
      }).reversed.toList();

      // Skip leading empty days to "stretch" the chart
      final last7Days = raw7Days.skipWhile((a) => a.avgSpO2 == 0).toList();
      if (last7Days.isEmpty) {
        return const SizedBox.shrink(); // Should already be handled by aggregates.isEmpty
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklySummary(last7Days, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildWeeklyChart(last7Days, isDarkMode, textColor),
          const SizedBox(height: 32),
          _buildConsistencyCard(last7Days, isDarkMode, textColor),
        ],
      );
    });
  }

  Widget _buildWeeklySummary(
    List<DailyBloodOxygenAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    double totalAvg = 0;
    double minOfMin = 100;
    int count = 0;
    for (var a in data) {
      if (a.avgSpO2 > 0) {
        totalAvg += a.avgSpO2;
        if (a.minSpO2 < minOfMin) minOfMin = a.minSpO2;
        count++;
      }
    }
    final weeklyAvg = count > 0 ? totalAvg / count : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            'Weekly Avg',
            '${weeklyAvg.toInt()}%',
            Colors.blue,
            textColor,
          ),
          _buildMetric(
            'Weekly Min',
            '${minOfMin == 100 ? 0 : minOfMin.toInt()}%',
            Colors.orange,
            textColor,
          ),
          _buildMetric(
            'Stability',
            count > 5 ? 'High' : 'Medium',
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
    List<DailyBloodOxygenAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
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
                    getTitlesWidget: (value, meta) {
                      if (value == 90 || value == 95 || value == 100) {
                        return Text(
                          '${value.toInt()}%',
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
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < data.length) {
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
              minY: 85,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map(
                        (e) => FlSpot(
                          e.key.toDouble(),
                          e.value.avgSpO2 > 0 ? e.value.avgSpO2 : 94,
                        ),
                      )
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFF00E5FF),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencyCard(
    List<DailyBloodOxygenAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    int activeDays = data.where((a) => a.avgSpO2 > 0).length;

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
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.blueAccent,
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
                  'You have monitored your oxygen for $activeDays out of ${data.length} days this week.',
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
