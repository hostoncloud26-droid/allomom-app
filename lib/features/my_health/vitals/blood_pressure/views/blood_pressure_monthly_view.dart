// Ported from AlloConnect lib/features/health_section/vitals/blood_pressure/views/blood_pressure_monthly_view.dart.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/models/blood_pressure_models.dart';
import 'package:allomom/controllers/health_vital_controller.dart';

class BloodPressureMonthlyView extends StatefulWidget {
  final String userId;
  const BloodPressureMonthlyView({super.key, required this.userId});

  @override
  State<BloodPressureMonthlyView> createState() =>
      _BloodPressureMonthlyViewState();
}

class _BloodPressureMonthlyViewState extends State<BloodPressureMonthlyView> {
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
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      final result = await _vitalsController.getVitalsHistory(
        widget.userId,
        'blood_pressure',
        fromDate: monthAgo,
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

      final stats = DailyBloodPressureStats.fromHistory(_history);
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      if (stats.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 100),
            child: Text('No data for the past month.'),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          ...stats.reversed.map((s) => _buildStatTile(s, isDarkMode)),
        ],
      );
    });
  }

  Widget _buildStatTile(DailyBloodPressureStats stat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            DateFormat('d MMM').format(stat.date),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            '${stat.avgSystolic.toInt()}/${stat.avgDiastolic.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
}
