// Ported from AlloConnect lib/features/health_section/vitals/steps/views/daily_steps_view.dart.
// AlloConnect's Health Connect / Apple Health sync panel is replaced by a
// manual log panel in the same card style (Allomom has no device sync).
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/features/my_health/vitals/steps/models/steps_models.dart';
import 'package:allomom/features/my_health/vitals/steps/step_target_sheet.dart';
import 'package:allomom/features/my_health/vitals/steps/steps_entry_sheet.dart';

class DailyStepsView extends StatefulWidget {
  final String userId;
  final int goalSteps;

  const DailyStepsView({
    super.key,
    required this.userId,
    this.goalSteps = 10000,
  });

  @override
  State<DailyStepsView> createState() => _DailyStepsViewState();
}

class _DailyStepsViewState extends State<DailyStepsView> {
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
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final result = await _vitalsController.getVitalsHistory(
        widget.userId,
        'steps',
        fromDate: from,
        toDate: to,
      );
      if (!mounted) return;
      // The whole day, so the hourly chart can place each entry; the day's
      // total is still its newest reading.
      _history = result;
    } catch (_) {
      // Keep whatever was shown.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEntry({VitalsStreamResponse? existing}) async {
    final saved = await showStepsEntrySheet(context, existing: existing);
    if (saved == true && mounted) _fetchData();
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
    final data = aggregates.isEmpty ? null : aggregates.last;

    final logPanel = _buildLogPanel(data, isDarkMode, textColor);

    if (data == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          logPanel,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: VitalsEmptyState(
              title: 'No steps recorded today',
              subtitle:
                  'Get moving! Your daily goal is ${widget.goalSteps} steps.',
              icon: Icons.directions_walk_rounded,
              iconColor: const Color(0xFF00E676),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        logPanel,
        _buildHeroProgress(data, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildQuickStats(data, isDarkMode, textColor),
        const SizedBox(height: 32),
        _buildHourlyChart(data, isDarkMode, textColor),
      ],
    );
  }

  Widget _buildHeroProgress(
      DailyStepsAggregate data, bool isDark, Color textColor) {
    final goal = widget.goalSteps > 0 ? widget.goalSteps : 1;
    final progress = (data.totalSteps / goal).clamp(0.0, 1.0);
    const stepColor = Color(0xFF00E676);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: stepColor.withValues(alpha: 0.1),
                  color: stepColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Inner Glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      stepColor.withValues(alpha: 0.15),
                      stepColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data.totalSteps}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'of ${widget.goalSteps} steps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressBadge(progress, stepColor),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => showStepTargetSheet(context, userId: widget.userId),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: stepColor.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_road_rounded, color: stepColor, size: 12),
                  SizedBox(width: 6),
                  Text(
                    'Update Target',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: stepColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(double progress, Color color) {
    final percent = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flash_on_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            '$percent% of daily goal',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      DailyStepsAggregate data, bool isDark, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Steps',
            value: '${data.totalSteps}',
            unit: 'steps',
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFF00E676),
            isDark: isDark,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'Distance',
            value: data.distanceKm.toStringAsFixed(2),
            unit: 'km',
            icon: Icons.route_rounded,
            color: const Color(0xFF00E5FF),
            isDark: isDark,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'Peak Hour',
            value: data.peakHourLabel,
            unit: '',
            icon: Icons.schedule_rounded,
            color: const Color(0xFFFFD700),
            isDark: isDark,
            textColor: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.4)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(
      DailyStepsAggregate data, bool isDark, Color textColor) {
    final maxY = _calculateMaxHourly(data.hourlyBreakdown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hourly Activity',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
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
                      if (val % 4 == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${val.toInt()}:00',
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
              barGroups: List.generate(24, (index) {
                final hourData = data.hourlyBreakdown.firstWhere(
                  (h) => h.timestamp.hour == index,
                  orElse: () => StepsStats(timestamp: DateTime.now(), count: 0),
                );
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: hourData.count.toDouble(),
                      color: const Color(0xFF00E676),
                      width: 4,
                      borderRadius: BorderRadius.circular(2),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateMaxHourly(List<StepsStats> hourly) {
    if (hourly.isEmpty) return 100;
    double maxVal = 100;
    for (var h in hourly) {
      if (h.count > maxVal) maxVal = h.count.toDouble();
    }
    return maxVal * 1.2;
  }

  /// Takes the place of AlloConnect's Health Connect / Apple Health sync
  /// panel: same card, but logs (or edits today's) steps by hand.
  Widget _buildLogPanel(
      DailyStepsAggregate? data, bool isDark, Color textColor) {
    const accent = Color(0xFF6366F1);
    const stepColor = Color(0xFF00E676);
    final latest = data?.latest;
    final hasEntry = latest != null;

    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (hasEntry ? stepColor : accent).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasEntry ? Icons.task_alt_rounded : Icons.edit_note_rounded,
              color: hasEntry ? stepColor : accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Entry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: hasEntry ? stepColor : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        hasEntry
                            ? 'Last logged at ${DateFormat('h:mm a').format(latest.createdAt)}'
                            : 'Not logged today',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasEntry)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: stepColor),
              tooltip: 'Edit Steps',
              onPressed: () => _openEntry(existing: latest),
            ),
          TextButton(
            onPressed: () => _openEntry(),
            style: TextButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Log Steps',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
