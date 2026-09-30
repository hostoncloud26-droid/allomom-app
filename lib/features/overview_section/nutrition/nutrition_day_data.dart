import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/models/vital_shapes.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// One day's food and drink, summed from the vitals stream.
///
/// Meals, snacks and drinks are AlloConnect's `food` rows — kcal in the value,
/// which one in `data['meal_type']` — or rows under Allomom's older per-meal
/// keys; snacks and drinks keep the portion or cup count in `data['count']`.
/// `water` rows are increments, in ml (AlloConnect) or glasses (older rows).
class NutritionDay {
  final DateTime date;
  final double breakfastKcal;
  final double lunchKcal;
  final double dinnerKcal;
  final double snacksKcal;
  final double drinksKcal;
  final int waterGlasses;
  final int snackCount;
  final int drinkCount;

  const NutritionDay({
    required this.date,
    this.breakfastKcal = 0,
    this.lunchKcal = 0,
    this.dinnerKcal = 0,
    this.snacksKcal = 0,
    this.drinksKcal = 0,
    this.waterGlasses = 0,
    this.snackCount = 0,
    this.drinkCount = 0,
  });

  double get totalKcal =>
      breakfastKcal + lunchKcal + dinnerKcal + snacksKcal + drinksKcal;

  bool get isEmpty => totalKcal <= 0 && waterGlasses <= 0;
}

/// Everything the nutrition section needs for one stretch of days.
class NutritionSummary {
  /// Oldest first, one entry per calendar day, including days with nothing.
  final List<NutritionDay> days;

  /// What she typed when logging today's meals, keyed by meal ('breakfast', …).
  final Map<String, String> todayMealNotes;

  /// Today's cups per named drink ('Tea', 'Coffee', 'Other').
  final Map<String, int> todayDrinkCounts;

  const NutritionSummary({
    required this.days,
    this.todayMealNotes = const {},
    this.todayDrinkCounts = const {},
  });

  /// [endDate] is the last day of the window; today when omitted.
  factory NutritionSummary.empty(int dayCount, {DateTime? endDate}) {
    final today = _startOfDay(endDate ?? DateTime.now());
    return NutritionSummary(
      days: List.generate(
        dayCount,
        (i) => NutritionDay(
          date: today.subtract(Duration(days: dayCount - 1 - i)),
        ),
      ),
    );
  }

  NutritionDay get today => days.last;

  double get totalKcal => days.fold(0.0, (sum, d) => sum + d.totalKcal);
  int get totalWaterGlasses => days.fold(0, (sum, d) => sum + d.waterGlasses);
}

/// A glass of water in millilitres, so glasses and the ml the cards show stay
/// the same number underneath.
const int kGlassMl = 250;

/// Daily water goal, which rises through pregnancy the way Today's Care sets it.
int waterGoalGlasses() {
  final session = MainController.instance;
  if (!session.isPregnant) return 8;
  final week = session.currentGestationalWeek;
  if (week <= 13) return 10;
  if (week <= 27) return 11;
  return 12;
}

/// Recommended daily energy intake in pregnancy, matching the calorie tracker.
const double kDailyCalorieGoal = 2200;

