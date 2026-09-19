import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// One day's food and drink, summed from the vitals stream.
///
/// Meal keys hold kcal in the value; `snacks` and `drinks` do too, and keep the
/// portion or cup count in `data['count']`. `water` is the odd one out — its
/// value *is* the number of glasses, logged as increments.
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

  factory NutritionSummary.empty(int dayCount) {
    final today = _startOfDay(DateTime.now());
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

const _breakfastKeys = ['breakfast', 'break_fast'];

/// Loads the last [dayCount] days (today last) of meals, snacks, drinks and water.
Future<NutritionSummary> loadNutritionSummary({int dayCount = 1}) async {
  final userId = MainController.instance.userId;
  if (userId.isEmpty) return NutritionSummary.empty(dayCount);

  final today = _startOfDay(DateTime.now());
  final from = today.subtract(Duration(days: dayCount - 1));
  final to = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

  // Accumulators, one slot per day in the window.
  final breakfast = List<double>.filled(dayCount, 0);
  final lunch = List<double>.filled(dayCount, 0);
  final dinner = List<double>.filled(dayCount, 0);
  final snacks = List<double>.filled(dayCount, 0);
  final drinks = List<double>.filled(dayCount, 0);
  final water = List<int>.filled(dayCount, 0);
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

  // ── Meals ──
  for (final entry in {
    'breakfast': _breakfastKeys,
    'lunch': ['lunch'],
    'dinner': ['dinner'],
  }.entries) {
    for (final key in entry.value) {
      for (final row in await rowsFor(key)) {
        final when = _dateOf(row);
        final slot = when == null ? null : slotOf(when);
        if (slot == null) continue;

        final kcal = _numOf(row['value']) ?? 0;
        switch (entry.key) {
          case 'breakfast':
            breakfast[slot] += kcal;
          case 'lunch':
            lunch[slot] += kcal;
          default:
            dinner[slot] += kcal;
        }

        // Keep the newest note from today, which is what the card shows.
        if (slot == dayCount - 1) {
          final data = _dataOf(row);
          final note = (data['items'] ?? data['details'])?.toString().trim();
          final seen = latestNoteAt[entry.key];
          if (note != null && note.isNotEmpty && (seen == null || when!.isAfter(seen))) {
            mealNotes[entry.key] = note;
            latestNoteAt[entry.key] = when!;
          }
        }
      }
    }
  }

  // ── Snacks and drinks: kcal in the value, units in data['count'] ──
  for (final row in await rowsFor('snacks')) {
    final when = _dateOf(row);
    final slot = when == null ? null : slotOf(when);
    if (slot == null) continue;
    snacks[slot] += _numOf(row['value']) ?? 0;
    snackCount[slot] += _countOf(row);
  }

  for (final row in await rowsFor('drinks')) {
    final when = _dateOf(row);
    final slot = when == null ? null : slotOf(when);
    if (slot == null) continue;
    final units = _countOf(row);
    drinks[slot] += _numOf(row['value']) ?? 0;
    drinkCount[slot] += units;

    if (slot == dayCount - 1) {
      final name = _dataOf(row)['drink']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        drinkCounts[name] = (drinkCounts[name] ?? 0) + units;
      }
    }
  }

  // ── Water: increments, so a sum is the running total ──
  for (final row in await rowsFor('water')) {
    final when = _dateOf(row);
    final slot = when == null ? null : slotOf(when);
    if (slot == null) continue;
    water[slot] += (_numOf(row['value']) ?? 0).round();
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
        waterGlasses: water[i] < 0 ? 0 : water[i],
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
