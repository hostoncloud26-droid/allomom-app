import 'package:flutter/material.dart';

/// The part of the day Today's Care is currently showing.
///
/// Boundaries follow the meal reminder defaults in
/// `LocalReminderType.defaultTime` (breakfast 08:00, lunch 13:00,
/// dinner 19:30) widened into windows, so the section and the notifications
/// never disagree about which meal is "now".
enum CareDayPart {
  /// 05:00 – 10:59 · breakfast
  morning,

  /// 11:00 – 12:29 · mid-morning snack
  midMorning,

  /// 12:30 – 16:29 · lunch
  afternoon,

  /// 16:30 – 18:59 · evening tea / snack
  evening,

  /// 19:00 – 21:59 · dinner
  night,

  /// 22:00 – 04:59 · wind down
  lateNight;

  /// Resolves the day part for [time] (defaults to now).
  static CareDayPart at([DateTime? time]) {
    final now = time ?? DateTime.now();
    final minutes = now.hour * 60 + now.minute;

    if (minutes >= 5 * 60 && minutes < 11 * 60) return CareDayPart.morning;
    if (minutes >= 11 * 60 && minutes < 12 * 60 + 30) {
      return CareDayPart.midMorning;
    }
    if (minutes >= 12 * 60 + 30 && minutes < 16 * 60 + 30) {
      return CareDayPart.afternoon;
    }
    if (minutes >= 16 * 60 + 30 && minutes < 19 * 60) {
      return CareDayPart.evening;
    }
    if (minutes >= 19 * 60 && minutes < 22 * 60) return CareDayPart.night;
    return CareDayPart.lateNight;
  }

  /// Short name of the window, e.g. "Morning".
  String get label => switch (this) {
    CareDayPart.morning => 'Morning',
    CareDayPart.midMorning => 'Mid-morning',
    CareDayPart.afternoon => 'Afternoon',
    CareDayPart.evening => 'Evening',
    CareDayPart.night => 'Night',
    CareDayPart.lateNight => 'Late night',
  };

  /// What this window is about, e.g. "Breakfast time".
  String get headline => switch (this) {
    CareDayPart.morning => 'Breakfast time',
    CareDayPart.midMorning => 'Mid-morning snack',
    CareDayPart.afternoon => 'Lunch time',
    CareDayPart.evening => 'Evening tea & a walk',
    CareDayPart.night => 'Dinner time',
    CareDayPart.lateNight => 'Wind down for the night',
  };

  /// Greeting shown above the headline.
  String get greeting => switch (this) {
    CareDayPart.morning => 'Good morning',
    CareDayPart.midMorning => 'Good morning',
    CareDayPart.afternoon => 'Good afternoon',
    CareDayPart.evening => 'Good evening',
    CareDayPart.night => 'Good evening',
    CareDayPart.lateNight => 'Good night',
  };

  IconData get icon => switch (this) {
    CareDayPart.morning => Icons.wb_twilight_rounded,
    CareDayPart.midMorning => Icons.wb_sunny_outlined,
    CareDayPart.afternoon => Icons.light_mode_rounded,
    CareDayPart.evening => Icons.wb_twilight_rounded,
    CareDayPart.night => Icons.dinner_dining_rounded,
    CareDayPart.lateNight => Icons.nightlight_round,
  };

  /// Human-readable window, e.g. "5:00 AM – 11:00 AM".
  String get timeRange => switch (this) {
    CareDayPart.morning => '5:00 AM – 11:00 AM',
    CareDayPart.midMorning => '11:00 AM – 12:30 PM',
    CareDayPart.afternoon => '12:30 PM – 4:30 PM',
    CareDayPart.evening => '4:30 PM – 7:00 PM',
    CareDayPart.night => '7:00 PM – 10:00 PM',
    CareDayPart.lateNight => '10:00 PM – 5:00 AM',
  };

  /// The main meal this window logs, if any. `null` for the snack and
  /// wind-down windows.
  CareMeal? get meal => switch (this) {
    CareDayPart.morning => CareMeal.breakfast,
    CareDayPart.afternoon => CareMeal.lunch,
    CareDayPart.night => CareMeal.dinner,
    CareDayPart.midMorning ||
    CareDayPart.evening ||
    CareDayPart.lateNight => null,
  };
}

/// A main meal that Today's Care can log, mapped onto the vital keys the rest
/// of the app already reads (see `nutrition_tiles.dart`).
///
/// Snacks and drinks are deliberately not here — they are logged as counts
/// (portions / cups) rather than through the meal sheet.
enum CareMeal {
  breakfast('breakfast', 'Breakfast', 400),
  lunch('lunch', 'Lunch', 600),
  dinner('dinner', 'Dinner', 550);

  const CareMeal(this.vitalKey, this.label, this.typicalCalories);

  /// Vital key this meal is stored under.
  final String vitalKey;
  final String label;

  /// Pre-filled calorie estimate in the log sheet.
  final int typicalCalories;

  /// Legacy alias also written by earlier builds; readers must check both.
  String? get legacyVitalKey =>
      this == CareMeal.breakfast ? 'break_fast' : null;
}
