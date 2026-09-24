import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/models/heart_rate_models.dart';

class HeartRateWeeklyView extends StatefulWidget {
  final String userId;
  const HeartRateWeeklyView({super.key, required this.userId});

  @override
  State<HeartRateWeeklyView> createState() => _HeartRateWeeklyViewState();
}

class _HeartRateWeeklyViewState extends State<HeartRateWeeklyView> {
  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;
  final RxList<VitalsStreamResponse> _history = <VitalsStreamResponse>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final to = DateTime.now();
      final from = to.subtract(const Duration(days: 7));

      final result = await _vitalsController.getVitalsHistory(
        widget.userId,
        'heart_rate',
        fromDate: from,
        toDate: to,
      );

      _history.value = result;

      if (_history.isEmpty && _vitalsController.error.isNotEmpty) {
        _error.value = _vitalsController.error;
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Color _getHeartRateColor(double bpm) {
    if (bpm < 60) return Colors.blue.shade400;
    if (bpm <= 100) return const Color(0xFF00E676);
    if (bpm <= 120) return Colors.orange.shade400;
    return const Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Obx(() {
      if (_isLoading.value && _history.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_history.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: VitalsEmptyState(
            title: 'No activity for this week',
            subtitle: 'Try taking a new recording or check back later!',
          ),
        );
      }

      final dailyStats = DailyHeartRateStats.fromHistory(_history);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklySummary(dailyStats, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildChart(dailyStats, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildInsights(dailyStats, isDarkMode, textColor),
        ],
      );
    });
  }

  Widget _buildWeeklySummary(
    List<DailyHeartRateStats> stats,
    bool isDark,
    Color textColor,
  ) {
    double totalAvg = 0;
    double maxPeak = 0;
    double minResting = stats.first.min;

    for (var s in stats) {
      totalAvg += s.avg;
      if (s.max > maxPeak) maxPeak = s.max;
      if (s.min < minResting) minResting = s.min;
    }
    final weeklyAvg = totalAvg / stats.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Weekly Avg',
            weeklyAvg.round().toString(),
            const Color(0xFF00E676),
            textColor,
          ),
          _buildSummaryItem(
            'Peak',
            maxPeak.round().toString(),
            const Color(0xFFFF5252),
            textColor,
          ),
          _buildSummaryItem(
            'Lowest',
            minResting.round().toString(),
            Colors.blue.shade400,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    Color textColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    List<DailyHeartRateStats> stats,
    bool isDark,
    Color textColor,
  ) {
    // Dynamically compute Y-axis bounds from the aggregated daily min/max.
    final allMin = stats.map((s) => s.min).reduce((a, b) => a < b ? a : b);
    final allMax = stats.map((s) => s.max).reduce((a, b) => a > b ? a : b);
    final chartMinY =
        ((allMin - 10).clamp(0, double.infinity) / 10).floor() * 10.0;
    final chartMaxY = ((allMax + 10) / 10).ceil() * 10.0;
    final range = chartMaxY - chartMinY;
    final leftInterval = (range / 4).clamp(5, 50).ceilToDouble();

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(10, 24, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (val) => FlLine(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < stats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('E').format(stats[idx].date),
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: leftInterval,
                getTitlesWidget: (val, meta) => Text(
                  val.toInt().toString(),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: chartMinY,
          maxY: chartMaxY,
          barGroups: stats.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  fromY: e.value.min,
                  toY: e.value.max,
                  width: 12,
                  gradient: LinearGradient(
                    colors: [
                      _getHeartRateColor(e.value.min),
                      _getHeartRateColor(e.value.max),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) =>
                  isDark ? const Color(0xFF1E2433) : Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stat = stats[groupIndex];
                return BarTooltipItem(
                  '${DateFormat('EEEE').format(stat.date)}\n',
                  TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text:
                          'Range: ${stat.min.toInt()} - ${stat.max.toInt()} BPM\n',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    TextSpan(
                      text: 'Avg: ${stat.avg.toInt()} BPM',
                      style: TextStyle(
                        color: _getHeartRateColor(stat.avg),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsights(
    List<DailyHeartRateStats> stats,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Trends',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildTrendCard(
          'Highest Activity',
          DateFormat(
            'EEEE, MMM dd',
          ).format(stats.reduce((a, b) => a.max > b.max ? a : b).date),
          const Color(0xFFFF5252),
          isDark,
          textColor,
        ),
        _buildTrendCard(
          'Most Stable',
          DateFormat('EEEE, MMM dd').format(
            stats
                .reduce((a, b) => (a.max - a.min) < (b.max - b.min) ? a : b)
                .date,
          ),
          const Color(0xFF00E676),
          isDark,
          textColor,
        ),
      ],
    );
  }

  Widget _buildTrendCard(
    String title,
    String subtitle,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_up_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
