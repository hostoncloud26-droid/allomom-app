import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/models/heart_rate_models.dart';

class HeartRateMonthlyView extends StatefulWidget {
  final String userId;
  const HeartRateMonthlyView({super.key, required this.userId});

  @override
  State<HeartRateMonthlyView> createState() => _HeartRateMonthlyViewState();
}

class _HeartRateMonthlyViewState extends State<HeartRateMonthlyView> {
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
      final from = to.subtract(const Duration(days: 30));

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
            title: 'No activity for this month',
            subtitle: 'Try taking a new recording or check back later!',
          ),
        );
      }

      final dailyStats = DailyHeartRateStats.fromHistory(_history);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlyOverview(dailyStats, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildChart(dailyStats, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildAnalysis(dailyStats, isDarkMode, textColor),
        ],
      );
    });
  }

  Widget _buildMonthlyOverview(
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
    final monthlyAvg = totalAvg / stats.length;

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
          _buildOverviewItem(
            'Monthly Avg',
            monthlyAvg.round().toString(),
            const Color(0xFF00E676),
            textColor,
          ),
          _buildOverviewItem(
            'Peak',
            maxPeak.round().toString(),
            const Color(0xFFFF5252),
            textColor,
          ),
          _buildOverviewItem(
            'Resting',
            minResting.round().toString(),
            Colors.blue.shade400,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
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
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                interval: 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  final int step = (stats.length / 5).ceil().clamp(1, 100);

                  if (idx % step != 0) {
                    return const SizedBox.shrink();
                  }

                  if (idx >= 0 && idx < stats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(stats[idx].date),
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 9,
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
                    fontSize: 9,
                  ),
                ),
                reservedSize: 24,
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
                  width: 3,
                  gradient: LinearGradient(
                    colors: [
                      _getHeartRateColor(e.value.min),
                      _getHeartRateColor(e.value.max),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
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
                  '${DateFormat('MMM dd').format(stat.date)}\n',
                  TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: 'High: ${stat.max.toInt()}\n',
                      style: TextStyle(
                        color: const Color(0xFFFF5252),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Low: ${stat.min.toInt()}\n',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Avg: ${stat.avg.toInt()} BPM',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 9,
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

  Widget _buildAnalysis(
    List<DailyHeartRateStats> stats,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Insight',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildAnalysisCard(
          'Range Stability',
          'Your resting heart rate has been stable this month.',
          Icons.shield_moon_rounded,
          const Color(0xFF00E676),
          isDark,
          textColor,
        ),
        _buildAnalysisCard(
          'Activity Impact',
          'Higher peaks observed during cardiovascular activities.',
          Icons.bolt_rounded,
          const Color(0xFFFF5252),
          isDark,
          textColor,
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.5),
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
