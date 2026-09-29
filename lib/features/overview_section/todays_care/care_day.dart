/// One day of Today's Care: the items each window asks for, and how far she
/// has got with each — shared by Home's [TodocareSection] and Today's
/// Planner, so both read and write the same rows.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_custom_activity.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_count_sheet.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';
import 'package:allomom/services/health_vital_sync_service.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// A window of the day and what it asks for.
class CareGroup {
  const CareGroup({required this.part, required this.items});

  final CareDayPart part;
  final List<CareItem> items;
}

class CareDay {
  CareDay({
    required this.part,
    required this.groups,
    required this.hours,
    required this.customById,
    required this.completedActions,
    required this.todocareRowIds,
    required this.countsToday,
    required this.mealsLogged,
    required this.navigateDone,
  }) : items = [for (final group in groups) ...group.items];

  static final CareDay empty = CareDay(
    part: CareDayPart.at(),
    groups: const [],
    hours: const {},
    customById: const {},
    completedActions: <String>{},
    todocareRowIds: const {},
    countsToday: const {},
    mealsLogged: const {},
    navigateDone: const {},
  );

  /// The window the clock was in when this was loaded.
  final CareDayPart part;

  /// Each window asked for and its items.
  final List<CareGroup> groups;

  /// Every item across [groups].
  final List<CareItem> items;

  /// The clock hour each item sits at on the timeline.
  final Map<CareItem, int> hours;

  /// Her own activities, by the id their [CareItem] carries.
  final Map<String, CareCustomActivity> customById;

  /// `todocare` action values already ticked off today. Mutable, so a tick
  /// can show before its write lands.
  final Set<String> completedActions;

  /// Today's `todocare` rows behind each ticked action, so un-ticking can
  /// delete exactly them.
  final Map<String, List<String>> todocareRowIds;

  /// Count-item vital key -> amount logged today (glasses, cups, portions).
  final Map<String, int> countsToday;

  /// Meal vital keys logged today.
  final Set<String> mealsLogged;

  /// `doneVitalKey`s that already have a row today.
  final Set<String> navigateDone;

  // ─── LOADING ────────────────────────────────────────────────

  /// Today's items for [parts], each at its hour, with what's done so far.
  static Future<CareDay> load(List<CareDayPart> parts) async {
    final session = MainController.instance;
    final customs = await CareCustomActivityStore.load();
    final hours = <CareItem, int>{};
    final customById = <String, CareCustomActivity>{};

    final babyAgeDays = WeeklyBabyTalk.babyAgeDays();
    final groups = <CareGroup>[];
    for (final window in parts) {
      final items = <CareItem>[];
      for (final item in careItemsFor(
        part: window,
        isPregnant: session.isPregnant,
        pregnancyDay: session.currentPregnancyDay,
        babyAgeDays: babyAgeDays,
      )) {
        items.add(item);
        hours[item] = careHourFor(item.id, window);
      }
      // Her own activities join the window their hour falls in, so progress,
      // tick-offs and `day_part` treat them like any other item.
      for (final custom in customs) {
        if (partAtHour(custom.hour) != window) continue;
        final item = custom.toCareItem();
        items.add(item);
        hours[item] = custom.hour;
        customById[item.id] = custom;
      }
      groups.add(CareGroup(part: window, items: items));
    }
    final items = [for (final group in groups) ...group.items];

    final ticks = await _loadTodocareTicks();
    return CareDay(
      part: CareDayPart.at(),
      groups: groups,
      hours: hours,
      customById: customById,
      completedActions: ticks.actions,
      todocareRowIds: ticks.rowIds,
      countsToday: await _loadCountsToday(items),
      mealsLogged: await _loadMealsLoggedToday(items),
      navigateDone: await _loadNavigateDone(items),
    );
  }

