/// Every specialized agent the Agents tab can open, and where each one goes.
///
/// One entry per feature, so the grid, the search and the navigation all read
/// from the same list instead of drifting apart. Each agent points at the page
/// that already exists for it — the health agents open the very detail pages My
/// Health opens, so the chart and the full history are the same ones she sees
/// there rather than a second, thinner copy.
library;

import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/allobot/pages/daily_activity_page.dart';
import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/my_health/vitals/blood_glucose/blood_glucose_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/blood_pressure_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/body_composition/body_composition_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/heart_rate_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/hemoglobin/hemoglobin_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/hrv/hrv_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/steps/steps_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/stress/stress_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/drinks/drinks_overview_screen.dart';
import 'package:allomom/features/my_health/vitals/meals/meal_kind.dart';
import 'package:allomom/features/my_health/vitals/meals/meal_overview_screen.dart';
import 'package:allomom/features/my_health/vitals/meals/snacks_overview_screen.dart';
import 'package:allomom/features/my_health/vitals/water/water_overview_screen.dart';

/// The bands the grid is split into, in the order they are shown.
enum AgentGroup {
  care('Care agents', 'The helpers that work alongside you'),
  vitals('Vitals & trends', 'Charts and history from your wearable and logs'),
  readings('Body readings', 'The numbers your clinic asks for'),
  nutrition('Nutrition & intake', 'What you ate and drank, day by day');

