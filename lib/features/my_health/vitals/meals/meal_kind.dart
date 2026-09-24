// Ported from AlloConnect lib/features/health_section/vitals/{breakfast,lunch,dinner}/.
//
// AlloConnect keeps three near-identical copies of the overview screen and the
// entry sheet; here the per-meal differences (key, colours, icons, copy) live
// in one place and the screens read them.
import 'package:flutter/material.dart';

enum MealKind { breakfast, lunch, dinner }

extension MealKindSpec on MealKind {
  /// The vital key Allomom writes (Home, Today's care and the calorie tile read it).
  String get vitalKey => switch (this) {
    MealKind.breakfast => 'breakfast',
    MealKind.lunch => 'lunch',
    MealKind.dinner => 'dinner',
  };

  /// Every key a row of this meal may have been stored under.
  List<String> get readKeys => switch (this) {
    MealKind.breakfast => const ['breakfast', 'break_fast'],
    MealKind.lunch => const ['lunch'],
    MealKind.dinner => const ['dinner'],
  };

  String get label => switch (this) {
    MealKind.breakfast => 'Breakfast',
    MealKind.lunch => 'Lunch',
    MealKind.dinner => 'Dinner',
  };

  String get lower => label.toLowerCase();

  // ── Overview screen ──
  Color get overviewColor => switch (this) {
    MealKind.breakfast => Colors.orange.shade500,
    MealKind.lunch => Colors.green.shade600,
    MealKind.dinner => const Color(0xFF6366F1),
  };

  IconData get overviewIcon => switch (this) {
    MealKind.breakfast => Icons.wb_sunny_rounded,
    MealKind.lunch => Icons.lunch_dining_rounded,
    MealKind.dinner => Icons.dinner_dining_rounded,
  };

  String get defaultTitle => switch (this) {
    MealKind.breakfast => 'Healthy Breakfast',
    MealKind.lunch => 'Satisfying Lunch',
    MealKind.dinner => 'Mindful Dinner',
  };

  String get emptyTodaySubtitle => switch (this) {
    MealKind.breakfast =>
      'Start your morning right! Track your breakfast to monitor your daily energy.',
    MealKind.lunch =>
      'Keep your energy balanced! Track your midday meal to stay focused all day.',
    MealKind.dinner =>
      'Wrap up your day mindfully! Track your dinner to maintain nutritional balance.',
  };

  // ── Entry sheet ──
  /// Header badge and time-picker icon colour.
  Color get entryColor => switch (this) {
    MealKind.breakfast => Colors.orange,
    MealKind.lunch => Colors.green,
    MealKind.dinner => Colors.indigo.shade400,
  };

  /// Text-field prefix icon colour.
  Color get entryFieldColor => switch (this) {
    MealKind.breakfast => Colors.orange.shade400,
    MealKind.lunch => Colors.green.shade400,
    MealKind.dinner => Colors.indigo.shade400,
  };

  IconData get entryIcon => switch (this) {
    MealKind.breakfast => Icons.breakfast_dining_rounded,
    MealKind.lunch => Icons.lunch_dining_rounded,
    MealKind.dinner => Icons.dinner_dining_rounded,
  };

  String get entrySubtitle => switch (this) {
    MealKind.breakfast =>
      'Keep track of your morning nutrition to maintain a healthy lifestyle.',
    MealKind.lunch =>
      'Keep track of your midday meal to stay energized throughout the day.',
    MealKind.dinner =>
      'Wind down your day with a nutritious dinner to support overnight recovery.',
  };

  String get detailsHint => switch (this) {
    MealKind.breakfast => 'e.g. Oatmeal with blueberries and honey',
    MealKind.lunch => 'e.g. Quinoa salad with grilled chicken',
    MealKind.dinner => 'e.g. Grilled salmon with steamed asparagus',
  };

  String get caloriesHint => switch (this) {
    MealKind.breakfast => 'e.g. 450',
    MealKind.lunch => 'e.g. 650',
    MealKind.dinner => 'e.g. 500',
  };
}