/// Loads the last [dayCount] days (today last) of meals, snacks, drinks and water.
///
/// [endDate] moves the window so it ends on that day instead of today; the
/// "today" notes and drink counts then describe that day.
Future<NutritionSummary> loadNutritionSummary({
  int dayCount = 1,
  DateTime? endDate,
}) async {
  final userId = MainController.instance.userId;
  if (userId.isEmpty) {
    return NutritionSummary.empty(dayCount, endDate: endDate);
  }

  final today = _startOfDay(endDate ?? DateTime.now());
  final from = today.subtract(Duration(days: dayCount - 1));
  final to = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

  // Accumulators, one slot per day in the window.
  final breakfast = List<double>.filled(dayCount, 0);
  final lunch = List<double>.filled(dayCount, 0);
  final dinner = List<double>.filled(dayCount, 0);
  final snacks = List<double>.filled(dayCount, 0);
  final drinks = List<double>.filled(dayCount, 0);
  // Doubles until the end: water can be logged in part-glasses.
  final water = List<double>.filled(dayCount, 0);
  final snackCount = List<int>.filled(dayCount, 0);
  final drinkCount = List<int>.filled(dayCount, 0);

  final mealNotes = <String, String>{};
  final drinkCounts = <String, int>{};
  final latestNoteAt = <String, DateTime>{};

  Future<List<Map<String, dynamic>>> rowsFor(String key) async {
    try {
      return await VitalsSqLiteService()
          .getVitalsHistory(userId, key, fromDate: from, toDate: to);
    } catch (e) {
      debugPrint('⚠️ [nutrition] Could not read "$key" vitals: $e');
      return const [];
    }
  }

  int? slotOf(DateTime when) {
    final index = dayCount - 1 - today.difference(_startOfDay(when)).inDays;
    return (index >= 0 && index < dayCount) ? index : null;
  }

  // ── Meals, snacks and drinks: `food` rows, or the older per-meal keys ──
  final foodRows = <Map<String, dynamic>>[
    for (final key in VitalShapes.foodReadKeys) ...await rowsFor(key),
  ];
  for (final row in foodRows) {
    final when = _dateOf(row);
    final slot = when == null ? null : slotOf(when);
    if (slot == null) continue;

    final data = _dataOf(row);
    final meal = VitalShapes.mealTypeOf(row['key']?.toString() ?? '', data);
    if (meal == null) continue;
    final kcal = _numOf(row['value']) ?? 0;

    switch (meal) {
      case VitalShapes.snacks:
        snacks[slot] += kcal;
        snackCount[slot] += _countOf(row);
        continue;
      case VitalShapes.drinks:
        final units = _countOf(row);
        drinks[slot] += kcal;
        drinkCount[slot] += units;
        if (slot == dayCount - 1) {
          final name = VitalShapes.drinkNameOf(data);
          drinkCounts[name] = (drinkCounts[name] ?? 0) + units;
        }
        continue;
      case VitalShapes.breakfast:
        breakfast[slot] += kcal;
      case VitalShapes.lunch:
        lunch[slot] += kcal;
      default:
        dinner[slot] += kcal;
    }

    // Keep the newest note from today, which is what the card shows.
    if (slot == dayCount - 1) {
      final note = (data['items'] ?? data['details'])?.toString().trim();
      final seen = latestNoteAt[meal];
      if (note != null && note.isNotEmpty && (seen == null || when!.isAfter(seen))) {
        mealNotes[meal] = note;
        latestNoteAt[meal] = when!;
      }
    }
  }

  // ── Water: increments, so a sum is the running total ──
  for (final row in await rowsFor('water')) {
    final when = _dateOf(row);
    final slot = when == null ? null : slotOf(when);
    if (slot == null) continue;
    water[slot] += VitalShapes.waterGlasses(_numOf(row['value']) ?? 0);
  }

  return NutritionSummary(
    days: List.generate(dayCount, (i) {
      return NutritionDay(
        date: from.add(Duration(days: i)),
        breakfastKcal: breakfast[i],
        lunchKcal: lunch[i],
        dinnerKcal: dinner[i],
        snacksKcal: snacks[i],
        drinksKcal: drinks[i],
        waterGlasses: water[i] < 0 ? 0 : water[i].round(),
        snackCount: snackCount[i] < 0 ? 0 : snackCount[i],
        drinkCount: drinkCount[i] < 0 ? 0 : drinkCount[i],
      );
    }),
    todayMealNotes: mealNotes,
    todayDrinkCounts: drinkCounts,
  );
}

DateTime _startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime? _dateOf(Map<String, dynamic> row) {
  final raw = row['createdAt'];
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

double? _numOf(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '');
}

/// Rows written outside Today's Care carry no count, so they stand for one unit.
int _countOf(Map<String, dynamic> row) {
  final recorded = _dataOf(row)['count'];
  if (recorded is num) return recorded.round();
  return int.tryParse(recorded?.toString() ?? '') ?? 1;
}

Map<String, dynamic> _dataOf(Map<String, dynamic> row) {
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
