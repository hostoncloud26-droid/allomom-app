/// Today's Planner's data, ported from AlloKonnect's `todays_plan_data.dart`:
/// the day's meals and activities (planned, logged or both) and last night's
/// sleep, read from Allomom's own vitals and reminders.
///
/// AlloKonnect's organization check-ins have no place in Allomom and are left
/// out.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/vitals/sleep/models/sleep_response_map_model.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_utils.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_day.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/local_notification/models/local_reminder.dart';
import 'package:allomom/local_notification/services/local_reminder_storage.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// When a meal was eaten, as the planner writes it into the meal's vital
/// data: `eat_time` and `complete_time`. Logs from before the planner have
/// neither and start at `createdAt`, lasting [defaultDuration].
class MealTimes {
  static const Duration defaultDuration = Duration(minutes: 30);

  static (DateTime, DateTime) of(
    DateTime createdAt,
    Map<String, dynamic>? data,
  ) {
    final start = DateTime.tryParse('${data?['eat_time'] ?? ''}') ?? createdAt;
    final end = DateTime.tryParse('${data?['complete_time'] ?? ''}');
    return (
      start,
      end != null && end.isAfter(start) ? end : start.add(defaultDuration),
    );
  }

  static Map<String, dynamic> toData(DateTime start, DateTime end) => {
    'eat_time': start.toIso8601String(),
    'complete_time': end.toIso8601String(),
  };
}

/// One night's sleep (or a nap) on the timeline.
class SleepSession {
  final DateTime start;
  final DateTime end;
  final int minutes;

  const SleepSession({
    required this.start,
    required this.end,
    required this.minutes,
  });
}

/// A meal on the day's timeline: planned, logged, or both.
class PlannedMeal {
  final String type; // breakfast | lunch | dinner
  final String title;
  final IconData icon;
  final Color color;

  /// Planned window in minutes of day, or null when the meal isn't planned.
  final int? planStart;
  final int? planEnd;
  final VitalsStreamResponse? logged;

  const PlannedMeal({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    this.planStart,
    this.planEnd,
    this.logged,
  });

  bool get isMeal => TodaysPlanData.mealTypes.contains(type);
  bool get isLogged => logged != null;
  bool get isPlanned => planStart != null && planEnd != null;

  /// The Today's Care meal this is, for the log sheet and its vital key.
  CareMeal? get careMeal =>
      CareMeal.values.firstWhereOrNull((m) => m.mealType == type);

  /// When the logged meal was eaten; older logs without times start at
  /// `createdAt` and last [MealTimes.defaultDuration].
  (DateTime, DateTime)? get eatenWindow =>
      logged == null ? null : MealTimes.of(logged!.createdAt, logged!.data);

  /// Minute of day the tile starts at: when it was eaten if logged, else the
  /// plan.
  int get minuteOfDay {
    final at = eatenWindow?.$1;
    return at == null ? planStart! : at.hour * 60 + at.minute;
  }

  /// Length of the tile: how long it took if logged, else the planned window.
  int get durationMinutes {
    final eaten = eatenWindow;
    if (eaten == null) return planEnd! - planStart!;
    return eaten.$2.difference(eaten.$1).inMinutes.clamp(1, 24 * 60).toInt();
  }

  String get details =>
      (logged?.data?['details'] ?? logged?.data?['items'] ?? '').toString();

  double? get calories => logged?.value;
}

class TodaysPlanData {
  /// The vital keys each meal is logged under: Today's Care's own key, then
  /// the older `break_fast` spelling.
  static const Map<String, List<String>> _mealKeys = {
    'breakfast': ['break_fast'],
    'lunch': ['lunch'],
    'dinner': ['dinner'],
  };

  static const List<String> mealTypes = ['breakfast', 'lunch', 'dinner'];

