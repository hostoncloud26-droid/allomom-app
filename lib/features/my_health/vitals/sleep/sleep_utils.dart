import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/sleep/models/sleep_response_map_model.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// Holds the output parameters for sleep suggestions.
class SleepSuggestionResult {
  final TimeOfDay? bedTime;
  final TimeOfDay? wakeTime;
  final double? hours;

  const SleepSuggestionResult({this.bedTime, this.wakeTime, this.hours});
}

/// AlloConnect's two sleep helpers (`utils/sleep_utils.dart` and
/// `vitals/sleep/sleep_utils.dart`) in one place, reading Allomom's rows.
class SleepUtils {
  /// Every key a sleep session is stored under in Allomom: `sleep` is the
  /// manual log (value in hours), `sleep_data` the device / AlloConnect row
  /// (value in minutes), `sleep_hours` an older spelling.
  static const List<String> sleepVitalKeys = <String>[
    'sleep',
    'sleep_data',
    'sleep_hours',
  ];

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// A row's plain value in minutes: Allomom's `sleep` rows hold hours,
  /// `sleep_data` rows minutes.
  static int valueMinutes(double value, String unit) {
    if (value <= 0) return 0;
    if (unit.toLowerCase().contains('min') || value > 24) {
      return value.round();
    }
    return (value * 60).round();
  }

  /// The data map the entry sheet writes for a manual session, under key
  /// `sleep` with the value in hours, so Allomom's tile, Home and summary
  /// card keep reading it, while carrying AlloConnect's `sleep_data` window.
  static Map<String, dynamic> manualSessionData({
    required DateTime sleepTime,
    required DateTime awakeTime,
  }) {
    final minutes = math.max(0, awakeTime.difference(sleepTime).inMinutes);
    final hours = minutes / 60.0;
    // The sheet asks for no stages. Allomom's own log keeps a 25% deep share
    // as its default split, which the tile reads as "not measured".
    final deep = hours * 0.25;
    return <String, dynamic>{
      'source': 'manual',
      'sleep_time': sleepTime.toIso8601String(),
      'awake_time': awakeTime.toIso8601String(),
      'total_sleep_duration': minutes,
      'totalMinutes': minutes,
      'hours': hours,
      'deepSleep': deep,
      'lightSleep': hours - deep,
    };
  }

  /// Calculates total sleep minutes for a specific [day] by summing every
  /// session that ended on that day from SQLite records.
  static int calculateSleepMinutesForDay(
    List<Map<String, dynamic>> rawHistory,
    DateTime day,
  ) {
    int totalMinutes = 0;

    for (final record in rawHistory) {
      final rawData = record['data'];
      Map<String, dynamic>? parsedData;
      try {
        parsedData = rawData is String && rawData.isNotEmpty
            ? jsonDecode(rawData) as Map<String, dynamic>?
            : rawData as Map<String, dynamic>?;
      } catch (_) {
        parsedData = null;
      }

      final createdAtVal = record['createdAt'];
      final DateTime createdAtDate = createdAtVal is DateTime
          ? createdAtVal
          : (DateTime.tryParse(createdAtVal.toString()) ?? DateTime.now());

      DateTime? sessionSleep;
      DateTime? sessionWake;
      int sessionMinutes = 0;

      if (parsedData != null) {
        try {
          final model = SleepResponseMapModel.fromJson(parsedData);
          sessionSleep = model.sleepTime;
          sessionWake = model.awakeTime;
          sessionMinutes = model.totalSleepDuration;
          if (sessionMinutes <= 0 && sessionWake.isAfter(sessionSleep)) {
            sessionMinutes = sessionWake.difference(sessionSleep).inMinutes;
          }
          sessionMinutes = math.max(0, sessionMinutes);
        } catch (_) {
          sessionSleep = null;
          sessionWake = null;
          sessionMinutes = 0;
        }
      }

      if (sessionMinutes == 0) {
        final val = (record['value'] as num?)?.toDouble() ?? 0.0;
        sessionMinutes = valueMinutes(val, record['unit']?.toString() ?? '');
        sessionWake = createdAtDate;
        sessionSleep = sessionWake.subtract(Duration(minutes: sessionMinutes));
      }

      if (sessionMinutes <= 0) {
        continue;
      }

      final endedAt = sessionWake ?? createdAtDate;
      if (!isSameDay(endedAt, day)) {
        continue;
      }

      totalMinutes += sessionMinutes;
    }

    return totalMinutes;
  }

  /// Loads all sleep records for [userId] and calculates total sleep minutes
  /// for [date]. Defaults to today.
  static Future<int> getSleepMinutesForDay(
    String userId, [
    DateTime? date,
  ]) async {
    final uid = userId.trim();
    if (uid.isEmpty) return 0;
    try {
      final rawHistory = <Map<String, dynamic>>[];
      for (final key in sleepVitalKeys) {
        rawHistory.addAll(
          await VitalsSqLiteService().getVitalsHistory(uid, key),
        );
      }
      if (rawHistory.isEmpty) return 0;
      return calculateSleepMinutesForDay(rawHistory, date ?? DateTime.now());
    } catch (e) {
      debugPrint('Error getting sleep minutes for day: $e');
      return 0;
    }
  }

  /// Formats sleep minutes into string like '6h 49m' (same as sleep cycle tile).
  static String formatSleepDuration(int minutes) {
    if (minutes <= 0) return '—';
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    return '${h}h ${m}m';
  }

