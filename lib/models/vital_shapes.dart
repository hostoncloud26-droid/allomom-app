import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// AlloConnect's keys and shapes for the vitals stream. Allomom writes and
/// reads exactly these, so both apps share one meaning for every row.
///
/// | Reading            | key          | unit      | value              | data                                        |
/// |--------------------|--------------|-----------|--------------------|---------------------------------------------|
/// | breakfast / lunch / dinner / snacks | `food` | `kcal` | kcal     | `type` = `meal_type` = the meal, `details`, `total_calorie_intake` |
/// | tea / coffee / other drink | `food` | `kcal`    | kcal               | `type` = `tea`/`coffee`/`beverages`, `meal_type` = `beverages`, `details`, `total_calorie_intake` |
/// | water              | `water`      | `ml`      | ml                 | `type` = `water`, `details`                  |
/// | sleep              | `sleep_data` | `minutes` | minutes            | `source`, `sleep_time`, `awake_time`, `total_sleep_duration` |
/// | workout            | `workout`    | `kcal`    | kcal burned        | `workout_type`, `duration` (min), `details`  |
/// | BMI                | `bmi`        | `kg/m²`   | BMI, 1 decimal     | `height`, `weight`                           |
/// | stress             | `stress`     | `level`   | score              | —                                            |
class VitalShapes {
  VitalShapes._();

  static const String food = 'food';
  static const String water = 'water';
  static const String sleep = 'sleep_data';
  static const String workout = 'workout';
  static const String bmi = 'bmi';

  static const String breakfast = 'breakfast';
  static const String lunch = 'lunch';
  static const String dinner = 'dinner';
  static const String snacks = 'snacks';

  /// AlloConnect's `meal_type` for every drink.
  static const String beverages = 'beverages';

  /// The group Allomom's screens show drinks under (not a stored key).
  static const String drinks = 'drinks';

  /// One glass of water, in ml.
  static const int mlPerGlass = 250;

  /// The keys AlloConnect reads meals from: `food`, and its own older
  /// `break_fast` / `lunch` / `dinner` keys.
  static const List<String> foodReadKeys = [food, 'break_fast', lunch, dinner];

  /// The pelvic-floor session's `workout_type`.
  static const String pelvicWorkoutType = 'Pelvic Exercise';

  static const Set<String> _drinkTypes = {
    'tea',
    'coffee',
    beverages,
    'beverage',
    drinks,
  };

  /// Which part of the day's food a row is — `breakfast`, `lunch`, `dinner`,
  /// `snacks` or `drinks` — as AlloConnect tells them apart: a `food` row by
  /// its `meal_type` / `type`, or its older per-meal keys.
  static String? mealTypeOf(String key, Map<String, dynamic>? data) {
    switch (key.toLowerCase()) {
      case 'break_fast':
        return breakfast;
      case lunch:
      case dinner:
        return key.toLowerCase();
      case food:
        final mealType = data?['meal_type']?.toString().toLowerCase();
        final type = data?['type']?.toString().toLowerCase();
        for (final t in [mealType, type]) {
          if (t == null) continue;
          if (t == breakfast || t == lunch || t == dinner || t == snacks) {
            return t;
          }
          if (_drinkTypes.contains(t)) return drinks;
        }
        return null;
    }
    return null;
  }

  /// `data` for a meal or snack row, AlloConnect's fields first.
  static Map<String, dynamic> mealData(
    String mealType, {
    Map<String, dynamic> extra = const {},
  }) => {...extra, 'type': mealType, 'meal_type': mealType};

  /// A drink row's own kind — `tea`, `coffee` or `beverages`.
  static String drinkTypeOf(Map<String, dynamic>? data) {
    final t = data?['type']?.toString().toLowerCase();
    if (t == 'tea' || t == 'coffee') return t!;
    return beverages;
  }

  /// A drink row's display name — `Tea`, `Coffee` or `Other`.
  static String drinkNameOf(Map<String, dynamic>? data) =>
      switch (drinkTypeOf(data)) {
        'tea' => 'Tea',
        'coffee' => 'Coffee',
        _ => 'Other',
      };

  /// `data` for a drink row: `type` is the drink, `meal_type` `beverages`.
  static Map<String, dynamic> drinkData(
    String drinkType, {
    Map<String, dynamic> extra = const {},
  }) => {...extra, 'type': drinkType, 'meal_type': beverages};

  /// A water row (ml) in glasses.
  static double waterGlasses(num ml) => ml / mlPerGlass;

  /// A workout row's minutes, from `data['duration']`.
  static double workoutMinutes(Map<String, dynamic>? data) {
    final d = data?['duration'];
    if (d is num) return d.toDouble();
    return double.tryParse('${d ?? ''}') ?? 0;
  }

  /// Whether a workout row is the pelvic-floor session.
  static bool isPelvicWorkout(Map<String, dynamic>? data) =>
      data?['workout_type']?.toString() == pelvicWorkoutType;

  /// Adds what AlloConnect adds when it saves a `food` row: the day's
  /// `total_calorie_intake`, this row included. [excludeId] names a row being
  /// edited, left out of the day's sum so it is not counted twice. Every
  /// other reading is stored as given.
  static Future<Map<String, dynamic>?> completeData({
    required String key,
    required double value,
    required DateTime createdAt,
    Map<String, dynamic>? data,
    String? excludeId,
  }) async {
    if (key != food) return data;
    final d = <String, dynamic>{...?data};
    d['total_calorie_intake'] ??=
        await _dayKcal(createdAt, excludeId: excludeId) + value;
    return d;
  }

  /// The kcal of every food row on [day]'s calendar day.
  static Future<double> _dayKcal(DateTime day, {String? excludeId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    var total = 0.0;
    for (final key in foodReadKeys) {
      try {
        final rows = await VitalsSqLiteService()
            .getVitalsHistory('', key, fromDate: start, toDate: end);
        for (final row in rows) {
          if (excludeId != null && row['id'] == excludeId) continue;
          final v = row['value'];
          if (v is num) total += v.toDouble();
        }
      } catch (_) {
        // A total that misses a key is still a better guess than none.
      }
    }
    return total;
  }

  /// BMI from [weightKg] and [heightCm], to one decimal, or null when either
  /// is missing.
  static double? bmiOf(double? weightKg, double? heightCm) {
    if (weightKg == null || heightCm == null) return null;
    if (weightKg <= 0 || heightCm <= 0) return null;
    final m = heightCm > 3 ? heightCm / 100 : heightCm;
    return double.parse((weightKg / (m * m)).toStringAsFixed(1));
  }
}
