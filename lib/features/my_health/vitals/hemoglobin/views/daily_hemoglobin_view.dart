// Day view, mirroring AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/views/daily_blood_oxygen_view.dart.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import '../models/hemoglobin_models.dart';
import '../widgets/hemoglobin_widgets.dart';

class DailyHemoglobinView extends StatefulWidget {
  final DateTime date;
  final VoidCallback onChanged;

  const DailyHemoglobinView({
    super.key,
    required this.date,
    required this.onChanged,
  });

  @override
  State<DailyHemoglobinView> createState() => _DailyHemoglobinViewState();
}

class _DailyHemoglobinViewState extends State<DailyHemoglobinView> {
  List<VitalsStreamResponse> _history = [];

  /// Most recent reading on or before the day, shown when the day is empty —
  /// hemoglobin is a lab value, taken every few weeks.
  VitalsStreamResponse? _lastKnown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final d = widget.date;
    final from = DateTime(d.year, d.month, d.day);
    final to = from
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    final day = await loadHemoglobinHistory(from, to);
    VitalsStreamResponse? last;
    if (day.isEmpty) {
      final older = await loadHemoglobinHistory(
        from.subtract(const Duration(days: 365)),
        to,
      );
      last = older.isEmpty ? null : older.first;
    }
    if (!mounted) return;
    setState(() {
      _history = day;
      _lastKnown = last;
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: VitalsEmptyState(
              title: isToday
                  ? 'No reading recorded today'
                  : 'No reading on this day',
              subtitle: 'Tap Add Hemoglobin to log your latest lab result.',
              icon: Icons.bloodtype_outlined,
              iconColor: kHemoglobinColor,
            ),
          ),
          if (_lastKnown != null) ...[
            const HbSectionTitle('Last Recorded'),
            const SizedBox(height: 16),
            HbReadingsList(
              readings: [HemoglobinReading(_lastKnown!)],
              onChanged: widget.onChanged,
            ),
          ],
        ],
      );
    }

    final agg = DailyHemoglobinAggregate.fromReadings(
      widget.date,
      _history.map(HemoglobinReading.new).toList(),
    );
    final latest = agg.readings.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroStatus(latest, isDarkMode, textColor),
        const SizedBox(height: 24),
        HbStatGrid(
          cards: [
            HbStatCard(
              label: 'Average',
              value: '${agg.avg.toStringAsFixed(1)} g/dL',
              icon: Icons.analytics_outlined,
              color: Colors.blue,
            ),
            HbStatCard(
              label: 'Lowest',
              value: '${agg.min.toStringAsFixed(1)} g/dL',
              icon: Icons.trending_down,
              color: Colors.orange,
            ),
            HbStatCard(
              label: 'Highest',
              value: '${agg.max.toStringAsFixed(1)} g/dL',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            HbStatCard(
              label: 'Readings',
              value: '${agg.readings.length}',
              icon: Icons.format_list_numbered_rounded,
              color: kHemoglobinColor,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildTrendGraph(agg, isDarkMode, textColor),
        const SizedBox(height: 32),
        const HbSectionTitle('Smart Insights'),
        const SizedBox(height: 16),
        ...hbInsightsFor(agg.avg),
        const SizedBox(height: 20),
        const HbSectionTitle('Readings'),
        const SizedBox(height: 16),
        HbReadingsList(
          readings: agg.readings,
          showDate: false,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }

  Widget _buildHeroStatus(
    HemoglobinReading reading,
    bool isDark,
    Color textColor,
  ) {
    final color = reading.category.color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: hbCardDecoration(isDark, radius: 32),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: (reading.value / 16).clamp(0.0, 1.0),
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
                    reading.value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'g/dL',
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
                  'Last updated: ${DateFormat('h:mm a').format(reading.timestamp)}',
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
                    'Target: above $kHbTarget g/dL',
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
    DailyHemoglobinAggregate data,
    bool isDark,
    Color textColor,
  ) {
    final spots = data.readings
        .map((r) => FlSpot(r.timestamp.hour + r.timestamp.minute / 60, r.value))
        .toList();
    final minDataX = spots.first.x;
    final maxDataX = spots.last.x;
    final range = maxDataX - minDataX;
    final minX = range < 1 ? (minDataX - 1).clamp(0.0, 24.0) : minDataX;
    final maxX = range < 1 ? (maxDataX + 1).clamp(0.0, 24.0) : maxDataX;
    final minY = [8.0, data.min - 1].reduce((a, b) => a < b ? a : b);
    final maxY = [16.0, data.max + 1].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HbSectionTitle('Hemoglobin Trend'),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          decoration: hbCardDecoration(isDark),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: kHbBandMin,
                    y2: kHbBandMax,
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
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value % 2 == 0) {
                        return Text(
                          value.toInt().toString(),
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
              minY: minY.floorToDouble(),
              maxY: maxY.ceilToDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: spots.length > 2,
                  color: kHemoglobinColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        kHemoglobinColor.withValues(alpha: 0.2),
                        kHemoglobinColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Anaemia threshold (11 g/dL)
                LineChartBarData(
                  spots: [FlSpot(minX, 11), FlSpot(maxX, 11)],
                  isCurved: false,
                  color: Colors.red.withValues(alpha: 0.25),
                  barWidth: 1,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
