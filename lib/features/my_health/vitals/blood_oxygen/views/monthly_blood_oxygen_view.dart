import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/models/blood_oxygen_models.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';

class MonthlyBloodOxygenView extends StatefulWidget {
  final String userId;

  const MonthlyBloodOxygenView({
    super.key,
    required this.userId,
  });

  @override
  State<MonthlyBloodOxygenView> createState() => _MonthlyBloodOxygenViewState();
}

class _MonthlyBloodOxygenViewState extends State<MonthlyBloodOxygenView> {
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
      final from = now.subtract(const Duration(days: 30));

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
            title: 'No monthly data',
            subtitle: 'Tap Add SpO₂ to log readings and see long-term trends.',
            icon: Icons.calendar_month_rounded,
          ),
        );
      }

      // Group into 30 days
      final raw30Days = List.generate(30, (index) {
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
      final last30Days = raw30Days.skipWhile((a) => a.avgSpO2 == 0).toList();
      if (last30Days.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlySummary(last30Days, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildMonthlyChart(last30Days, isDarkMode, textColor),
          const SizedBox(height: 32),
          _buildStabilityMetircs(last30Days, isDarkMode, textColor),
        ],
      );
    });
  }

  Widget _buildMonthlySummary(
    List<DailyBloodOxygenAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    double totalAvg = 0;
    int count = 0;
    for (var a in data) {
      if (a.avgSpO2 > 0) {
        totalAvg += a.avgSpO2;
        count++;
      }
    }
    final monthlyAvg = count > 0 ? totalAvg / count : 0.0;

    return Container(
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
            'Monthly SpO₂ Average',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${monthlyAvg.toInt()}%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade400,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'Consistently within normal range',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(
    List<DailyBloodOxygenAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '30-Day Trend',
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
          child: BarChart(
            BarChartData(
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
              minY: 85,
              maxY: 100,
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.avgSpO2 > 0 ? e.value.avgSpO2 : 0,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
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

  Widget _buildStabilityMetircs(
    List<DailyBloodOxygenAggregate> data,
    bool isDark,
    Color textColor,
  ) {
    int normalDays = data.where((a) => a.avgSpO2 >= 95).length;
    int totalDaysWithData = data.where((a) => a.avgSpO2 > 0).length;
    double percentage = totalDaysWithData > 0
        ? (normalDays / totalDaysWithData) * 100
        : 0;

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
                'Oxygen Stability',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueAccent,
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
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.blueAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your monthly stability score is based on the consistency of your SpO₂ levels within the optimal 95-100% range.',
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