  /// Today's tick-offs, read from the `todocare` rows in the vitals stream.
  ///
  /// The vitals table is the only record: a tick is a row, an un-tick deletes
  /// it, and both reach the server through the `vitals` sync. Each row is
  /// indexed under every value it carries, since older builds wrote the action
  /// to different fields.
  static Future<({Set<String> actions, Map<String, List<String>> rowIds})>
  _loadTodocareTicks() async {
    final actions = <String>{};
    final rowIds = <String, List<String>>{};

    final userId = MainController.instance.userId;
    if (userId.isEmpty) return (actions: actions, rowIds: rowIds);

    try {
      final rows = await VitalsSqLiteService().getVitalsHistory(
        userId,
        'todocare',
        fromDate: _startOfToday(),
      );

      for (final row in rows) {
        final id = row['id']?.toString();
        final values = <String>{
          ?row['unit']?.toString().toLowerCase().trim(),
          for (final value in _decodeData(row).values)
            ?value?.toString().toLowerCase().trim(),
        }..removeWhere((v) => v.isEmpty);

        for (final value in values) {
          actions.add(value);
          if (id != null) rowIds.putIfAbsent(value, () => []).add(id);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CareDay] Could not read todocare vitals: $e');
    }

    return (actions: actions, rowIds: rowIds);
  }

  /// Sums today's rows for each count item. Rows hold increments, so a sum is
  /// the running total for the day.
  ///
  /// Calorie-backed keys (`snacks`, `drinks`) store kcal in the value, so the
  /// count is read from `data['count']`. Rows written elsewhere in the app
  /// (My Health's snack dialog) carry no count, so they count as one unit.
  static Future<Map<String, int>> _loadCountsToday(List<CareItem> items) async {
    final counts = <String, int>{};
    final userId = MainController.instance.userId;
    if (userId.isEmpty) return counts;

    final countItems = items
        .where((i) => i.kind == CareActionKind.count && i.countVitalKey != null)
        .toList();

    for (final item in countItems) {
      final key = item.countVitalKey!;
      if (counts.containsKey(key)) continue;

      try {
        final rows = await VitalsSqLiteService().getVitalsHistory(
          userId,
          key,
          fromDate: _startOfToday(),
        );

        // Summed before rounding: water can arrive in part-glasses (a 100 ml
        // entry is 0.4), and rounding each row would drop them.
        var total = 0.0;
        for (final row in rows) {
          if (item.caloriesPerUnit == null) {
            total += (row['value'] as num?)?.toDouble() ?? 0;
          } else {
            final recorded = _decodeData(row)['count'];
            final parsed = recorded is num
                ? recorded.round()
                : int.tryParse(recorded?.toString() ?? '');
            total += parsed ?? 1;
          }
        }
        final rounded = total.round();
        counts[key] = rounded < 0 ? 0 : rounded;
      } catch (e) {
        debugPrint('⚠️ [CareDay] Could not read "$key" vitals: $e');
      }
    }

    return counts;
  }

  static Future<Set<String>> _loadMealsLoggedToday(List<CareItem> items) async {
    final logged = <String>{};
    final userId = MainController.instance.userId;
    if (userId.isEmpty) return logged;

    final meals = items.map((i) => i.meal).whereType<CareMeal>().toSet();
    for (final meal in meals) {
      final keys = <String>[meal.vitalKey, ?meal.legacyVitalKey];
      for (final key in keys) {
        try {
          final rows = await VitalsSqLiteService().getVitalsHistory(
            userId,
            key,
            fromDate: _startOfToday(),
          );
          if (rows.isNotEmpty) {
            logged.add(meal.vitalKey);
            break;
          }
        } catch (e) {
          debugPrint('⚠️ [CareDay] Could not read "$key" vitals: $e');
        }
      }
    }

    return logged;
  }

  /// Marks a navigate item done when the screen it opens has already written
  /// its vital today (e.g. kicks counted in the kick counter).
  static Future<Set<String>> _loadNavigateDone(List<CareItem> items) async {
    final done = <String>{};
    final userId = MainController.instance.userId;
    if (userId.isEmpty) return done;

    final keys = items.map((i) => i.doneVitalKey).whereType<String>().toSet();
    for (final key in keys) {
      try {
        final rows = await VitalsSqLiteService().getVitalsHistory(
          userId,
          key,
          fromDate: _startOfToday(),
        );
        if (rows.isNotEmpty) done.add(key);
        // Also by window, for items that recur through the day (feeds).
        for (final row in rows) {
          final raw = row['createdAt'];
          final at = raw is DateTime
              ? raw
              : DateTime.tryParse(raw?.toString() ?? '');
          if (at != null) done.add('$key@${CareDayPart.at(at.toLocal()).name}');
        }
      } catch (e) {
        debugPrint('⚠️ [CareDay] Could not read "$key" vitals: $e');
      }
    }

    return done;
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The window [hour] falls in today.
  static CareDayPart partAtHour(int hour) {
    final now = DateTime.now();
    return CareDayPart.at(DateTime(now.year, now.month, now.day, hour));
  }

  static Map<String, dynamic> _decodeData(Map<String, dynamic> row) {
    final raw = row['data'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Not JSON — nothing to pull out of it.
      }
    }
    return const {};
  }

  // ─── STATE OF AN ITEM ───────────────────────────────────────

  bool isDone(CareItem item) => switch (item.kind) {
    CareActionKind.meal => mealsLogged.contains(item.meal!.vitalKey),
    CareActionKind.count =>
      countFor(item) > 0 &&
          (item.dailyTarget == null || countFor(item) >= item.dailyTarget!),
    CareActionKind.checkoff => completedActions.contains(
      item.actionValue?.toLowerCase().trim(),
    ),
    CareActionKind.navigate => navigateDone.contains(
      item.donePerPart
          ? '${item.doneVitalKey}@${partOf(item).name}'
          : item.doneVitalKey,
    ),
  };

  int countFor(CareItem item) => countsToday[item.countVitalKey] ?? 0;

  int get doneCount => items.where(isDone).length;

  /// The window [item] belongs to, which is what its `day_part` records — on
  /// the checklist page that is not always the window the clock is in.
  CareDayPart partOf(CareItem item) {
    for (final group in groups) {
      if (group.items.contains(item)) return group.part;
    }
    return part;
  }

  /// The hour [item] sits at.
  int hourOf(CareItem item) => hours[item] ?? partOf(item).startHour;

  /// Trailing status line for count items, e.g. "4 of 10 glasses today".
  String? progressLabel(CareItem item) {
    if (item.kind != CareActionKind.count) return null;
    final logged = countFor(item);
    if (logged == 0) return null;
    final unit = logged == 1 ? item.unitSingular : item.unitPlural;
    final target = item.dailyTarget;
    return target == null
        ? '$logged $unit today'
        : '$logged of $target $unit today';
  }
}

/// What tapping a care item does, wherever it's shown: log a meal or a
/// count, tick it off (or undo), or open the screen that records it. The
/// caller reloads its [CareDay] once the returned future completes.
class CareItemActions {
  /// Runs [item]'s action. [onTicked] is called right after a check-off's
  /// optimistic change to [day], so the tick shows before its write lands.
  static Future<void> run(
    BuildContext context,
    CareItem item,
    CareDay day, {
    VoidCallback? onTicked,
  }) async {
    switch (item.kind) {
      case CareActionKind.meal:
        await _logMeal(context, item, day);
      case CareActionKind.count:
        await _logCount(context, item, day);
      case CareActionKind.checkoff:
        await _toggleCheckoff(context, item, day, onTicked);
      case CareActionKind.navigate:
        await _navigate(context, item);
    }
  }

