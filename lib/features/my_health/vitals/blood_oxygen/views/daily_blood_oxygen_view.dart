import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/models/blood_oxygen_models.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';

class DailyBloodOxygenView extends StatefulWidget {
  final String userId;

  const DailyBloodOxygenView({
    super.key,
    required this.userId,
  });

  @override
  State<DailyBloodOxygenView> createState() => _DailyBloodOxygenViewState();
}

class _DailyBloodOxygenViewState extends State<DailyBloodOxygenView> {
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

      final now = DateTime.now();
      final from = now.subtract(const Duration(hours: 24));

      _history.value = await HealthVitalsController.instance.getVitalsHistory(
        widget.userId,
        'blood_oxygen',
        fromDate: from,
        toDate: now,
      );
    } catch (e) {
      _error.value = e.toString();
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

      final data = DailyBloodOxygenAggregate.fromRolling24Hours(_history);

      if (data == null) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: VitalsEmptyState(
            title: 'No data recorded today',
            subtitle:
                'Tap Add SpO₂ to log a reading, or wear your device to track your blood oxygen levels.',
            icon: Icons.monitor_heart_outlined,
            iconColor: const Color(0xFF00E5FF),
          ),
        );
      }

      final latest = data.readings.last;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroStatus(latest, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildQuickStats(data, isDarkMode, textColor),
          const SizedBox(height: 32),
          _buildTrendGraph(data, isDarkMode, textColor),
          const SizedBox(height: 32),
          _buildSleepAnalysis(data, isDarkMode, textColor),
          const SizedBox(height: 32),
          _buildInsights(data, isDarkMode, textColor),
        ],
      );
    });
  }

  Widget _buildHeroStatus(
    BloodOxygenStats stats,
    bool isDark,
    Color textColor,
  ) {
    final oxygenColor = _getSpO2Color(stats.value.toInt());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: stats.value / 100,
                  strokeWidth: 8,
                  backgroundColor: oxygenColor.withValues(alpha: 0.1),
                  color: oxygenColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stats.value.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '%',
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
                  _getSpO2StatusLabel(stats.value.toInt()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: oxygenColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${_formatTime(stats.timestamp)}',
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
                    color: oxygenColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Normal range: 95-100%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: oxygenColor,
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

  Widget _buildQuickStats(
    DailyBloodOxygenAggregate data,
    bool isDark,
    Color textColor,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          'Average SpO₂',
          '${data.avgSpO2.toStringAsFixed(1)}%',
          Icons.analytics_outlined,
          Colors.blue,
          isDark,
          textColor,
        ),
        _buildStatCard(
          'Minimum SpO₂',
          '${data.minSpO2.toInt()}%',
          Icons.trending_down,
          Colors.orange,
          isDark,
          textColor,
        ),
        _buildStatCard(
          'Time Below 94%',
          '${data.timeBelow94Percent} min',
          Icons.timer_outlined,
          Colors.redAccent,
          isDark,
          textColor,
        ),
        _buildStatCard(
          'Oxygen Drops',
          '${data.desaturationEvents}',
          Icons.warning_amber_rounded,
          Colors.deepOrange,
          isDark,
          textColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendGraph(
    DailyBloodOxygenAggregate data,
    bool isDark,
    Color textColor,
  ) {
    final spots = _generateSpots(data.readings);
    if (spots.isEmpty) return const SizedBox.shrink();

    // Calculate dynamic X-axis range based on available data
    final minDataX = spots.first.x;
    final maxDataX = spots.last.x;

    // Add a small buffer if there's only one point or very close points
    final range = maxDataX - minDataX;
    final minX = range < 1 ? minDataX - 1 : minDataX;
    final maxX = range < 1 ? maxDataX + 1 : maxDataX;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oxygen Trend',
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
                    reservedSize: 24,
                    interval: range > 12 ? 4 : (range > 6 ? 2 : 1),
                    getTitlesWidget: (val, meta) {
                      final now = DateTime.now();
                      final hoursAgo = (24 - val).toInt();
                      final hourAtVal = now.subtract(Duration(hours: hoursAgo));

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${hourAtVal.hour.toString().padLeft(2, '0')}:00',
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
              minY: 85,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF00E5FF),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        const Color(0xFF00E5FF).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Threshold line (94%) across the dynamic range
                LineChartBarData(
                  spots: [FlSpot(minX, 94), FlSpot(maxX, 94)],
                  isCurved: false,
                  color: Colors.red.withValues(alpha: 0.2),
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

  Widget _buildSleepAnalysis(
    DailyBloodOxygenAggregate data,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1C30), const Color(0xFF0A111F)]
              : [const Color(0xFFF0F4FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.nightlight_round_rounded,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sleep Oxygen Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSleepMiniStat(
                  'Lowest SpO₂',
                  '${data.lowestSleepSpO2.toInt()}%',
                  textColor,
                ),
              ),
              Expanded(
                child: _buildSleepMiniStat(
                  'Drops',
                  '${data.sleepDesaturationEvents}',
                  textColor,
                ),
              ),
              Expanded(
                child: _buildSleepMiniStat(
                  'Apnea Risk',
                  data.sleepDesaturationEvents > 5 ? 'Elevated' : 'Low',
                  textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Levels remained stable during sleep, indicating good respiratory recovery.',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepMiniStat(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(
    DailyBloodOxygenAggregate data,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildInsightItem(
          data.avgSpO2 >= 95
              ? 'Your oxygen levels are stable and optimal.'
              : 'Mild fluctuations detected in your oxygen levels.',
          data.avgSpO2 >= 95
              ? Icons.check_circle_rounded
              : Icons.info_outline_rounded,
          data.avgSpO2 >= 95 ? Colors.green : Colors.orange,
          isDark,
          textColor,
        ),
        const SizedBox(height: 12),
        if (data.desaturationEvents > 0)
          _buildInsightItem(
            'We detected minor drops during sleep. Ensure your wearing position is correct.',
            Icons.lightbulb_outline_rounded,
            Colors.blue,
            isDark,
            textColor,
          ),
      ],
    );
  }

  Widget _buildInsightItem(
    String text,
    IconData icon,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots(List<BloodOxygenStats> readings) {
    if (readings.isEmpty) return [];

    final now = DateTime.now();

    // Group by hour relative to 24h window
    final Map<int, List<double>> hourlySlots = {};
    for (var r in readings) {
      final hoursAgo = now.difference(r.timestamp).inHours;
      if (hoursAgo >= 0 && hoursAgo < 24) {
        final slot = 24 - hoursAgo;
        if (!hourlySlots.containsKey(slot)) hourlySlots[slot] = [];
        hourlySlots[slot]!.add(r.value);
      }
    }

    final List<FlSpot> spots = [];
    hourlySlots.forEach((slot, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      spots.add(FlSpot(slot.toDouble(), avg));
    });

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  Color _getSpO2Color(int spO2) {
    if (spO2 >= 95) return const Color(0xFF00E5FF);
    if (spO2 >= 90) return const Color(0xFF4CAF50);
    if (spO2 >= 85) return const Color(0xFFFFB300);
    return const Color(0xFFFF5252);
  }

  String _getSpO2StatusLabel(int spO2) {
    if (spO2 >= 95) return 'Optimal Concentration';
    if (spO2 >= 90) return 'Normal Levels';
    if (spO2 >= 85) return 'Mildly Low';
    return 'Critical Low';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