  /// Everything planned on each day by default, in day order. Only the meals:
  /// Today's Care's own items (movement, water, tablets, baby care) sit on
  /// the timeline beside them at their catalogue hours.
  static const List<String> planTypes = mealTypes;

  /// Today's Care's items that go on the timeline: all but its meals, which
  /// the planner shows as its own movable meal tiles.
  static List<CareItem> careItemsOnPlanner(CareDay day) =>
      day.items.where((i) => i.kind != CareActionKind.meal).toList();

  /// The tile key of a care item at [hour]: ids repeat across windows
  /// (water, feeds), so the hour tells them apart.
  static String careKey(CareItem item, int hour) => 'care-${item.id}@$hour';

  static String mealTitle(String type) => switch (type) {
    'breakfast' => 'Breakfast',
    'lunch' => 'Lunch',
    _ => 'Dinner',
  };

  static IconData mealIcon(String type) => switch (type) {
    'breakfast' => Icons.breakfast_dining_rounded,
    'lunch' => Icons.lunch_dining_rounded,
    _ => Icons.dinner_dining_rounded,
  };

  static Color mealColor(String type) => switch (type) {
    'breakfast' => const Color(0xFFFBBF24),
    'lunch' => const Color(0xFF10B981),
    _ => const Color(0xFF3B82F6),
  };

  /// The reminder whose time sets [type]'s default plan.
  static LocalReminderType reminderTypeFor(String type) => switch (type) {
    'breakfast' => LocalReminderType.breakfast,
    'lunch' => LocalReminderType.lunch,
    _ => LocalReminderType.dinner,
  };

  static const int defaultPlanMinutes = 30;

  /// Minute of day [type] starts at by default: its reminder time.
  static int defaultStart(String type, [List<LocalReminderConfig>? reminders]) {
    final reminderType = reminderTypeFor(type);
    final config =
        (reminders ?? LocalReminderStorage.loadAll()).firstWhereOrNull(
          (c) => c.type == reminderType,
        ) ??
        LocalReminderConfig(type: reminderType);
    return config.hour * 60 + config.minute;
  }

  // Plans are per day, stored in SharedPreferences as "<start>-<end>" minutes
  // of day under `todays_plan.v2.<yyyy-MM-dd>.<type>`. A day with nothing
  // stored falls back to the reminder time; [_removed] marks a default the
  // user took off that day.
  static const String _removed = 'none';

  static String _planPrefKey(DateTime day, String type) =>
      'todays_plan.v2.${DateFormat('yyyy-MM-dd').format(day)}.$type';

