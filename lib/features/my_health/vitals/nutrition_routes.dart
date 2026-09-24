// Maps Allomom's NutritionMetric (the nutrition tiles / overview cards) onto
// the ported AlloConnect overview screens and entry sheets.
import 'package:flutter/material.dart';

import 'package:allomom/features/my_health/vitals/drinks/drinks_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/drinks/drinks_overview_screen.dart';
import 'package:allomom/features/my_health/vitals/meals/meal_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/meals/meal_kind.dart';
import 'package:allomom/features/my_health/vitals/meals/meal_overview_screen.dart';
import 'package:allomom/features/my_health/vitals/meals/snacks_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/meals/snacks_overview_screen.dart';
import 'package:allomom/features/my_health/vitals/water/water_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/water/water_overview_screen.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_detail_page.dart'
    show NutritionMetric;

/// The overview screen for one nutrition [metric].
Widget nutritionOverviewScreen(NutritionMetric metric, {String? userId}) {
  return switch (metric) {
    NutritionMetric.breakfast =>
      MealOverviewScreen(meal: MealKind.breakfast, userId: userId),
    NutritionMetric.lunch =>
      MealOverviewScreen(meal: MealKind.lunch, userId: userId),
    NutritionMetric.dinner =>
      MealOverviewScreen(meal: MealKind.dinner, userId: userId),
    NutritionMetric.snacks => SnacksOverviewScreen(userId: userId),
    NutritionMetric.drinks => DrinksOverviewScreen(userId: userId),
    NutritionMetric.water => WaterOverviewScreen(userId: userId),
  };
}

/// Opens the entry sheet for one nutrition [metric]; true when saved.
Future<bool?> showNutritionEntrySheet(
  BuildContext context,
  NutritionMetric metric, {
  String? userId,
}) {
  return switch (metric) {
    NutritionMetric.breakfast =>
      showMealEntrySheet(context, meal: MealKind.breakfast, userId: userId),
    NutritionMetric.lunch =>
      showMealEntrySheet(context, meal: MealKind.lunch, userId: userId),
    NutritionMetric.dinner =>
      showMealEntrySheet(context, meal: MealKind.dinner, userId: userId),
    NutritionMetric.snacks => showSnacksEntrySheet(context, userId: userId),
    NutritionMetric.drinks => showDrinksEntrySheet(context, userId: userId),
    NutritionMetric.water => showWaterEntrySheet(context, userId: userId),
  };
}