  const AgentGroup(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

/// The pill on an agent card.
class AgentStatus {
  const AgentStatus(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;

  /// Always on, whether or not anything was recorded (AlloCry).
  static const listening = AgentStatus(
    'Listening',
    Color(0xFF2563EB),
    Color(0xFFDBEAFE),
  );

  /// Something was recorded today.
  static const active = AgentStatus(
    'Active',
    Color(0xFF059669),
    Color(0xFFD1FAE5),
  );

  /// Readings exist, but none from today.
  static const tracking = AgentStatus(
    'Tracking',
    Color(0xFF7C3AED),
    Color(0xFFEDE9FE),
  );

  /// Nothing recorded yet.
  static const idle = AgentStatus(
    'Idle',
    Color(0xFF64748B),
    Color(0xFFF1F5F9),
  );
}

/// One agent: how it looks, what it reads its status from, and where it opens.
class AgentSpec {
  const AgentSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.group,
    required this.pageBuilder,
    this.vitalKeys = const [],
    this.fixedStatus,
    this.keywords = const [],
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final AgentGroup group;

  /// The page this agent opens — the same one My Health opens for it.
  final WidgetBuilder pageBuilder;

  /// Vitals-stream keys the status pill is read from. Several where earlier
  /// builds wrote the same reading under a different name.
  final List<String> vitalKeys;

  /// A pill that never changes, for an agent whose state is not a reading.
  final AgentStatus? fixedStatus;

  /// Extra words search should match, beyond the name and the description.
  final List<String> keywords;

  /// What the pill says right now, read from what has actually been recorded.
  AgentStatus get status {
    if (fixedStatus != null) return fixedStatus!;
    if (vitalKeys.isEmpty) return AgentStatus.idle;

    final controller = HealthVitalsController.instance;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    var hasAny = false;
    for (final key in vitalKeys) {
      final history = controller.getHistory(key);
      if (history.isEmpty) continue;
      hasAny = true;
      final loggedToday = history.any(
        (row) => !row.createdAt.isBefore(startOfToday),
      );
      if (loggedToday) return AgentStatus.active;
    }
    return hasAny ? AgentStatus.tracking : AgentStatus.idle;
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if (description.toLowerCase().contains(q)) return true;
    return keywords.any((k) => k.toLowerCase().contains(q));
  }
}

/// Every agent, grouped by [AgentGroup].
abstract final class AgentCatalog {
  static const List<AgentSpec> all = [
    // ─── Care agents ───
    AgentSpec(
      id: 'allocry',
      name: 'AlloCry',
      description: 'Listens for baby crying',
      icon: Icons.volume_up_rounded,
      iconColor: Color(0xFFD97706),
      iconBackground: Color(0xFFFEF3C7),
      group: AgentGroup.care,
      fixedStatus: AgentStatus.listening,
      keywords: ['cry', 'baby', 'sound', 'audio'],
      pageBuilder: _alloCry,
    ),
    AgentSpec(
      id: 'kick_counter',
      name: 'Kick counter',
      description: 'Counts kicks with you',
      icon: Icons.directions_walk_rounded,
      iconColor: Color(0xFFFF4E6A),
      iconBackground: Color(0xFFFFE4E9),
      group: AgentGroup.care,
      vitalKeys: ['kick_count', 'kicks'],
      keywords: ['kicks', 'movement', 'baby'],
      pageBuilder: _kickCounter,
    ),
    AgentSpec(
      id: 'feeding_tracker',
      name: 'Feeding tracker',
      description: 'Logs every feed',
      icon: Icons.restaurant_rounded,
      iconColor: Color(0xFF9333EA),
      iconBackground: Color(0xFFF3E8FF),
      group: AgentGroup.care,
      vitalKeys: ['feeding'],
      keywords: ['feed', 'breastfeeding', 'bottle', 'milk'],
      pageBuilder: _feedingTracker,
    ),
    AgentSpec(
      id: 'daily_activity',
      name: 'Daily activity',
      description: "Today's five things",
      icon: Icons.access_time_rounded,
      iconColor: Color(0xFF0891B2),
      iconBackground: Color(0xFFCFFAFE),
      group: AgentGroup.care,
      vitalKeys: ['todocare'],
      keywords: ['care', 'todo', 'tasks', 'routine'],
      pageBuilder: _dailyActivity,
    ),

    // ─── Vitals & trends ───
    AgentSpec(
      id: 'steps',
      name: 'Steps',
      description: 'Counts your walking',
      icon: Icons.directions_run_rounded,
      iconColor: Color(0xFF10B981),
      iconBackground: Color(0xFFD1FAE5),
      group: AgentGroup.vitals,
      vitalKeys: ['steps'],
      keywords: ['walk', 'activity', 'fitness'],
      pageBuilder: _steps,
    ),
    AgentSpec(
      id: 'heart_rate',
      name: 'Heart rate',
      description: 'Watches your pulse',
      icon: Icons.favorite_rounded,
      iconColor: Color(0xFFEF4444),
      iconBackground: Color(0xFFFEE2E2),
      group: AgentGroup.vitals,
      vitalKeys: ['heart_rate'],
      keywords: ['bpm', 'pulse', 'heart'],
      pageBuilder: _heartRate,
    ),
    AgentSpec(
      id: 'hrv',
      name: 'HRV',
      description: 'Reads your recovery',
      icon: Icons.monitor_heart_rounded,
      iconColor: Color(0xFF6366F1),
      iconBackground: Color(0xFFE0E7FF),
      group: AgentGroup.vitals,
      vitalKeys: ['hrv'],
      keywords: ['variability', 'recovery', 'heart'],
      pageBuilder: _hrv,
    ),
    AgentSpec(
      id: 'blood_oxygen',
      name: 'Blood oxygen',
      description: 'Checks your SpO2',
      icon: Icons.bubble_chart_rounded,
      iconColor: Color(0xFF0EA5E9),
      iconBackground: Color(0xFFE0F2FE),
      group: AgentGroup.vitals,
      vitalKeys: ['blood_oxygen'],
      keywords: ['spo2', 'oxygen', 'saturation'],
      pageBuilder: _bloodOxygen,
    ),
    AgentSpec(
      id: 'stress',
      name: 'Stress load',
      description: 'Notices the strain',
      icon: Icons.self_improvement_rounded,
      iconColor: Color(0xFFF59E0B),
      iconBackground: Color(0xFFFEF3C7),
      group: AgentGroup.vitals,
      vitalKeys: ['stress'],
      keywords: ['calm', 'relax', 'tension'],
      pageBuilder: _stress,
    ),
    AgentSpec(
      id: 'sleep',
      name: 'Sleep',
      description: 'Tracks your rest',
      icon: Icons.bedtime_rounded,
      iconColor: Color(0xFF8B5CF6),
      iconBackground: Color(0xFFEDE9FE),
      group: AgentGroup.vitals,
      vitalKeys: ['sleep'],
      keywords: ['rest', 'night', 'hours'],
      pageBuilder: _sleep,
    ),

    // ─── Body readings ───
    AgentSpec(
      id: 'blood_pressure',
      name: 'Blood pressure',
      description: 'Keeps your BP log',
      icon: Icons.speed_rounded,
      iconColor: Color(0xFFE11D48),
      iconBackground: Color(0xFFFFE4E6),
      group: AgentGroup.readings,
      vitalKeys: ['blood_pressure'],
      keywords: ['bp', 'systolic', 'diastolic'],
      pageBuilder: _bloodPressure,
    ),
    AgentSpec(
      id: 'hemoglobin',
      name: 'Hemoglobin',
      description: 'Follows your Hb',
      icon: Icons.bloodtype_rounded,
      iconColor: Color(0xFFBE123C),
      iconBackground: Color(0xFFFFE4E6),
      group: AgentGroup.readings,
      vitalKeys: ['hemoglobin'],
      keywords: ['hb', 'anaemia', 'anemia', 'blood'],
      pageBuilder: _hemoglobin,
    ),
    AgentSpec(
      id: 'blood_glucose',
      name: 'Blood glucose',
      description: 'Watches your sugar',
      icon: Icons.science_rounded,
      iconColor: Color(0xFF7C3AED),
      iconBackground: Color(0xFFF3E8FF),
      group: AgentGroup.readings,
      vitalKeys: ['glucose', 'blood_glucose'],
      keywords: ['sugar', 'diabetes', 'gtt'],
      pageBuilder: _bloodGlucose,
    ),
    AgentSpec(
      id: 'weight',
      name: 'Weight',
      description: 'Watches your gain',
      icon: Icons.show_chart_rounded,
      iconColor: Color(0xFFDB2777),
      iconBackground: Color(0xFFFCE7F3),
      group: AgentGroup.readings,
      vitalKeys: ['weight'],
      keywords: ['bmi', 'kg', 'gain'],
      pageBuilder: _weight,
    ),

    // ─── Nutrition & intake ───
    AgentSpec(
      id: 'water',
      name: 'Water',
      description: 'Nudges you to drink',
      icon: Icons.water_drop_rounded,
      iconColor: Color(0xFF0284C7),
      iconBackground: Color(0xFFE0F2FE),
      group: AgentGroup.nutrition,
      vitalKeys: ['water'],
      keywords: ['hydration', 'glasses', 'intake', 'drink'],
      pageBuilder: _water,
    ),
    AgentSpec(
      id: 'breakfast',
      name: 'Breakfast',
      description: 'Logs your morning meal',
      icon: Icons.breakfast_dining_rounded,
      iconColor: Color(0xFFF59E0B),
      iconBackground: Color(0xFFFEF3C7),
      group: AgentGroup.nutrition,
      vitalKeys: ['breakfast', 'break_fast'],
      keywords: ['meal', 'calories', 'morning'],
      pageBuilder: _breakfast,
    ),
    AgentSpec(
      id: 'lunch',
      name: 'Lunch',
      description: 'Logs your midday meal',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFF10B981),
      iconBackground: Color(0xFFD1FAE5),
      group: AgentGroup.nutrition,
      vitalKeys: ['lunch'],
      keywords: ['meal', 'calories', 'afternoon'],
      pageBuilder: _lunch,
    ),
    AgentSpec(
      id: 'dinner',
      name: 'Dinner',
      description: 'Logs your evening meal',
      icon: Icons.dinner_dining_rounded,
      iconColor: Color(0xFF8B5CF6),
      iconBackground: Color(0xFFEDE9FE),
      group: AgentGroup.nutrition,
      vitalKeys: ['dinner'],
      keywords: ['meal', 'calories', 'night'],
      pageBuilder: _dinner,
    ),
    AgentSpec(
      id: 'snacks',
      name: 'Snacks',
      description: 'Counts the small bites',
      icon: Icons.cookie_rounded,
      iconColor: Color(0xFFF472B6),
      iconBackground: Color(0xFFFCE7F3),
      group: AgentGroup.nutrition,
      vitalKeys: ['snacks'],
      keywords: ['snack', 'calories', 'portions'],
      pageBuilder: _snacks,
    ),
    AgentSpec(
      id: 'drinks',
      name: 'Drinks',
      description: 'Notes what you sipped',
      icon: Icons.local_cafe_rounded,
      iconColor: Color(0xFFD97706),
      iconBackground: Color(0xFFFEF3C7),
      group: AgentGroup.nutrition,
      vitalKeys: ['drinks'],
      keywords: ['tea', 'coffee', 'juice', 'cups'],
      pageBuilder: _drinks,
    ),
  ];

  /// The agents in [group], in catalogue order.
  static List<AgentSpec> inGroup(AgentGroup group) =>
      all.where((a) => a.group == group).toList();

  /// Opens an agent's page.
  static Future<void> open(BuildContext context, AgentSpec agent) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: agent.pageBuilder),
    );
  }

  // Const-friendly builders — a tear-off can sit in a const list, a closure
  // cannot.
  static Widget _alloCry(BuildContext _) => const AlloCryPage();
  static Widget _kickCounter(BuildContext _) => const KickCounterPage();
  static Widget _feedingTracker(BuildContext _) => const FeedingTrackerPage();
  static Widget _dailyActivity(BuildContext _) => const DailyActivityPage();
  static Widget _steps(BuildContext _) => const StepsSummaryScreen();
  static Widget _heartRate(BuildContext _) => const HeartRateSummaryScreen();
  static Widget _hrv(BuildContext _) => const HrvSummaryScreen();
  static Widget _bloodOxygen(BuildContext _) => const BloodOxygenSummaryScreen();
  static Widget _stress(BuildContext _) => const StressSummaryScreen();
  static Widget _sleep(BuildContext _) => const SleepSummaryScreen();
  static Widget _bloodPressure(BuildContext _) =>
      const BloodPressureSummaryScreen();
  static Widget _hemoglobin(BuildContext _) => const HemoglobinSummaryScreen();
  static Widget _bloodGlucose(BuildContext _) => const BloodGlucoseSummaryScreen();
  static Widget _weight(BuildContext _) => const BodyCompositionSummaryScreen();
  static Widget _water(BuildContext _) =>
      const WaterOverviewScreen();
  static Widget _breakfast(BuildContext _) =>
      const MealOverviewScreen(meal: MealKind.breakfast);
  static Widget _lunch(BuildContext _) =>
      const MealOverviewScreen(meal: MealKind.lunch);
  static Widget _dinner(BuildContext _) =>
      const MealOverviewScreen(meal: MealKind.dinner);
  static Widget _snacks(BuildContext _) =>
      const SnacksOverviewScreen();
  static Widget _drinks(BuildContext _) =>
      const DrinksOverviewScreen();
}
