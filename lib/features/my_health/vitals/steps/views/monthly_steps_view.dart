// Ported from AlloConnect lib/features/health_section/vitals/steps/views/monthly_steps_view.dart.
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/features/my_health/vitals/steps/models/steps_models.dart';

class MonthlyStepsView extends StatefulWidget {
  final String userId;
  final int goalSteps;

  const MonthlyStepsView({
    super.key,
    required this.userId,
    this.goalSteps = 10000,
  });

  @override
  State<MonthlyStepsView> createState() => _MonthlyStepsViewState();
}

class _MonthlyStepsViewState extends State<MonthlyStepsView> {
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
          title: 'No monthly activity',
          subtitle: 'Keep moving every day to build your trends!',
          icon: Icons.calendar_month_rounded,
        ),
      );
    }

    // Generate last 30 days
    final last30Days = List.generate(30, (index) {
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
        _buildMonthlySummary(last30Days, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildMonthlyChart(last30Days, isDarkMode, textColor),
        const SizedBox(height: 32),
        _buildConsistencyStats(last30Days, isDarkMode, textColor),
      ],
    );
  }

  Widget _buildMonthlySummary(
      List<DailyStepsAggregate> data, bool isDark, Color textColor) {
    int totalSteps = 0;
    int goalReachedCount = 0;
    for (var a in data) {
      totalSteps += a.totalSteps;
      if (a.totalSteps >= widget.goalSteps) goalReachedCount++;
    }
    final avgSteps = totalSteps / data.length;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMonthlyStat(
              'Total', NumberFormat.compact().format(totalSteps), textColor),
          _buildMonthlyStat(
              'Avg', NumberFormat.compact().format(avgSteps), textColor),
          _buildMonthlyStat('Goals', '$goalReachedCount/30', textColor),
        ],
      ),
    );
  }

  Widget _buildMonthlyStat(String label, String value, Color textColor) {
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
                fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
      ],
    );
  }

  Widget _buildMonthlyChart(
      List<DailyStepsAggregate> data, bool isDark, Color textColor) {
    final maxSteps = _calculateMaxSteps(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30-Day Trends',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor)),
            Text('Daily Totals',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
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
                      if (val % 7 == 0 && idx >= 0 && idx < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd').format(data[idx].date),
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.3),
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.totalSteps.toDouble(),
                      color: e.value.totalSteps >= widget.goalSteps
                          ? const Color(0xFF00E676)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.6),
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

  double _calculateMaxSteps(List<DailyStepsAggregate> data) {
    int maxVal = 1000;
    for (var a in data) {
      if (a.totalSteps > maxVal) maxVal = a.totalSteps;
    }
    return maxVal * 1.1;
  }

  int _calculateActiveStreak(List<DailyStepsAggregate> data) {
    if (data.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    int i = data.length - 1;

    if (i >= 0) {
      final lastEl = data[i];
      final lastElStr = DateFormat('yyyy-MM-dd').format(lastEl.date);

      if (lastElStr == todayStr) {
        if (lastEl.totalSteps >= widget.goalSteps) {
          streak = 1;
          i--;
        } else {
          i--;
          if (i >= 0) {
            final yesterdayEl = data[i];
            if (yesterdayEl.totalSteps >= widget.goalSteps) {
              streak = 1;
              i--;
            } else {
              return 0;
            }
          } else {
            return 0;
          }
        }
      } else {
        if (lastEl.totalSteps >= widget.goalSteps) {
          streak = 1;
          i--;
        } else {
          return 0;
        }
      }
    }

    while (i >= 0) {
      if (data[i].totalSteps >= widget.goalSteps) {
        streak++;
        i--;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateGoalCompletion(List<DailyStepsAggregate> data) {
    int count = 0;
    for (var a in data) {
      if (a.totalSteps >= widget.goalSteps) {
        count++;
      }
    }
    return count;
  }

  Widget _buildConsistencyStats(
      List<DailyStepsAggregate> data, bool isDark, Color textColor) {
    final streak = _calculateActiveStreak(data);
    final goalCompletion = _calculateGoalCompletion(data);
    final streakText = '$streak ${streak == 1 ? 'Day' : 'Days'}';
    final completionText = '$goalCompletion/${data.length}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Engagement',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 16),
        _buildEngagementRow(
            'Active Streak',
            streakText,
            Icons.local_fire_department_rounded,
            const Color(0xFFFF5252),
            isDark,
            textColor),
        const SizedBox(height: 12),
        _buildEngagementRow('Goal Completion', completionText,
            Icons.stars_rounded, const Color(0xFFFFD700), isDark, textColor),
      ],
    );
  }

  Widget _buildEngagementRow(String label, String value, IconData icon,
      Color color, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.6))),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
        ],
      ),
    );
  }
}
