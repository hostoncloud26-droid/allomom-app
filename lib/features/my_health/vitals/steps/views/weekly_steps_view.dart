// Ported from AlloConnect lib/features/health_section/vitals/steps/views/weekly_steps_view.dart.
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/features/my_health/vitals/steps/models/steps_models.dart';

class WeeklyStepsView extends StatefulWidget {
  final String userId;
  final int goalSteps;

  const WeeklyStepsView({
    super.key,
    required this.userId,
    this.goalSteps = 10000,
  });

  @override
  State<WeeklyStepsView> createState() => _WeeklyStepsViewState();
}

class _WeeklyStepsViewState extends State<WeeklyStepsView> {
  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;
  List<VitalsStreamResponse> _history = <VitalsStreamResponse>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    try {
      final result = await _vitalsController.getVitalsHistory(
        widget.userId,
        'steps',
        fromDate: from,
        toDate: to,
      );
      if (!mounted) return;
      _history = result;
    } catch (_) {
      // Keep whatever was shown.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    if (_isLoading && _history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final aggregates = DailyStepsAggregate.fromHistory(_history);

    if (aggregates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: VitalsEmptyState(
          title: 'No activity this week',
          subtitle: 'Start your activity to see weekly trends!',
          icon: Icons.bar_chart_rounded,
        ),
      );
    }

    // Ensure we show last 7 days even if some days are missing
    final last7Days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      final match = aggregates.firstWhere(
        (a) =>
            DateFormat('yyyy-MM-dd').format(a.date) ==
            DateFormat('yyyy-MM-dd').format(date),
        orElse: () =>
            DailyStepsAggregate(date: date, totalSteps: 0, hourlyBreakdown: []),
      );
      return match;
    }).reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummarySection(last7Days, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildWeeklyChart(last7Days, isDarkMode, textColor),
      ],
    );
  }

  Widget _buildSummarySection(
      List<DailyStepsAggregate> last7Days, bool isDark, Color textColor) {
    int totalSteps = 0;
    int maxSteps = 0;
    for (var a in last7Days) {
      totalSteps += a.totalSteps;
      if (a.totalSteps > maxSteps) maxSteps = a.totalSteps;
    }
    final avgSteps = totalSteps / 7;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat(
                  'Weekly Avg', avgSteps.round().toString(), textColor),
              _buildSimpleStat('Best Day', maxSteps.toString(), textColor),
              _buildSimpleStat('Total', totalSteps.toString(), textColor),
            ],
          ),
          const SizedBox(height: 24),
          _buildAverageComparison(avgSteps, isDark),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.4))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
      ],
    );
  }

  Widget _buildAverageComparison(double avg, bool isDark) {
    final goal = widget.goalSteps > 0 ? widget.goalSteps : 1;
    final progress = (avg / goal).clamp(0.0, 1.0);
    const color = Color(0xFF00E676);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Consistency Score',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.5))),
            Text('${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
      List<DailyStepsAggregate> last7Days, bool isDark, Color textColor) {
    final maxSteps = _calculateMaxSteps(last7Days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Trends',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 16),
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.03)),
          ),
          child: BarChart(
            BarChartData(
              maxY: maxSteps,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < last7Days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E')
                                .format(last7Days[idx].date)
                                .toUpperCase(),
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.3),
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: last7Days.asMap().entries.map((e) {
                final isGoalReached = e.value.totalSteps >= widget.goalSteps;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.totalSteps.toDouble(),
                      color: isGoalReached
                          ? const Color(0xFF00E676)
                          : const Color(0xFF00E5FF),
                      width: 14,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxSteps,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.01),
                      ),
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

  double _calculateMaxSteps(List<DailyStepsAggregate> data) {
    int maxVal = 1000;
    for (var a in data) {
      if (a.totalSteps > maxVal) maxVal = a.totalSteps;
    }
    return maxVal * 1.2;
  }
}
