import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';

class BloodOxygenStats {
  final DateTime timestamp;
  final double value;
  final double? confidence;

  BloodOxygenStats({
    required this.timestamp,
    required this.value,
    this.confidence,
  });

  bool get isNormal => value >= 95;
  bool get isMildlyLow => value >= 90 && value < 95;
  bool get isCritical => value < 90;
}

class DailyBloodOxygenAggregate {
  final DateTime date;
  final double avgSpO2;
  final double minSpO2;
  final double maxSpO2;
  final int timeBelow94Percent; // Duration in minutes (approx)
  final int desaturationEvents;
  final List<BloodOxygenStats> readings;

  // Sleep Analysis Metrics
  final double lowestSleepSpO2;
  final int sleepDesaturationEvents;

  DailyBloodOxygenAggregate({
    required this.date,
    required this.avgSpO2,
    required this.minSpO2,
    required this.maxSpO2,
    this.timeBelow94Percent = 0,
    this.desaturationEvents = 0,
    required this.readings,
    this.lowestSleepSpO2 = 0,
    this.sleepDesaturationEvents = 0,
  });

  static List<DailyBloodOxygenAggregate> fromHistory(
    List<VitalsStreamResponse> history,
  ) {
    if (history.isEmpty) return [];

    final Map<String, List<VitalsStreamResponse>> grouped = {};
    for (var item in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    final List<DailyBloodOxygenAggregate> results = [];
    grouped.forEach((dateKey, items) {
      final date = DateTime.parse(dateKey);

      // Sort items by time for desaturation analysis
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      double total = 0;
      double min = 100;
      double max = 0;
      int below94Count = 0;
      int drops = 0;

      // Sleep analysis (10 PM to 7 AM)
      double sleepMin = 100;
      int sleepDrops = 0;

      final List<BloodOxygenStats> readings = [];

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final val = item.value;
        readings.add(BloodOxygenStats(timestamp: item.createdAt, value: val));

        total += val;
        if (val < min) min = val;
        if (val > max) max = val;
        if (val < 94) below94Count++;

        // Desaturation Event Logic: drop > 3% from previous reading if close in time
        if (i > 0) {
          final prevVal = items[i - 1].value;
          final timeDiff = item.createdAt
              .difference(items[i - 1].createdAt)
              .inMinutes;
          if (timeDiff <= 5 && (prevVal - val) >= 3) {
            drops++;
            if (_isSleepHour(item.createdAt)) {
              sleepDrops++;
            }
          }
        }

        // Sleep specific tracking
        if (_isSleepHour(item.createdAt)) {
          if (val < sleepMin) sleepMin = val;
        }
      }

      final avg = items.isNotEmpty ? total / items.length : 0.0;

      results.add(
        DailyBloodOxygenAggregate(
          date: date,
          avgSpO2: avg,
          minSpO2: min == 100 ? 0 : min,
          maxSpO2: max,
          timeBelow94Percent: (below94Count * 1.0)
              .toInt(), // Approximation: 1 reading = 1 min approx for now
          desaturationEvents: drops,
          readings: readings,
          lowestSleepSpO2: sleepMin == 100 ? 0 : sleepMin,
          sleepDesaturationEvents: sleepDrops,
        ),
      );
    });

    return results..sort((a, b) => a.date.compareTo(b.date));
  }

  static DailyBloodOxygenAggregate? fromRolling24Hours(
    List<VitalsStreamResponse> history,
  ) {
    if (history.isEmpty) return null;

    final items = List<VitalsStreamResponse>.from(history)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double total = 0;
    double min = 100;
    double max = 0;
    int below94Count = 0;
    int drops = 0;

    double sleepMin = 100;
    int sleepDrops = 0;

    final List<BloodOxygenStats> readings = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final val = item.value;
      readings.add(BloodOxygenStats(timestamp: item.createdAt, value: val));

      total += val;
      if (val < min) min = val;
      if (val > max) max = val;
      if (val < 94) below94Count++;

      if (i > 0) {
        final prevVal = items[i - 1].value;
        final timeDiff = item.createdAt
            .difference(items[i - 1].createdAt)
            .inMinutes;
        if (timeDiff <= 5 && (prevVal - val) >= 3) {
          drops++;
          if (_isSleepHour(item.createdAt)) {
            sleepDrops++;
          }
        }
      }

      if (_isSleepHour(item.createdAt)) {
        if (val < sleepMin) sleepMin = val;
      }
    }

    final avg = items.isNotEmpty ? total / items.length : 0.0;

    return DailyBloodOxygenAggregate(
      date: DateTime.now(),
      avgSpO2: avg,
      minSpO2: min == 100 ? 0 : min,
      maxSpO2: max,
      timeBelow94Percent: (below94Count * 1.0).toInt(),
      desaturationEvents: drops,
      readings: readings,
      lowestSleepSpO2: sleepMin == 100 ? 0 : sleepMin,
      sleepDesaturationEvents: sleepDrops,
    );
  }

  static bool _isSleepHour(DateTime time) {
    // 10 PM (22) to 7 AM (7)
    return time.hour >= 22 || time.hour < 7;
  }
}