  /// Plans [type] on [day] from [start] to [end] (minutes of day), replacing
  /// any existing plan for that meal.
  static Future<void> savePlan(
    DateTime day,
    String type,
    int start,
    int end,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planPrefKey(day, type), '$start-$end');
  }

  /// Takes [type] off [day]'s plan, including its default.
  static Future<void> removePlan(DateTime day, String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planPrefKey(day, type), _removed);
  }

  /// Whether [day] has a plan saved for [type] (or has it removed), rather
  /// than falling back to the default.
  static bool _hasSavedPlan(
    SharedPreferences prefs,
    DateTime day,
    String type,
  ) => prefs.getString(_planPrefKey(day, type)) != null;

  static (int, int)? _readPlan(
    SharedPreferences prefs,
    DateTime day,
    String type,
    List<LocalReminderConfig> reminders,
  ) {
    final raw = prefs.getString(_planPrefKey(day, type));
    if (raw == _removed) return null;
    if (raw == null) {
      final start = defaultStart(type, reminders);
      return (start, (start + defaultPlanMinutes).clamp(start + 1, 24 * 60));
    }
    final parts = raw.split('-');
    if (parts.length != 2) return null;
    final start = int.tryParse(parts[0]);
    final end = int.tryParse(parts[1]);
    if (start == null || end == null || end <= start) return null;
    return (start, end);
  }

  /// Plans that follow the user's wake-up time when left at their defaults.
  static const List<String> _morningTypes = ['breakfast'];

  /// Sleep has to last this long, and end before [_latestWake], to count as
  /// the night's sleep rather than a nap.
  static const Duration _minNightSleep = Duration(hours: 3);
  static const int _latestWake = 14 * 60;

  /// Gap left after waking, and between morning plans.
  static const int _morningGap = 15;

  /// Minute of [day] the user woke up at, from the night's sleep in [sleep];
  /// null when there's none.
  static int? wakeMinute(DateTime day, List<SleepSession> sleep) {
    final dayStart = DateTime(day.year, day.month, day.day);
    int? wake;
    for (final s in sleep) {
      if (s.end.difference(s.start) < _minNightSleep) continue;
      final end = s.end.difference(dayStart).inMinutes;
      if (end <= 0 || end >= _latestWake) continue;
      if (wake == null || end > wake) wake = end;
    }
    return wake;
  }

  /// Moves default morning plans in [plans] that start before the user is up
  /// to follow [wake] in turn, keeping their length. Plans the user saved are
  /// left alone, but later plans still queue after them.
  static void _fitMorningToWake(
    Map<String, (int, int)?> plans,
    Set<String> saved,
    int wake,
  ) {
    int roundUp(int m) => (m + 14) ~/ 15 * 15;
    final morning = [
      for (final type in _morningTypes)
        if (plans[type] != null) type,
    ]..sort((a, b) => plans[a]!.$1.compareTo(plans[b]!.$1));

    var next = roundUp(wake + _morningGap);
    for (final type in morning) {
      var (start, end) = plans[type]!;
      if (!saved.contains(type) && start < next) {
        final length = end - start;
        start = next;
        end = (start + length).clamp(start + 1, 24 * 60).toInt();
        plans[type] = (start, end);
      }
      final after = roundUp(end + _morningGap);
      if (after > next) next = after;
    }
  }

  static String? get _userId {
    final id = MainController.instance.userId.trim();
    return id.isEmpty ? null : id;
  }

  /// Meals and activities for [day] that are planned (by default at their
  /// reminder times, with morning ones moved after the user wakes up) or
  /// logged; the rest are left out. [sleep] is loaded when not given.
  static Future<List<PlannedMeal>> loadMeals(
    DateTime day, {
    List<SleepSession>? sleep,
  }) async {
    final userId = _userId;
    final logged = <String, VitalsStreamResponse?>{};

    if (userId != null) {
      final from = DateTime(day.year, day.month, day.day);
      final to = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final service = VitalsSqLiteService();

      final vitals = <VitalsStreamResponse>[];
      for (final key in {'food', for (final k in _mealKeys.values) ...k}) {
        try {
          final rows = await service.getVitalsHistory(
            userId,
            key,
            fromDate: from,
            toDate: to,
          );
          vitals.addAll(rows.map(_vitalFromDbMap));
        } catch (e) {
          debugPrint('TodaysPlanData: failed to load $key: $e');
        }
      }
      vitals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (final entry in _mealKeys.entries) {
        logged[entry.key] = vitals.firstWhereOrNull(
          (v) =>
              entry.value.contains(v.key) ||
              (v.key == 'food' &&
                  (v.data?['type'] == entry.key ||
                      v.data?['meal_type'] == entry.key)),
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final reminders = LocalReminderStorage.loadAll();
    final plans = {
      for (final type in planTypes)
        type: _readPlan(prefs, day, type, reminders),
    };
    final wake = wakeMinute(day, sleep ?? await loadSleep(day));
    if (wake != null) {
      _fitMorningToWake(plans, {
        for (final type in planTypes)
          if (_hasSavedPlan(prefs, day, type)) type,
      }, wake);
    }

    final meals = <PlannedMeal>[];
    for (final type in planTypes) {
      final plan = plans[type];
      if (plan == null && logged[type] == null) continue;
      meals.add(
        PlannedMeal(
          type: type,
          title: mealTitle(type),
          icon: mealIcon(type),
          color: mealColor(type),
          planStart: plan?.$1,
          planEnd: plan?.$2,
          logged: logged[type],
        ),
      );
    }
    meals.sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    return meals;
  }

  /// Wearables split one night into several fragments; fragments closer than
  /// this are shown as a single sleep block.
  static const Duration sleepMergeGap = Duration(minutes: 60);

  /// Sleep sessions overlapping [day], merged when they overlap (the same night
  /// synced twice) or sit within [sleepMergeGap] of each other. Times are not
  /// clipped to the day.
  static Future<List<SleepSession>> loadSleep(DateTime day) async {
    final userId = _userId;
    if (userId == null) return [];

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = <Map<String, dynamic>>[];
    for (final key in SleepUtils.sleepVitalKeys) {
      try {
        rows.addAll(await VitalsSqLiteService().getVitalsHistory(userId, key));
      } catch (e) {
        debugPrint('TodaysPlanData: failed to load $key: $e');
      }
    }

    final sessions = <SleepSession>[];
    for (final row in rows) {
      final s = _parseSleep(row);
      if (s == null || !s.end.isAfter(s.start)) continue;
      if (!s.end.isAfter(dayStart) || !s.start.isBefore(dayEnd)) continue;
      sessions.add(s);
    }
    sessions.sort((a, b) => a.start.compareTo(b.start));

    final merged = <SleepSession>[];
    for (final s in sessions) {
      final last = merged.isEmpty ? null : merged.last;
      if (last != null && !s.start.isAfter(last.end.add(sleepMergeGap))) {
        final overlaps = s.start.isBefore(last.end);
        merged[merged.length - 1] = SleepSession(
          start: last.start,
          end: s.end.isAfter(last.end) ? s.end : last.end,
          // Separate fragments add up; an overlapping duplicate of the same
          // period must not be counted twice.
          minutes: overlaps
              ? (last.minutes > s.minutes ? last.minutes : s.minutes)
              : last.minutes + s.minutes,
        );
      } else {
        merged.add(s);
      }
    }
    return merged;
  }

  /// A sleep row as a session: its sleep / wake window when it has one, else
  /// its value (hours or minutes) ending at `createdAt`.
  static SleepSession? _parseSleep(Map<String, dynamic> row) {
    final data = _decodeData(row['data']);
    if (data != null) {
      try {
        final model = SleepResponseMapModel.fromJson(data);
        final minutes = model.totalSleepDuration > 0
            ? model.totalSleepDuration
            : model.awakeTime.difference(model.sleepTime).inMinutes;
        return SleepSession(
          start: model.sleepTime,
          end: model.awakeTime,
          minutes: minutes,
        );
      } catch (_) {
        // No window: fall back to the value.
      }
    }
    final created = _asDate(row['createdAt']);
    final minutes = SleepUtils.valueMinutes(
      (row['value'] as num?)?.toDouble() ?? 0,
      row['unit']?.toString() ?? '',
    );
    if (created == null || minutes <= 0) return null;
    return SleepSession(
      start: created.subtract(Duration(minutes: minutes)),
      end: created,
      minutes: minutes,
    );
  }

  static Map<String, dynamic>? _decodeData(Object? raw) {
    try {
      if (raw is String && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>?;
      }
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _asDate(Object? raw) =>
      raw is DateTime ? raw : DateTime.tryParse('${raw ?? ''}');

  static VitalsStreamResponse _vitalFromDbMap(Map<String, dynamic> map) {
    return VitalsStreamResponse(
      id: '${map['id'] ?? ''}',
      key: '${map['vital_key'] ?? map['key'] ?? ''}',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      unit: '${map['unit'] ?? ''}',
      createdAt: _asDate(map['createdAt']) ?? DateTime.now(),
      data: _decodeData(map['data']),
    );
  }
}
