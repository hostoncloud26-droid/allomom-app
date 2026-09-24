// Ported from AlloConnect lib/features/health_section/vitals/steps/models/steps_models.dart
// (plus the parts of its StepsResponseMapModel it relies on).
//
// Data translation: AlloConnect writes one device row per day (with an
// `hourly_data` breakdown), so summing a day's rows equals the day total.
// Allomom's manual entries (`addStepsEntry`) each hold the day's running total
// and the controller treats the newest row as the day's steps, so here a day's
// total is its newest row. Its hourly breakdown comes from the row's
// `hourly_data` when present; otherwise each entry is placed in the hour it was
// logged (a rising series is read as running totals, as Allomom's StepTile does).
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';

class StepsStats {
  final DateTime timestamp;
  final int count;

  StepsStats({required this.timestamp, required this.count});

  // 1 step ~= 0.04 - 0.05 calories
  double get calories => count * 0.045;

  // 1 step ~= 0.76 meters
  double get distanceKm => (count * 0.762) / 1000.0;

  // Assuming 100 steps per minute for moderate activity
  int get activeMinutes => (count / 100).ceil();
}

class DailyStepsAggregate {
  final DateTime date;
  final int totalSteps;

  /// Metres, when the reading carried one (AlloConnect's `distance`).
  final int totalDistance;
  final int totalCalories;
  final List<StepsStats> hourlyBreakdown;

  /// The newest reading of the day, if any (used for editing).
  final VitalsStreamResponse? latest;

  DailyStepsAggregate({
    required this.date,
    required this.totalSteps,
    this.totalDistance = 0,
    this.totalCalories = 0,
    required this.hourlyBreakdown,
    this.latest,
  });

  double get calories =>
      totalCalories > 0 ? totalCalories.toDouble() : totalSteps * 0.045;
  double get distanceKm => totalDistance > 0
      ? totalDistance / 1000.0
      : (totalSteps * 0.762) / 1000.0;
  int get activeMinutes => (totalSteps / 100).ceil();

  String get peakHourLabel {
    if (hourlyBreakdown.isEmpty) return '--:--';
    var peak = hourlyBreakdown.first;
    for (final item in hourlyBreakdown) {
      if (item.count > peak.count) {
        peak = item;
      }
    }
    final hour = peak.timestamp.hour.toString().padLeft(2, '0');
    return '$hour:00';
  }

  static int? _asInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return num.tryParse(v)?.toInt();
    return null;
  }

  /// Steps held by a reading: `data.steps`, else its value.
  static int stepsOf(VitalsStreamResponse v) =>
      _asInt(v.data?['steps']) ?? v.value.toInt();

  /// A reading's own per-hour breakdown (`hourly_data` or `hourlyData`, list
  /// or JSON-encoded list). Null when it has none.
  static Map<int, int>? _deviceHourly(VitalsStreamResponse v) {
    dynamic raw = v.data?['hourly_data'] ?? v.data?['hourlyData'];
    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        raw = null;
      }
    }
    if (raw is! List || raw.isEmpty) return null;
    final hourly = <int, int>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final hour = _asInt(item['hour']);
      final steps = _asInt(item['steps']) ?? 0;
      if (hour != null && hour >= 0 && hour < 24) {
        hourly[hour] = (hourly[hour] ?? 0) + steps;
      }
    }
    return hourly;
  }

  static List<DailyStepsAggregate> fromHistory(
    List<VitalsStreamResponse> history,
  ) {
    if (history.isEmpty) return [];

    final Map<String, List<VitalsStreamResponse>> grouped = {};
    for (var item in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    final List<DailyStepsAggregate> results = [];
    grouped.forEach((dateKey, items) {
      final date = DateTime.parse(dateKey);
      // Oldest first.
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final latest = items.last;
      final total = stepsOf(latest);
      final totalDistance = _asInt(latest.data?['distance']) ?? 0;
      final totalCalories = _asInt(latest.data?['calories']) ?? 0;

      Map<int, int> hourly = _deviceHourly(latest) ?? {};
      if (hourly.isEmpty) {
        bool cumulative = true;
        for (int i = 1; i < items.length; i++) {
          if (stepsOf(items[i]) < stepsOf(items[i - 1])) cumulative = false;
        }
        if (!cumulative) {
          // Not running totals: only the newest reading counts.
          hourly[latest.createdAt.hour] = total;
        } else {
          int previous = 0;
          for (final r in items) {
            final s = stepsOf(r);
            final delta = s - previous;
            previous = s;
            if (delta > 0) {
              hourly[r.createdAt.hour] =
                  (hourly[r.createdAt.hour] ?? 0) + delta;
            }
          }
        }
      }

      final hourlyBreakdown = hourly.entries.map((e) {
        return StepsStats(
          timestamp: DateTime(date.year, date.month, date.day, e.key),
          count: e.value,
        );
      }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      results.add(
        DailyStepsAggregate(
          date: date,
          totalSteps: total,
          totalDistance: totalDistance,
          totalCalories: totalCalories,
          hourlyBreakdown: hourlyBreakdown,
          latest: latest,
        ),
      );
    });

    return results..sort((a, b) => a.date.compareTo(b.date));
  }
}
