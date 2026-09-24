// Ported from AlloConnect
// lib/features/health_section/vitals/stress/stress_summary_screen.dart
// (Allomom addition: a "+" action that opens showStressEntrySheet).
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/features/my_health/vitals/stress/stress_entry_sheet.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';

class StressSummaryScreen extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;
  final int initialStress;
  final DateTime? lastUpdatedAt;

  const StressSummaryScreen({
    super.key,
    this.userId,
    this.initialStress = 0,
    this.lastUpdatedAt,
  });

  @override
  State<StressSummaryScreen> createState() => _StressSummaryScreenState();
}

class _StressSummaryScreenState extends State<StressSummaryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Overview', 'Trend', 'Insights'];

  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;
  bool _isLoadingHistory = false;
  String _historyError = '';
  List<_StressReading> _history = const [];

  @override
  void initState() {
    super.initState();
    _fetchStressHistory();
  }

  Future<void> _fetchStressHistory() async {
    final explicitUserId = widget.userId?.trim() ?? '';
    final userId = explicitUserId.isNotEmpty
        ? explicitUserId
        : MainController.instance.userId.trim();
    if (userId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _history = const [];
        _historyError = 'User not found for stress history.';
      });
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoadingHistory = true;
          _historyError = '';
        });
      }

      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30));
      final result = await _vitalsController.getVitalsHistory(
        userId,
        'stress',
        fromDate: fromDate,
        toDate: now,
      );

      if (!mounted) {
        return;
      }

      final readings = <_StressReading>[];
      for (final vital in result) {
        try {
          final reading = _StressReading.fromVital(vital);
          if (reading != null) {
            readings.add(reading);
          }
        } catch (_) {
          // Skip malformed payloads so valid data still renders.
        }
      }

      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _history = readings;
        _isLoadingHistory = false;
        if (_history.isEmpty && _vitalsController.error.isNotEmpty) {
          _historyError = _vitalsController.error;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _historyError = 'Unable to load stress history right now.';
        _isLoadingHistory = false;
      });
    }
  }

  int _normalizeStress(num raw) {
    if (raw <= 0) {
      return 0;
    }
    return raw.round().clamp(1, 100).toInt();
  }

  _StressReading get _latestReading {
    if (_history.isNotEmpty) {
      return _history.last;
    }
    final latestVital = _vitalsController.stressVital;
    if (widget.initialStress <= 0 && latestVital != null) {
      return _StressReading(
        timestamp: latestVital.createdAt.toLocal(),
        value: _normalizeStress(latestVital.value),
      );
    }
    return _StressReading(
      timestamp: widget.lastUpdatedAt?.toLocal() ?? DateTime.now(),
      value: _normalizeStress(widget.initialStress),
    );
  }

  DateTime? get _lastUpdated {
    if (_history.isNotEmpty) {
      return _history.last.timestamp;
    }
    return widget.lastUpdatedAt?.toLocal() ??
        _vitalsController.stressVital?.createdAt.toLocal();
  }

  Future<void> _openEntrySheet() async {
    final saved = await showStressEntrySheet(
      context,
      initialValue: _latestReading.value > 0 ? _latestReading.value : null,
    );
    if (saved == true && mounted) {
      await _fetchStressHistory();
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'No recent sync';
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

  Color _stressColor(int stress) {
    if (stress <= 0) {
      return Colors.blueGrey.shade400;
    }
    if (stress <= 15) {
      return const Color(0xFF10B981); // emerald - calm
    }
    if (stress <= 30) {
      return const Color(0xFF84CC16); // lime - relaxed
    }
    if (stress <= 50) {
      return const Color(0xFF0EA5E9); // sky - normal
    }
    if (stress <= 70) {
      return const Color(0xFFF59E0B); // amber - slightly tense
    }
    if (stress <= 85) {
      return const Color(0xFFF97316); // orange - tense
    }
    return const Color(0xFFEF4444); // red - overwhelmed
  }

  String _stressLabel(int stress) {
    if (stress <= 0) {
      return 'No Data';
    }
    if (stress <= 15) {
      return 'Calm';
    }
    if (stress <= 30) {
      return 'Relaxed';
    }
    if (stress <= 50) {
      return 'Normal';
    }
    if (stress <= 70) {
      return 'Slightly tense';
    }
    if (stress <= 85) {
      return 'Tense';
    }
    return 'Overwhelmed';
  }

  String _stressNarrative(int stress) {
    if (stress <= 0) {
      return 'No stress values found yet. Log your stress score to unlock insights.';
    }
    if (stress <= 15) {
      return 'Total serenity. Your nervous system is in an optimal state of recovery.';
    }
    if (stress <= 30) {
      return 'Balanced and relaxed. You are maintaining a healthy level of calm.';
    }
    if (stress <= 50) {
      return 'Standard daily activity. Your body is handling the current load well.';
    }
    if (stress <= 70) {
      return 'Stress is mounting. Consider a quick mindful pause to reset.';
    }
    if (stress <= 85) {
      return 'High load detected. Your body needs a break to prevent burnout.';
    }
    return 'System overloaded. Stop everything and focus on deep recovery now.';
  }

  List<_StressDayPoint> _dailySeries(int days) {
    final normalizedNow = DateTime.now();
    final today = DateTime(
      normalizedNow.year,
      normalizedNow.month,
      normalizedNow.day,
    );

    final grouped = <String, List<_StressReading>>{};
    for (final reading in _history) {
      final key = DateFormat('yyyy-MM-dd').format(reading.timestamp);
      grouped.putIfAbsent(key, () => <_StressReading>[]).add(reading);
    }

    final output = <_StressDayPoint>[];
    for (var offset = days - 1; offset >= 0; offset--) {
      final day = today.subtract(Duration(days: offset));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final dayReadings = grouped[key] ?? const <_StressReading>[];

      if (dayReadings.isEmpty) {
        output.add(_StressDayPoint(day: day, value: 0, hasData: false));
      } else {
        final avg =
            dayReadings.map((entry) => entry.value).reduce((a, b) => a + b) /
            dayReadings.length;
        output.add(
          _StressDayPoint(
            day: day,
            value: avg.round().clamp(1, 100).toInt(),
            hasData: true,
          ),
        );
      }
    }

    return output;
  }

  List<_StressDayPoint> get _last7Days => _dailySeries(7);

  List<_StressDayPoint> get _last14Days => _dailySeries(14);

  double get _sevenDayAverage {
    final values = _last7Days
        .where((entry) => entry.hasData)
        .map((entry) => entry.value)
        .toList();
    if (values.isEmpty) {
      return _latestReading.value.toDouble();
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  int get _weeklyPeak {
    final values = _last7Days
        .where((entry) => entry.hasData)
        .map((entry) => entry.value)
        .toList();
    if (values.isEmpty) {
      return _latestReading.value;
    }
    return values.reduce(math.max);
  }

  int get _calmDayPercent {
    final withData = _last7Days.where((entry) => entry.hasData).toList();
    if (withData.isEmpty) {
      return _latestReading.value <= 35 ? 100 : 0;
    }
    final calmDays = withData.where((entry) => entry.value <= 35).length;
    return ((calmDays / withData.length) * 100).round();
  }

  double get _volatility {
    final values = _last7Days
        .where((entry) => entry.hasData)
        .map((entry) => entry.value.toDouble())
        .toList();

    if (values.length < 2) {
      return 0;
    }

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values
            .map((value) => (value - mean) * (value - mean))
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }

  double get _trendDelta {
    final withData = _last7Days.where((entry) => entry.hasData).toList();
    if (withData.length < 2) {
      return 0;
    }
    return (withData.last.value - withData.first.value).toDouble();
  }

  int get _highStressSamples {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return _history
        .where((entry) => entry.timestamp.isAfter(start) && entry.value >= 75)
        .length;
  }

  List<_StressInsight> _composeInsights() {
    final latest = _latestReading.value;
    final suggestions = <_StressInsight>[];

    if (latest >= 80) {
      suggestions.add(
        _StressInsight(
          title: 'Immediate down-regulation',
          description:
              'Your latest stress score is high. Start with a 4-7-8 breathing cycle for 2-3 minutes.',
          icon: Icons.air_rounded,
          color: const Color(0xFFEF4444),
        ),
      );
    } else if (latest >= 60) {
      suggestions.add(
        _StressInsight(
          title: 'Schedule micro-breaks',
          description:
              'Stress is elevated. Add a short pause every 90 minutes to prevent overload.',
          icon: Icons.pause_circle_filled_rounded,
          color: const Color(0xFFD97706),
        ),
      );
    } else {
      suggestions.add(
        _StressInsight(
          title: 'Protect your calm window',
          description:
              'Your stress is in a controlled zone. Keep hydration, movement, and sleep consistency.',
          icon: Icons.self_improvement_rounded,
          color: const Color(0xFF16A34A),
        ),
      );
    }

    if (_trendDelta >= 10) {
      suggestions.add(
        _StressInsight(
          title: 'Rising weekly pattern',
          description:
              'Your 7-day trend is climbing by ${_trendDelta.round()} points. Try reducing evening workload.',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFFDC2626),
        ),
      );
    } else if (_trendDelta <= -10) {
      suggestions.add(
        _StressInsight(
          title: 'Recovery trend improving',
          description:
              'Great momentum. Stress dropped by ${_trendDelta.abs().round()} points over the week.',
          icon: Icons.trending_down_rounded,
          color: const Color(0xFF16A34A),
        ),
      );
    }

    if (_volatility >= 16) {
      suggestions.add(
        _StressInsight(
          title: 'High variability detected',
          description:
              'Frequent spikes suggest uneven load. Keep meals, sleep, and breaks on a fixed schedule.',
          icon: Icons.show_chart_rounded,
          color: const Color(0xFF0EA5E9),
        ),
      );
    }

    if (_highStressSamples >= 5) {
      suggestions.add(
        _StressInsight(
          title: 'Frequent high-stress episodes',
          description:
              'You had $_highStressSamples high-stress moments this week. Reduce caffeine late in the day.',
          icon: Icons.warning_rounded,
          color: const Color(0xFFB91C1C),
        ),
      );
    }

    if (suggestions.length < 2) {
      suggestions.add(
        _StressInsight(
          title: 'Keep momentum',
          description:
              'Your stress profile looks stable. Continue regular sleep timing and light daily activity.',
          icon: Icons.verified_rounded,
          color: const Color(0xFF0EA5E9),
        ),
      );
    }

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF0A111F)
        : const Color(0xFFF8FAFF);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Stress Analysis',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Log stress',
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: textColor.withValues(alpha: 0.8),
              size: 24,
            ),
            onPressed: _openEntrySheet,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStressHistory,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VitalBabyBanner(),
                _buildFilterToggle(isDarkMode, textColor),
                const SizedBox(height: 22),
                if (_historyError.isNotEmpty)
                  _buildErrorBanner(isDarkMode, textColor),
                if (_isLoadingHistory && _history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: _buildCurrentView(isDarkMode, textColor),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToggle(bool isDarkMode, Color textColor) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDarkMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected
                        ? textColor
                        : textColor.withValues(alpha: 0.5),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentView(bool isDarkMode, Color textColor) {
    switch (_selectedFilterIndex) {
      case 0:
        return _buildOverview(isDarkMode, textColor, key: const ValueKey('o'));
      case 1:
        return _buildTrend(isDarkMode, textColor, key: const ValueKey('t'));
      case 2:
        return _buildInsights(isDarkMode, textColor, key: const ValueKey('i'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverview(bool isDarkMode, Color textColor, {Key? key}) {
    final latest = _latestReading;
    final stress = latest.value;
    final stressColor = _stressColor(stress);
    final progress = (stress / 100).clamp(0.0, 1.0);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.32 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 168,
                    height: 168,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      color: stressColor,
                      backgroundColor: stressColor.withValues(alpha: 0.14),
                    ),
                  ),
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          stressColor.withValues(alpha: 0.2),
                          stressColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stress.toString(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'STRESS',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: stressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_stressLabel(stress)} · ${stress <= 0 ? 0 : stress.clamp(1, 100)}/100',
                  style: TextStyle(
                    color: stressColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _stressNarrative(stress),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.56),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildMetaChip(
                      icon: Icons.schedule_rounded,
                      label: 'Last Updated',
                      value: _formatDateTime(_lastUpdated),
                      textColor: textColor,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildOverviewStats(isDarkMode, textColor),
      ],
    );
  }

  Widget _buildOverviewStats(bool isDarkMode, Color textColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        final sevenDayAvg = _sevenDayAverage.round();
        final trendDelta = _trendDelta;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                title: '7-Day Avg',
                value: sevenDayAvg.toString(),
                subtitle: 'Average stress score',
                icon: Icons.query_stats_rounded,
                color: const Color(0xFF0EA5E9),
                isDarkMode: isDarkMode,
                textColor: textColor,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                title: 'Weekly Peak',
                value: _weeklyPeak.toString(),
                subtitle: 'Highest recorded day',
                icon: Icons.flash_on_rounded,
                color: const Color(0xFFD97706),
                isDarkMode: isDarkMode,
                textColor: textColor,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                title: 'Calm Days',
                value: '$_calmDayPercent%',
                subtitle: 'Days under score 35',
                icon: Icons.spa_rounded,
                color: const Color(0xFF16A34A),
                isDarkMode: isDarkMode,
                textColor: textColor,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildStatCard(
                title: 'Trend',
                value: trendDelta == 0
                    ? 'Stable'
                    : trendDelta > 0
                    ? '+${trendDelta.round()}'
                    : trendDelta.round().toString(),
                subtitle: '7-day direction',
                icon: trendDelta > 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_flat_rounded,
                color: trendDelta > 8
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF0EA5E9),
                isDarkMode: isDarkMode,
                textColor: textColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrend(bool isDarkMode, Color textColor, {Key? key}) {
    final hasData = _last14Days.any((entry) => entry.hasData);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasData)
          Container(
            margin: const EdgeInsets.only(top: 20),
            height: 380,
            child: VitalsEmptyState(
              title: 'No stress history yet',
              subtitle:
                  'Tap + at the top to log your stress score and see trend analytics here.',
              icon: Icons.stacked_line_chart_rounded,
              iconColor: const Color(0xFF0EA5E9),
            ),
          )
        else ...[
          _buildTrendChart(isDarkMode, textColor),
          const SizedBox(height: 18),
          _buildRecentReadings(isDarkMode, textColor),
        ],
      ],
    );
  }

  Widget _buildTrendChart(bool isDarkMode, Color textColor) {
    final series = _last14Days;
    final hasData = series.any((entry) => entry.hasData);

    final points = series.asMap().entries.map((entry) {
      final value = entry.value.hasData ? entry.value.value.toDouble() : 0.0;
      return FlSpot(entry.key.toDouble(), value);
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '14-Day Stress Trend',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Values are normalized on a 1-100 scale.',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Not enough data for trend yet.',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (series.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= series.length) {
                            return const SizedBox.shrink();
                          }
                          if (index % 2 != 0 && index != series.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('d MMM').format(series[index].day),
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.45),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      color: const Color(0xFF0EA5E9),
                      isCurved: true,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) {
                          final color = _stressColor(spot.y.round());
                          return FlDotCirclePainter(
                            radius: 3.5,
                            color: color,
                            strokeColor: color.withValues(alpha: 0.2),
                            strokeWidth: 1.8,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                            const Color(0xFF0EA5E9).withValues(alpha: 0.0),
                          ],
                        ),
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

  Widget _buildRecentReadings(bool isDarkMode, Color textColor) {
    final recent = _history.reversed.take(8).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Stress Samples',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Text(
              'No recent stress records.',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: recent.map((entry) {
                final color = _stressColor(entry.value);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM, hh:mm a').format(entry.timestamp),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}/100',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInsights(bool isDarkMode, Color textColor, {Key? key}) {
    final insights = _composeInsights();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personalized Stress Insights',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generated from your latest score, weekly trend, and stress variability.',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.48),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: insights.map((insight) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: insight.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: insight.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: insight.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            insight.icon,
                            color: insight.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insight.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                insight.description,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.56),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.52),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDarkMode, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _historyError,
              style: TextStyle(
                color: isDarkMode ? Colors.white : textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StressReading {
  final DateTime timestamp;
  final int value;

  const _StressReading({required this.timestamp, required this.value});

  static _StressReading? fromVital(VitalsStreamResponse vital) {
    if (vital.key != 'stress') {
      return null;
    }

    final value = vital.value.round();
    if (value <= 0) {
      return null;
    }

    return _StressReading(
      timestamp: vital.createdAt.toLocal(),
      value: value.clamp(1, 100).toInt(),
    );
  }
}

class _StressDayPoint {
  final DateTime day;
  final int value;
  final bool hasData;

  const _StressDayPoint({
    required this.day,
    required this.value,
    required this.hasData,
  });
}

class _StressInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _StressInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
