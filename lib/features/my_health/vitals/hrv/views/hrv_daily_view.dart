import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';
import 'package:allomom/features/my_health/vitals/hrv/hrv_entry_dialog.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

class HrvDailyView extends StatefulWidget {
  final String userId;
  const HrvDailyView({super.key, required this.userId});

  @override
  State<HrvDailyView> createState() => _HrvDailyViewState();
}

class _HrvDailyViewState extends State<HrvDailyView> {
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

      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);

      final result = await _vitalsController.getVitalsHistory(
        widget.userId,
        'hrv',
        fromDate: from,
        toDate: now,
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

  Color _getHrvColor(double ms) {
    if (ms >= 50) return const Color(0xFF00C896);
    if (ms >= 30) return const Color(0xFF7C4DFF);
    return const Color(0xFFFFAB40);
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
            title: 'No activity for today',
            subtitle: 'Try taking a new recording or check back later!',
            icon: Icons.monitor_heart_rounded,
            iconColor: const Color(0xFF7C4DFF),
          ),
        );
      }

      final sortedHistory = List<VitalsStreamResponse>.from(_history)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(sortedHistory, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildChart(sortedHistory, isDarkMode, textColor),
          const SizedBox(height: 24),
          _buildLog(sortedHistory, isDarkMode, textColor),
        ],
      );
    });
  }

  Widget _buildQuickStats(
    List<VitalsStreamResponse> history,
    bool isDark,
    Color textColor,
  ) {
    double sum = 0;
    double max = 0;
    double min = history.first.value;

    for (var item in history) {
      sum += item.value;
      if (item.value > max) max = item.value;
      if (item.value < min) min = item.value;
    }
    final avg = sum / history.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg',
            avg.round().toString(),
            const Color(0xFF7C4DFF),
            isDark,
            textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Max',
            max.round().toString(),
            const Color(0xFF00C896),
            isDark,
            textColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Min',
            min.round().toString(),
            const Color(0xFFFFAB40),
            isDark,
            textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
      ),
    );
  }

  Widget _buildChart(
    List<VitalsStreamResponse> history,
    bool isDark,
    Color textColor,
  ) {
    // Dynamically compute min/max from actual readings with ±10 ms padding,
    // then snap to the nearest multiple of 10 for clean axis ticks.
    final values = history.map((e) => e.value).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final chartMinY =
        ((dataMin - 10).clamp(0, double.infinity) / 10).floor() * 10.0;
    final chartMaxY = ((dataMax + 10) / 10).ceil() * 10.0;
    // Choose a label interval that yields ~4–5 gridlines.
    final range = chartMaxY - chartMinY;
    final leftInterval = (range / 4).clamp(5, 50).ceilToDouble();

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: LineChart(
        LineChartData(
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
                interval: (history.length / 4).clamp(1, 100).toDouble(),
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < history.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('HH:mm').format(history[idx].createdAt),
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 10,
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
          lineBarsData: [
            LineChartBarData(
              spots: history
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00C896),
                  const Color(0xFF7C4DFF),
                  const Color(0xFFFFAB40),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, bar, idx) => FlDotCirclePainter(
                  radius: 3,
                  color: _getHrvColor(spot.y),
                  strokeWidth: 1.5,
                  strokeColor: isDark ? const Color(0xFF0F131A) : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00C896).withValues(alpha: 0.1),
                    const Color(0xFF7C4DFF).withValues(alpha: 0.02),
                    const Color(0xFFFFAB40).withValues(alpha: 0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLog(
    List<VitalsStreamResponse> history,
    bool isDark,
    Color textColor,
  ) {
    final reversedHistory = history.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        ...reversedHistory.map(
          (item) => _buildLogItem(item, isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildLogItem(
    VitalsStreamResponse item,
    bool isDark,
    Color textColor,
  ) {
    final color = _getHrvColor(item.value);
    final source = item.data?['source'] as String? ?? '';
    final isFromAllowear = source == 'allowear';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isFromAllowear ? null : () => _editHrv(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.monitor_heart_rounded, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.value.toInt()} ms',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(item.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.value >= 50
                  ? 'Good'
                  : (item.value < 30 ? 'Low' : 'Balanced'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (!isFromAllowear) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _deleteHrv(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editHrv(VitalsStreamResponse item) async {
    final updated = await showHrvEntryDialog(context, item: item);
    if (updated == true) {
      await _fetchData();
    }
  }

  Future<void> _deleteHrv(VitalsStreamResponse item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete HRV Reading',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this HRV reading?',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await VitalsSqLiteService().deleteVital(item.id);
      await _fetchData();
      _vitalsController.fetchLatestVitals(showLoading: false);
    }
  }
}