  /// A steps row's per-hour breakdown (`hourly_data` or `hourlyData`, a
  /// JSON-encoded list accepted too), as hour -> steps. Empty when the row
  /// has none -- Allomom's manual step entries carry no hourly split.
  static Map<int, int> _hourlySteps(VitalsStreamResponse? record) {
    final result = <int, int>{};
    dynamic raw = record?.data?['hourly_data'] ?? record?.data?['hourlyData'];
    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        raw = null;
      }
    }
    if (raw is! List) return result;
    for (final item in raw) {
      if (item is! Map) continue;
      final h = item['hour'];
      final s = item['steps'];
      final hour = h is num ? h.toInt() : int.tryParse('$h');
      final steps = s is num ? s.toInt() : int.tryParse('$s');
      if (hour != null && steps != null && hour >= 0 && hour < 24) {
        result[hour] = steps;
      }
    }
    return result;
  }

  /// Calculates suggested bedtime and wake-up times based on historical
  /// hourly step activity. Returns null if there is no step data recorded
  /// yesterday or today.
  static SleepSuggestionResult? calculateSuggestions(
    List<VitalsStreamResponse> stepsHistory,
  ) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final yesterdayMidnight = todayMidnight.subtract(const Duration(days: 1));

    VitalsStreamResponse? todayRecord;
    VitalsStreamResponse? yesterdayRecord;

    for (final record in stepsHistory) {
      final recordDate = record.createdAt;
      if (isSameDay(recordDate, todayMidnight)) {
        todayRecord = record;
      } else if (isSameDay(recordDate, yesterdayMidnight)) {
        yesterdayRecord = record;
      }
    }

    final yesterdayHourly = _hourlySteps(yesterdayRecord);
    final todayHourly = _hourlySteps(todayRecord);

    final hasYesterdaySteps = yesterdayHourly.values.any((s) => s > 0);
    final hasTodaySteps = todayHourly.values.any((s) => s > 0);

    if (!hasYesterdaySteps && !hasTodaySteps) {
      return null;
    }

    TimeOfDay? suggestedBedTime;
    DateTime? suggestedBedDateTime;

    // Bedtime: the last active hour yesterday, counting back from 23.
    int lastActiveYesterday = -1;
    for (int h = 23; h >= 0; h--) {
      if ((yesterdayHourly[h] ?? 0) > 0) {
        lastActiveYesterday = h;
        break;
      }
    }

    int firstQuietHourToday() {
      for (int h = 0; h <= 12; h++) {
        if ((todayHourly[h] ?? 0) == 0) return h;
      }
      return -1;
    }

    if (lastActiveYesterday == 23) {
      // Steps till midnight yesterday: bedtime is when today's steps stopped.
      final bedHourToday = firstQuietHourToday();
      if (bedHourToday != -1) {
        suggestedBedTime = TimeOfDay(hour: bedHourToday, minute: 0);
        suggestedBedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          bedHourToday,
          0,
        );
      } else {
        suggestedBedTime = const TimeOfDay(hour: 23, minute: 0);
        suggestedBedDateTime = DateTime(
          yesterdayMidnight.year,
          yesterdayMidnight.month,
          yesterdayMidnight.day,
          23,
          0,
        );
      }
    } else if (lastActiveYesterday != -1) {
      final bedHourYesterday = lastActiveYesterday + 1;
      suggestedBedTime = TimeOfDay(hour: bedHourYesterday, minute: 0);
      suggestedBedDateTime = DateTime(
        yesterdayMidnight.year,
        yesterdayMidnight.month,
        yesterdayMidnight.day,
        bedHourYesterday,
        0,
      );
    } else {
      final bedHourToday = firstQuietHourToday();
      if (bedHourToday != -1) {
        suggestedBedTime = TimeOfDay(hour: bedHourToday, minute: 0);
        suggestedBedDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          bedHourToday,
          0,
        );
      }
    }

    // Wake-up: the first visible steps this morning (hours 4 to 12), else
    // the first from 5 onwards.
    TimeOfDay? suggestedWakeTime;
    DateTime? suggestedWakeDateTime;
    int firstActiveMorningToday = -1;
    for (int h = 4; h <= 12; h++) {
      if ((todayHourly[h] ?? 0) >= 10) {
        firstActiveMorningToday = h;
        break;
      }
    }
    if (firstActiveMorningToday == -1) {
      for (int h = 5; h < 24; h++) {
        if ((todayHourly[h] ?? 0) >= 10) {
          firstActiveMorningToday = h;
          break;
        }
      }
    }
    if (firstActiveMorningToday != -1) {
      suggestedWakeTime = TimeOfDay(hour: firstActiveMorningToday, minute: 0);
      suggestedWakeDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        firstActiveMorningToday,
        0,
      );
    }

    double? suggestedHours;
    if (suggestedBedDateTime != null && suggestedWakeDateTime != null) {
      final diff = suggestedWakeDateTime.difference(suggestedBedDateTime);
      suggestedHours = diff.inMinutes / 60.0;
      if (suggestedHours < 0) {
        suggestedHours = null;
      }
    }

    return SleepSuggestionResult(
      bedTime: suggestedBedTime,
      wakeTime: suggestedWakeTime,
      hours: suggestedHours,
    );
  }
}
