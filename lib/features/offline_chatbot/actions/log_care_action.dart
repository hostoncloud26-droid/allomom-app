/// Lets a flow open the same meal/water logging sheets Today's Care uses, and
/// saves what she enters exactly the way that section does — see
/// `todocare_section.dart`'s `_logMeal`/`_logCount`, which this mirrors.
library;

import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_count_sheet.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';
import 'package:allomom/main.dart' show rootNavigatorKey;

String? _userIdOrNull() {
  final id = MainController.instance.userId.trim();
  return id.isEmpty ? null : id;
}

/// Opens [CareMealSheet] for a fixed [meal] and logs what she enters.
class LogMealAction implements OfflineChatbotAction {
  const LogMealAction({
    required this.meal,
    required this.icon,
    required this.color,
  });

  final CareMeal meal;
  final IconData icon;
  final Color color;

  @override
  String get name => 'open_${meal.vitalKey}_sheet';

  @override
  String get description =>
      'Opens the sheet to log ${meal.label.toLowerCase()}.';

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return const ActionResult.failed(
        'I cannot open that right now — try again in a moment.',
      );
    }

    final log = await CareMealSheet.show(
      context,
      meal: meal,
      color: color,
      icon: icon,
    );
    if (log == null) return const ActionResult.ok(data: {'logged': false});

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
          'day_part': CareDayPart.at().name,
        },
      );
      return ActionResult.ok(data: {'logged': true, 'calories': log.calories});
    } catch (e) {
      return ActionResult.failed('Could not log ${meal.label.toLowerCase()}: $e');
    }
  }
}

/// Opens [CareCountSheet] for water and logs the glasses she enters.
class LogWaterAction implements OfflineChatbotAction {
  const LogWaterAction();

  @override
  String get name => 'open_water_sheet';

  @override
  String get description => 'Opens the sheet to log a glass of water.';

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return const ActionResult.failed(
        'I cannot open that right now — try again in a moment.',
      );
    }

    final amount = await CareCountSheet.show(
      context,
      title: 'Drink water',
      unitLabel: 'glasses',
      unitLabelSingular: 'glass',
      icon: Icons.water_drop_rounded,
      color: const Color(0xff26C6DA),
      presets: const [1, 2, 3],
    );
    if (amount == null) return const ActionResult.ok(data: {'logged': false});

    try {
      await HealthVitalsController.instance.addVitalEntry(
        key: 'water',
        value: amount.toDouble(),
        unit: 'glasses',
        createdAt: DateTime.now(),
        userId: _userIdOrNull(),
        data: {
          'details': '$amount ${amount == 1 ? 'glass' : 'glasses'}',
          'type': 'water',
          'count': amount,
          'count_unit': 'glasses',
          'day_part': CareDayPart.at().name,
        },
      );
      return ActionResult.ok(data: {'logged': true, 'count': amount});
    } catch (e) {
      return ActionResult.failed('Could not log water: $e');
    }
  }
}