  static Future<void> _logMeal(
    BuildContext context,
    CareItem item,
    CareDay day,
  ) async {
    final meal = item.meal!;
    final log = await CareMealSheet.show(
      context,
      meal: meal,
      color: item.color,
      icon: item.icon,
      suggestion: item.subtitle,
    );
    if (log == null || !context.mounted) return;

    HapticFeedback.mediumImpact();
    try {
      await HealthVitalsController.instance.addVitalEntry(
        key: meal.vitalKey,
        value: log.calories,
        unit: 'kcal',
        createdAt: DateTime.now(),
        userId: _userIdOrNull(),
        data: {
          'items': log.details,
          'details': log.details,
          'meal': meal.label,
          'meal_type': meal.vitalKey,
          'type': meal.vitalKey,
          'day_part': day.partOf(item).name,
        },
      );
      speak(NarrationKeys.pgConfMealSaved, force: true);
      if (context.mounted) {
        showLogged(
          context,
          '${meal.label} logged · ${log.calories.round()} kcal',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [CareItemActions] Error logging ${meal.vitalKey}: $e');
      if (context.mounted) {
        showError(context, 'Could not log ${meal.label.toLowerCase()}');
      }
    }
  }

  static Future<void> _logCount(
    BuildContext context,
    CareItem item,
    CareDay day,
  ) async {
    final amount = await CareCountSheet.show(
      context,
      title: item.title,
      unitLabel: item.unitPlural,
      unitLabelSingular: item.unitSingular,
      icon: item.icon,
      color: item.color,
      loggedToday: day.countFor(item),
      target: item.dailyTarget,
      presets: item.presets,
      subtitle: item.subtitle,
      // Water is the only count with a recorded line; the rest open silent.
      narrationKey: item.countVitalKey == 'water'
          ? NarrationKeys.pgNutritionWater
          : null,
    );
    if (amount == null || !context.mounted) return;

    HapticFeedback.mediumImpact();
    final unit = amount == 1 ? item.unitSingular : item.unitPlural;
    if (await addCount(item, day, amount)) {
      if (item.countVitalKey == 'water') {
        speak(NarrationKeys.pgConfWaterAdded, force: true);
      }
      if (context.mounted) showLogged(context, 'Logged $amount $unit');
    } else if (context.mounted) {
      showError(context, 'Could not log ${item.title.toLowerCase()}');
    }
  }

  /// Adds [amount] to a count item's total today. Returns whether it saved.
  static Future<bool> addCount(CareItem item, CareDay day, int amount) async {
    final key = item.countVitalKey;
    if (item.kind != CareActionKind.count || key == null || amount <= 0) {
      return false;
    }
    final unit = amount == 1 ? item.unitSingular : item.unitPlural;
    final caloriesPerUnit = item.caloriesPerUnit;
    try {
      final saved = await HealthVitalsController.instance.addVitalEntry(
        key: key,
        value: caloriesPerUnit == null
            ? amount.toDouble()
            : (amount * caloriesPerUnit).toDouble(),
        unit: caloriesPerUnit == null ? item.unitPlural : 'kcal',
        createdAt: DateTime.now(),
        userId: _userIdOrNull(),
        data: {
          'details': '$amount $unit',
          'type': key,
          'count': amount,
          'count_unit': item.unitPlural,
          'day_part': day.partOf(item).name,
        },
      );
      return saved != null;
    } catch (e) {
      debugPrint('⚠️ [CareItemActions] Error logging $key: $e');
      return false;
    }
  }

  /// Ticks an item off, or undoes it.
  ///
  /// A tick writes a `todocare` row to the vitals stream; undoing it deletes
  /// today's rows for that action. Either way the vitals sync carries it to the
  /// server, so a tick and an undo look the same on every device.
  static Future<void> _toggleCheckoff(
    BuildContext context,
    CareItem item,
    CareDay day,
    VoidCallback? onTicked,
  ) async {
    final action = item.actionValue;
    if (action == null) return;
    final wasDone = day.completedActions.contains(action.toLowerCase().trim());

    HapticFeedback.selectionClick();
    final saved = await setCheckoff(item, day, !wasDone, onTicked: onTicked);
    if (!saved && context.mounted) {
      showError(
        context,
        wasDone
            ? 'Could not undo ${item.title.toLowerCase()}'
            : 'Could not save ${item.title.toLowerCase()}',
      );
    }
  }

  /// Ticks a check-off item off ([done]) or undoes it. [day] changes first,
  /// and [onTicked] is called, so the tick shows before its write lands.
  /// Returns whether it saved.
  static Future<bool> setCheckoff(
    CareItem item,
    CareDay day,
    bool done, {
    VoidCallback? onTicked,
  }) async {
    final action = item.actionValue;
    if (item.kind != CareActionKind.checkoff || action == null) return false;

    final normalized = action.toLowerCase().trim();
    if (day.completedActions.contains(normalized) == done) return true;
    if (done) {
      day.completedActions.add(normalized);
    } else {
      day.completedActions.remove(normalized);
    }
    onTicked?.call();

    if (!done) {
      try {
        for (final id in day.todocareRowIds[normalized] ?? const <String>[]) {
          await VitalsSqLiteService().deleteVital(id);
        }
        await HealthVitalSyncService.instance.syncUnsyncedVitals();
        return true;
      } catch (e) {
        debugPrint('⚠️ [CareItemActions] Error undoing todocare: $e');
        return false;
      }
    }

    // addVitalEntry saves the row with synced = 0 and starts the vitals sync.
    final session = MainController.instance;
    try {
      final saved = await HealthVitalsController.instance.addVitalEntry(
        key: 'todocare',
        value: 1.0,
        unit: action,
        createdAt: DateTime.now(),
        userId: _userIdOrNull(),
        data: {
          'value': action,
          'action': action,
          'todocare': action,
          'details': action,
          'title': item.title,
          'day_part': day.partOf(item).name,
          'pregnancy_day': session.isPregnant ? session.currentPregnancyDay : 0,
          'is_pregnant': session.isPregnant,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return saved != null;
    } catch (e) {
      debugPrint('⚠️ [CareItemActions] Error logging todocare: $e');
      return false;
    }
  }

  static Future<void> _navigate(BuildContext context, CareItem item) async {
    switch (item.destination) {
      case CareDestination.kickCounter:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const KickCounterPage()));
      case CareDestination.feedingTracker:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FeedingTrackerPage()));
      case null:
        return;
    }
  }

  static String? _userIdOrNull() {
    final id = MainController.instance.userId.trim();
    return id.isEmpty ? null : id;
  }

  static void showLogged(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
