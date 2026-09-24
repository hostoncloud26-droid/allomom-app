// Ported from AlloConnect lib/features/health_section/vitals/blood_pressure/views/blood_pressure_daily_view.dart.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/models/blood_pressure_models.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/edit_blood_pressure_sheet.dart';
import 'package:fl_chart/fl_chart.dart';

class BloodPressureDailyView extends StatefulWidget {
  final String userId;
  const BloodPressureDailyView({super.key, required this.userId});

  @override
  State<BloodPressureDailyView> createState() => _BloodPressureDailyViewState();
}

class _BloodPressureDailyViewState extends State<BloodPressureDailyView> {
  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;
  final RxList<BloodPressureEntry> _history = <BloodPressureEntry>[].obs;
  final RxList<VitalsStreamResponse> _vitals = <VitalsStreamResponse>[].obs;
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
        'blood_pressure',
        fromDate: from,
        toDate: now,
      );

      // Keep vitals in the same (ascending) order as _history so list rows
      // map to the right record for editing.
      _vitals.value = List<VitalsStreamResponse>.from(result)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _history.value =
          result.map((v) => BloodPressureEntry.fromVital(v)).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (_history.isEmpty && _vitalsController.error.isNotEmpty) {
        _error.value = _vitalsController.error;
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_isLoading.value && _history.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_history.isEmpty) {
        return Column(
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.monitor_heart_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No measurements recorded for today',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error.value,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      }

      final entries = _history;
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      final latest = entries.last;
      final avgSys =
          entries.map((e) => e.systolic).reduce((a, b) => a + b) /
          entries.length;
      final avgDia =
          entries.map((e) => e.diastolic).reduce((a, b) => a + b) /
          entries.length;

      // Simple variability calculation (Std Dev or Range)

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentBP(latest, isDarkMode),
          const SizedBox(height: 24),
          _buildTrendChart(entries, isDarkMode),
          const SizedBox(height: 24),
          const Text(
            'Summary Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _buildSummaryGrid(avgSys, avgDia, entries),
          const SizedBox(height: 24),
          _buildTimeInsights(entries, isDarkMode),
          const SizedBox(height: 32),
          const Text(
            'Recent Measurements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          _buildMeasurementList(entries, isDarkMode),
          const SizedBox(height: 100),
        ],
      );
    });
  }

  Widget _buildCurrentBP(BloodPressureEntry entry, bool isDark) {
    final category = entry.category;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: category.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Reading',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: category.color,
                ),
              ),
              Text(
                DateFormat('h:mm a').format(entry.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: category.color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${entry.systolic}/${entry.diastolic}',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'mmHg',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              category.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<BloodPressureEntry> entries, bool isDark) {
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: LineChart(
        LineChartData(
          minY: 40,
          maxY: 200,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox();
                  }
                  final time = entries[index].timestamp;
                  // Only show titles for some points if too many
                  if (entries.length > 5 &&
                      index % (entries.length ~/ 3) != 0) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(time),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: entries
                  .asMap()
                  .entries
                  .map(
                    (e) =>
                        FlSpot(e.key.toDouble(), e.value.systolic.toDouble()),
                  )
                  .toList(),
              isCurved: true,
              color: const Color(0xFFE91E63),
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE91E63).withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: entries
                  .asMap()
                  .entries
                  .map(
                    (e) =>
                        FlSpot(e.key.toDouble(), e.value.diastolic.toDouble()),
                  )
                  .toList(),
              isCurved: true,
              color: const Color(0xFF2196F3),
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
    double avgSys,
    double avgDia,
    List<BloodPressureEntry> entries,
  ) {
    final maxSys = entries
        .map((e) => e.systolic)
        .reduce((a, b) => a > b ? a : b);
    final minSys = entries
        .map((e) => e.systolic)
        .reduce((a, b) => a < b ? a : b);
    final hyperPerc =
        (entries.where((e) => e.category != BPCategory.normal).length /
            entries.length) *
        100;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Avg BP',
          '${avgSys.toInt()}/${avgDia.toInt()}',
          'mmHg',
          const Color(0xFF673AB7),
        ),
        _buildSummaryCard(
          'Systolic Range',
          '$minSys-$maxSys',
          'mmHg',
          const Color(0xFFE91E63),
        ),
        _buildSummaryCard(
          'Hypertension %',
          '${hyperPerc.toInt()}%',
          'time elevated',
          const Color(0xFFFF5252),
        ),
        _buildSummaryCard(
          'Total Count',
          '${entries.length}',
          'readings',
          const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimeInsights(List<BloodPressureEntry> entries, bool isDark) {
    // Group by morning (before 12pm) and evening (after 12pm)
    final morning = entries.where((e) => e.timestamp.hour < 12).toList();
    final evening = entries.where((e) => e.timestamp.hour >= 12).toList();

    return Column(
      children: [
        _buildInsightRow(
          'Morning Average',
          morning,
          const Color(0xFFFFC107),
          Icons.wb_sunny_rounded,
        ),
        const SizedBox(height: 12),
        _buildInsightRow(
          'Evening Average',
          evening,
          const Color(0xFF3F51B5),
          Icons.nights_stay_rounded,
        ),
      ],
    );
  }

  Widget _buildInsightRow(
    String label,
    List<BloodPressureEntry> list,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String value = '-- / --';
    if (list.isNotEmpty) {
      final s =
          list.map((e) => e.systolic).reduce((a, b) => a + b) / list.length;
      final d =
          list.map((e) => e.diastolic).reduce((a, b) => a + b) / list.length;
      value = '${s.toInt()}/${d.toInt()}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'mmHg',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementList(List<BloodPressureEntry> entries, bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries.reversed.toList()[index];
        final category = entry.category;

        // Get the original vital for edit (need to check source)
        final vitalIndex = entries.length - 1 - index;
        final originalVital = _vitals.length > vitalIndex
            ? _vitals[vitalIndex]
            : null;
        final source = originalVital?.data?['source'] as String? ?? '';
        final isFromAllowear = source == 'allowear';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('h:mm a').format(entry.timestamp),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.systolic}/${entry.diastolic}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF673AB7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (entry.pulse != null)
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.pulse} bpm',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (!isFromAllowear && originalVital != null) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showEditDialog(originalVital, isDark),
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Colors.orange.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(VitalsStreamResponse vital, bool isDark) {
    showEditBloodPressureSheet(
      context,
      vital: vital,
      userId: widget.userId,
      onUpdate: () {
        _fetchData();
        _vitalsController.fetchLatestVitals(showLoading: false);
      },
    );
  }
}
