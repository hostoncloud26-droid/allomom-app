// Day view, mirroring AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/views/daily_blood_oxygen_view.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../models/blood_glucose_models.dart';
import '../widgets/blood_glucose_widgets.dart';

class DailyBloodGlucoseView extends StatefulWidget {
  final DateTime date;
  final VoidCallback onChanged;

  const DailyBloodGlucoseView({
    super.key,
    required this.date,
    required this.onChanged,
  });

  @override
  State<DailyBloodGlucoseView> createState() => _DailyBloodGlucoseViewState();
}

class _DailyBloodGlucoseViewState extends State<DailyBloodGlucoseView> {
  List<VitalsStreamResponse> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final d = widget.date;
    final from = DateTime(d.year, d.month, d.day);
    final to = from
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    final result = await loadGlucoseHistory(from, to);
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
      final isToday = DateUtils.isSameDay(widget.date, DateTime.now());
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: VitalsEmptyState(
          title: isToday ? 'No data recorded today' : 'No data on this day',
          subtitle:
              'Tap Add Glucose to log your fasting and post-meal readings.',
          icon: Icons.bloodtype_outlined,
          iconColor: kGlucoseColor,
        ),
      );
    }

    final readings = _history.map(GlucoseReading.new).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final stats = GlucoseStats(readings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroStatus(readings.last, isDarkMode, textColor),
        const SizedBox(height: 24),
        GlucoseStatGrid(stats: stats),
        const SizedBox(height: 32),
        _buildTrendGraph(readings, isDarkMode, textColor),
        const SizedBox(height: 32),
        const GlucoseSectionTitle('Smart Insights'),
        const SizedBox(height: 16),
        ...glucoseInsightsFor(stats),
        const SizedBox(height: 20),
        const GlucoseSectionTitle('Readings'),
        const SizedBox(height: 16),
        GlucoseReadingsList(
          readings: readings,
          showDate: false,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }

  Widget _buildHeroStatus(
    GlucoseReading reading,
    bool isDark,
    Color textColor,
  ) {
    final color = reading.category.color;
    final target = glucoseTargetFor(reading.mealPhase);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: glucoseCardDecoration(isDark, radius: 32),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: (reading.value / 200).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatMgDl(reading.value),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'mg/dL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading.category.label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${glucosePhaseLabel(reading.mealPhase)} · '
                  '${DateFormat('h:mm a').format(reading.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Target: below ${target.toInt()} mg/dL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendGraph(
    List<GlucoseReading> readings,
    bool isDark,
    Color textColor,
  ) {
    final spots = readings
        .map((r) => FlSpot(r.timestamp.hour + r.timestamp.minute / 60, r.value))
        .toList();
    final minDataX = spots.first.x;
    final maxDataX = spots.last.x;
    final range = maxDataX - minDataX;
    final double minX = range < 1 ? (minDataX - 1).clamp(0.0, 24.0) : minDataX;
    final double maxX = range < 1 ? (maxDataX + 1).clamp(0.0, 24.0) : maxDataX;
    final values = readings.map((r) => r.value);
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

    LineChartBarData threshold(double y, Color color) => LineChartBarData(
      spots: [FlSpot(minX, y), FlSpot(maxX, y)],
      isCurved: false,
      color: color,
      barWidth: 1,
      dashArray: [5, 5],
      dotData: const FlDotData(show: false),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlucoseSectionTitle('Glucose Trend'),
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
                    reservedSize: 24,
                    interval: (maxX - minX) > 12
                        ? 4
                        : ((maxX - minX) > 6 ? 2 : 1),
                    getTitlesWidget: (val, meta) {
                      if (val != val.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${val.toInt().toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: spots.length > 2,
                  preventCurveOverShooting: true,
                  color: kGlucoseColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: readings[index].category.color,
                          strokeWidth: 2,
                          strokeColor: isDark
                              ? const Color(0xFF0A111F)
                              : Colors.white,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        kGlucoseColor.withValues(alpha: 0.2),
                        kGlucoseColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Fasting (95) and post-meal (120) targets
                threshold(
                  kGlucoseFastingTarget,
                  Colors.orange.withValues(alpha: 0.35),
                ),
                threshold(
                  kGlucosePostMealTarget,
                  Colors.red.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legend(
              'Fasting < ${kGlucoseFastingTarget.toInt()}',
              Colors.orange,
              textColor,
            ),
            const SizedBox(width: 16),
            _legend(
              'Post-meal < ${kGlucosePostMealTarget.toInt()}',
              Colors.red,
              textColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _legend(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 2, color: color.withValues(alpha: 0.6)),
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
}
