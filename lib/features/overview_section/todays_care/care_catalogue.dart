import 'package:flutter/material.dart';

import 'package:allomom/config/colors.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';

/// How tapping a care item behaves.
enum CareActionKind {
  /// Opens the meal sheet and logs calories under the meal's vital key.
  meal,

  /// Opens the count sheet (glasses / cups / portions) and logs the amount.
  count,

  /// Plain tick-off, logged as a `todocare` vital.
  checkoff,

  /// Opens another screen instead of logging inline.
  navigate,
}

/// Screens a care item can send the user to.
enum CareDestination { kickCounter }

/// One row in Today's Care, scoped to a single [CareDayPart].
class CareItem {
  const CareItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.kind,
    this.meal,
    this.countVitalKey,
    this.unitPlural = '',
    this.unitSingular = '',
    this.dailyTarget,
    this.presets = const [1, 2, 3],
    this.caloriesPerUnit,
    this.actionValue,
    this.destination,
    this.doneVitalKey,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final CareActionKind kind;

  /// Set when [kind] is [CareActionKind.meal].
  final CareMeal? meal;

  /// Vital key for [CareActionKind.count] items, e.g. `water`, `drinks`.
  final String? countVitalKey;
  final String unitPlural;
  final String unitSingular;

  /// Daily goal for a count item; null when the item has no goal.
  final int? dailyTarget;
  final List<int> presets;

  /// Calories one unit is worth.
  ///
  /// `snacks` and `drinks` are calorie series everywhere else in the app (the
  /// calorie tracker sums them), so a count item on those keys stores
  /// `count × caloriesPerUnit` kcal in the vital's value and keeps the raw
  /// count in `data['count']`. Left null for `water`, where the value *is*
  /// the number of glasses.
  final int? caloriesPerUnit;

  /// `todocare` unit written for [CareActionKind.checkoff] items. Doubles as
  /// the de-duplication key, so it must stay stable across releases.
  final String? actionValue;

  /// Set when [kind] is [CareActionKind.navigate].
  final CareDestination? destination;

  /// For [CareActionKind.navigate] items: the vital key the destination screen
  /// writes. Any row for it today marks this item done, so counting kicks in
  /// the kick counter ticks the item off here.
  final String? doneVitalKey;
}

/// Builds the care items for one time window, tailored to whether the user is
/// pregnant and how far along she is.
///
/// Meals follow the clock: breakfast before 11 AM, a mid-morning snack, lunch
/// in the afternoon, tea in the early evening and dinner at night. Pregnancy
/// items are placed in the window where they actually belong — folic acid
/// after breakfast, iron after lunch, calcium after dinner, kick counting in
/// the evening when the baby is most active, left-side rest at bedtime.
List<CareItem> careItemsFor({
  required CareDayPart part,
  required bool isPregnant,
  required int pregnancyDay,
}) {
  final trimester = _trimesterFor(pregnancyDay);
  final week = _weekFor(pregnancyDay);

  final water = _waterItem(
    part: part,
    isPregnant: isPregnant,
    trimester: trimester,
  );

  return switch (part) {
    CareDayPart.morning => [
      if (isPregnant && week <= 14)
        const CareItem(
          id: 'nausea_care',
          title: 'Something dry before you sit up',
          subtitle:
              'A biscuit or toast before getting out of bed settles '
              'morning sickness',
          icon: Icons.bakery_dining_rounded,
          color: Color(0xffF59E0B),
          kind: CareActionKind.checkoff,
          actionValue: 'managing nausea',
        ),
      _mealItem(
        CareMeal.breakfast,
        subtitle: isPregnant
            ? switch (trimester) {
                1 => 'Something bland and dry helps with morning nausea',
                2 => 'Protein and iron-rich start — eggs, poha, sprouts',
                _ => 'Fibre-rich breakfast keeps digestion comfortable',
              }
            : 'Start with protein and whole grains to steady your energy',
        icon: Icons.free_breakfast_rounded,
        color: const Color(0xffFF9800),
      ),
      water,
      if (isPregnant)
        CareItem(
          id: 'folic_acid',
          title: 'Folic acid & prenatal vitamin',
          subtitle: trimester == 1
              ? 'Take it after breakfast — critical in the first trimester'
              : 'Take your prenatal vitamin after breakfast',
          icon: Icons.medication_rounded,
          color: primaryColor,
          kind: CareActionKind.checkoff,
          actionValue: 'taking prenatal vitamins',
        ),
      CareItem(
        id: 'morning_movement',
        title: isPregnant ? 'Prenatal yoga or a walk' : 'Morning movement',
        subtitle: isPregnant
            ? switch (trimester) {
                1 => 'Gentle 15–20 min walk to get your circulation going',
                2 => 'A 25–30 min walk while your energy is at its best',
                _ => 'Easy 20 min walk — stop if you feel pelvic pressure',
              }
            : '20–30 min brisk walk or a workout to start the day',
        icon: Icons.self_improvement_rounded,
        color: const Color(0xff4CAF50),
        kind: CareActionKind.checkoff,
        actionValue: 'walking',
      ),
    ],
    CareDayPart.midMorning => [
      if (isPregnant) ?_milestoneItem(week),
      _snackItem(
        subtitle: isPregnant
            ? 'Fruit, nuts or yoghurt keeps nausea and dizziness away'
            : 'A handful of nuts or fruit to bridge to lunch',
      ),
      water,
      if (isPregnant && week >= 12)
        const CareItem(
          id: 'pelvic_floor',
          title: 'Pelvic floor squeezes',
          subtitle:
              '10 slow holds and 10 quick ones — they make pushing and '
              'recovery easier',
          icon: Icons.fitness_center_rounded,
          color: Color(0xff00897B),
          kind: CareActionKind.checkoff,
          actionValue: 'pelvic floor exercises',
        ),
      _coffeeItem(isPregnant: isPregnant),
    ],
    CareDayPart.afternoon => [
      _mealItem(
        CareMeal.lunch,
        subtitle: isPregnant
            ? switch (trimester) {
                1 => 'Small and frequent beats one heavy plate right now',
                2 =>
                  'Dal, leafy greens and a protein — your baby is growing fast',
                _ => 'Balanced plate with fibre to keep heartburn down',
              }
            : 'Half your plate vegetables, then protein and whole grains',
        icon: Icons.lunch_dining_rounded,
        color: const Color(0xffEF6C00),
      ),
      water,
      if (isPregnant)
        const CareItem(
          id: 'iron_tablet',
          title: 'Iron tablet',
          subtitle: 'Take it an hour after lunch, not with milk or tea',
          icon: Icons.medication_liquid_rounded,
          color: primaryColor,
          kind: CareActionKind.checkoff,
          actionValue: 'taking iron tablet',
        ),
      if (isPregnant && trimester >= 2)
        const CareItem(
          id: 'afternoon_rest',
          title: 'Put your feet up',
          subtitle: '20 min rest with your feet elevated eases swelling',
          icon: Icons.airline_seat_recline_extra_rounded,
          color: Color(0xff6C63FF),
          kind: CareActionKind.checkoff,
          actionValue: 'resting',
        ),
    ],
    CareDayPart.evening => [
      _coffeeItem(isPregnant: isPregnant),
      _snackItem(
        subtitle: isPregnant
            ? 'Roasted chana, fruit or a chikki — skip the fried snacks'
            : 'Something light so you are not ravenous at dinner',
      ),
      // From 16 weeks, when the first flutters are felt. Until 28 it is
      // about getting to know her baby's pattern; after that the ten-kick
      // count is the one that matters clinically, so the copy changes but
      // the screen behind it does not.
      if (isPregnant && week >= 16)
        CareItem(
          id: 'kick_count',
          title: week >= 28 ? 'Count my kicks' : "Feel your baby's movements",
          subtitle: week >= 28
              ? 'Evenings are when baby is most active — count 10 kicks'
              : week >= 20
              ? 'Kicks and rolls should be daily now — learn her pattern'
              : 'Flutters and bubbles start about now — log what you feel',
          icon: Icons.child_friendly_rounded,
          color: const Color(0xff9C27B0),
          kind: CareActionKind.navigate,
          destination: CareDestination.kickCounter,
          doneVitalKey: 'kick_count',
        ),
      if (isPregnant && week >= 20)
        const CareItem(
          id: 'swelling_check',
          title: 'Check for swelling',
          subtitle:
              'Hands, feet and face — sudden puffiness needs your '
              'clinic the same day',
          icon: Icons.back_hand_rounded,
          color: Color(0xff0288D1),
          kind: CareActionKind.checkoff,
          actionValue: 'checking for swelling',
        ),
      CareItem(
        id: 'evening_walk',
        title: isPregnant ? 'Evening gentle walk' : 'Evening walk',
        subtitle: isPregnant
            ? 'A slow 15–20 min walk helps digestion and sleep'
            : 'Wind down the day with a 20 min walk',
        icon: Icons.directions_walk_rounded,
        color: const Color(0xff4CAF50),
        kind: CareActionKind.checkoff,
        actionValue: 'walking',
      ),
      water,
    ],
    CareDayPart.night => [
      _mealItem(
        CareMeal.dinner,
        subtitle: isPregnant
            ? switch (trimester) {
                1 => 'Keep it light and early to settle nausea before bed',
                2 => 'Finish 2 hours before bed so you sleep comfortably',
                _ => 'Light and early — it keeps night-time heartburn away',
              }
            : 'Lighter than lunch, and finish a couple of hours before bed',
        icon: Icons.dinner_dining_rounded,
        color: const Color(0xffD84315),
      ),
      water,
      if (isPregnant)
        const CareItem(
          id: 'calcium_tablet',
          title: 'Calcium tablet',
          subtitle: 'After dinner — keep it apart from your iron tablet',
          icon: Icons.medication_rounded,
          color: primaryColor,
          kind: CareActionKind.checkoff,
          actionValue: 'taking calcium tablet',
        ),
      if (isPregnant && week >= 36)
        const CareItem(
          id: 'labour_watch',
          title: 'Watch for labour signs',
          subtitle:
              'Regular tightening, a gush of fluid or any bleeding — '
              'call your clinic',
          icon: Icons.notifications_active_rounded,
          color: Color(0xffE53935),
          kind: CareActionKind.checkoff,
          actionValue: 'watching for labour signs',
        ),
    ],
    CareDayPart.lateNight => [
      if (isPregnant)
        CareItem(
          id: 'left_side_sleep',
          title: 'Left-side sleep setup',
          subtitle: trimester >= 2
              ? 'Left side with a pillow between your knees — best blood flow to baby'
              : 'Settle on your left side for the best circulation',
          icon: Icons.bed_rounded,
          color: const Color(0xff6C63FF),
          kind: CareActionKind.checkoff,
          actionValue: 'resting',
        )
      else
        const CareItem(
          id: 'sleep',
          title: 'Wind down for sleep',
          subtitle: 'Aim for 7–8 hours of uninterrupted rest',
          icon: Icons.nightlight_round,
          color: Color(0xff6C63FF),
          kind: CareActionKind.checkoff,
          actionValue: 'resting',
        ),
      if (isPregnant && week >= 16)
        const CareItem(
          id: 'belly_care',
          title: 'Oil your bump',
          subtitle:
              'A few minutes of oil or cream keeps the stretching skin '
              'comfortable',
          icon: Icons.spa_outlined,
          color: Color(0xffFF7043),
          kind: CareActionKind.checkoff,
          actionValue: 'belly care',
        ),
      if (isPregnant && week >= 18)
        const CareItem(
          id: 'talk_to_baby',
          title: 'Talk to your baby',
          subtitle:
              'She can hear you from about now — read, sing or just '
              'tell her about your day',
          icon: Icons.favorite_rounded,
          color: Color(0xffEC407A),
          kind: CareActionKind.checkoff,
          actionValue: 'talking to baby',
        ),
      if (isPregnant && week >= 34)
        const CareItem(
          id: 'perineal_massage',
          title: 'Perineal massage',
          subtitle: '5 min a day from 34 weeks lowers the chance of tearing',
          icon: Icons.healing_rounded,
          color: Color(0xff8E24AA),
          kind: CareActionKind.checkoff,
          actionValue: 'perineal massage',
        ),
      CareItem(
        id: 'stretch',
        title: 'Stretch & breathe',
        subtitle: isPregnant && week >= 30
            ? '5 min of slow breathing — the same rhythm carries you through '
                  'labour'
            : '5 min of gentle stretching and slow breathing',
        icon: Icons.self_improvement_rounded,
        color: const Color(0xffE91E63),
        kind: CareActionKind.checkoff,
        actionValue: 'stretching',
      ),
      water,
    ],
  };
}

/// Completed weeks of pregnancy, the way the rest of the app counts them
/// (`PregnancyController.currentGestationalWeek`).
///
/// Gates read as a clinic would say them: `week >= 16` is "from 16 weeks",
/// which begins on day 112.
int _weekFor(int pregnancyDay) {
  final week = pregnancyDay ~/ 7;
  if (week < 0) return 0;
  return week > 42 ? 42 : week;
}

/// The one appointment or preparation this week calls for, if any.
///
/// Scans, the sugar test and the vaccine each belong to a window of weeks
/// rather than to a day, so the list carries whichever window she is in — one
/// at a time, in the order they come due, so a mother at 28 weeks is asked
/// about her glucose test rather than about that and her vaccine at once.
CareItem? _milestoneItem(int week) {
  const milestones =
      <
        ({
          int from,
          int to,
          String id,
          String title,
          String subtitle,
          IconData icon,
          String action,
        })
      >[
        (
          from: 6,
          to: 10,
          id: 'first_anc',
          title: 'Book your first antenatal visit',
          subtitle: 'Your booking visit and dating scan are due about now',
          icon: Icons.event_available_rounded,
          action: 'booking first antenatal visit',
        ),
        (
          from: 11,
          to: 13,
          id: 'nt_scan',
          title: 'NT scan & first screening',
          subtitle: 'The 11–13 week scan — book it if you have not already',
          icon: Icons.monitor_heart_rounded,
          action: 'attending nt scan',
        ),
        (
          from: 18,
          to: 22,
          id: 'anomaly_scan',
          title: 'Anomaly scan',
          subtitle:
              'The 18–22 week scan checks how every part of baby is growing',
          icon: Icons.monitor_heart_rounded,
          action: 'attending anomaly scan',
        ),
        (
          from: 24,
          to: 28,
          id: 'glucose_test',
          title: 'Glucose tolerance test',
          subtitle: 'The sugar test is done between 24 and 28 weeks',
          icon: Icons.science_rounded,
          action: 'taking glucose test',
        ),
        (
          from: 29,
          to: 33,
          id: 'tdap',
          title: 'Tdap / TT vaccine',
          subtitle:
              'Ask your clinic — this one protects your baby after birth too',
          icon: Icons.vaccines_rounded,
          action: 'taking tdap vaccine',
        ),
        (
          from: 34,
          to: 35,
          id: 'hospital_bag',
          title: 'Pack your hospital bag',
          subtitle: 'Papers, clothes for you and baby, and your medicines',
          icon: Icons.luggage_rounded,
          action: 'packing hospital bag',
        ),
        (
          from: 36,
          to: 42,
          id: 'birth_plan',
          title: 'Birth plan & who drives you',
          subtitle: 'Settle the hospital, the route and who to call at night',
          icon: Icons.map_rounded,
          action: 'making birth plan',
        ),
      ];

  for (final milestone in milestones) {
    if (week < milestone.from || week > milestone.to) continue;
    return CareItem(
      id: milestone.id,
      title: milestone.title,
      subtitle: milestone.subtitle,
      icon: milestone.icon,
      color: const Color(0xff6C63FF),
      kind: CareActionKind.checkoff,
      actionValue: milestone.action,
    );
  }
  return null;
}

/// 1, 2 or 3 — clamped so a missing LMP still lands somewhere sensible.
int _trimesterFor(int pregnancyDay) {
  if (pregnancyDay <= 90) return 1;
  if (pregnancyDay <= 188) return 2;
  return 3;
}

CareItem _mealItem(
  CareMeal meal, {
  required String subtitle,
  required IconData icon,
  required Color color,
}) {
  return CareItem(
    id: 'meal_${meal.vitalKey}',
    title: meal.label,
    subtitle: subtitle,
    icon: icon,
    color: color,
    kind: CareActionKind.meal,
    meal: meal,
  );
}

CareItem _snackItem({required String subtitle}) {
  return CareItem(
    id: 'snack',
    title: 'Snack',
    subtitle: subtitle,
    icon: Icons.cookie_rounded,
    color: const Color(0xffF59E0B),
    kind: CareActionKind.count,
    countVitalKey: 'snacks',
    unitPlural: 'portions',
    unitSingular: 'portion',
    presets: const [1, 2],
    caloriesPerUnit: 150,
  );
}

CareItem _coffeeItem({required bool isPregnant}) {
  return CareItem(
    id: 'coffee',
    title: 'Coffee or tea',
    subtitle: isPregnant
        ? 'Keep caffeine under 2 cups a day while you are pregnant'
        : 'Log your cups — and switch to decaf after 4 PM',
    icon: Icons.coffee_rounded,
    color: const Color(0xff8D6E63),
    kind: CareActionKind.count,
    countVitalKey: 'drinks',
    unitPlural: 'cups',
    unitSingular: 'cup',
    presets: const [1, 2],
    caloriesPerUnit: 45,
  );
}

CareItem _waterItem({
  required CareDayPart part,
  required bool isPregnant,
  required int trimester,
}) {
  final target = !isPregnant
      ? 8
      : switch (trimester) {
          1 => 10,
          2 => 11,
          _ => 12,
        };

  final subtitle = switch (part) {
    CareDayPart.morning => 'Start the day with 2 glasses',
    CareDayPart.midMorning =>
      'Sip through the morning — aim for a glass an hour',
    CareDayPart.afternoon =>
      isPregnant
          ? 'Hydration supports your amniotic fluid'
          : 'Keep sipping through the afternoon',
    CareDayPart.evening =>
      'A couple more glasses before the evening winds down',
    CareDayPart.night => 'Top up now, then taper off before bed',
    CareDayPart.lateNight => 'Just a small glass so you are not up all night',
  };

  return CareItem(
    id: 'water',
    title: 'Drink water',
    subtitle: '$subtitle · goal $target glasses',
    icon: Icons.water_drop_rounded,
    color: infoCyan,
    kind: CareActionKind.count,
    countVitalKey: 'water',
    unitPlural: 'glasses',
    unitSingular: 'glass',
    dailyTarget: target,
    presets: const [1, 2, 3],
  );
}

/// The clock hour (0–23) an item sits at on the day's timeline.
///
/// Items are written per [CareDayPart], which is a window; the timeline needs
/// one hour for each, so this places them where the day actually puts them —
/// something dry on waking, breakfast at eight, folic acid after it, iron an
/// hour after lunch, calcium after dinner. Water and snacks recur through the
/// day, so the hour depends on the window as well as the item. Anything not
/// listed lands at the start of its window.
int careHourFor(String itemId, CareDayPart part) {
  final hour = switch ((part, itemId)) {
    (CareDayPart.morning, 'nausea_care') => 6,
    (CareDayPart.morning, 'water') => 7,
    (CareDayPart.morning, 'meal_breakfast') => 8,
    (CareDayPart.morning, 'folic_acid') => 9,
    (CareDayPart.morning, 'morning_movement') => 10,
    (CareDayPart.midMorning, 'snack') => 11,
    (CareDayPart.midMorning, 'water') => 12,
    (CareDayPart.midMorning, 'pelvic_floor') => 12,
    (CareDayPart.afternoon, 'meal_lunch') => 13,
    (CareDayPart.afternoon, 'iron_tablet') => 14,
    (CareDayPart.afternoon, 'water') => 15,
    (CareDayPart.afternoon, 'afternoon_rest') => 15,
    (CareDayPart.evening, 'coffee') => 17,
    (CareDayPart.evening, 'snack') => 17,
    (CareDayPart.evening, 'evening_walk') => 17,
    (CareDayPart.evening, 'kick_count') => 18,
    (CareDayPart.evening, 'swelling_check') => 18,
    (CareDayPart.evening, 'water') => 18,
    (CareDayPart.night, 'water') => 19,
    (CareDayPart.night, 'meal_dinner') => 20,
    (CareDayPart.night, 'calcium_tablet') => 21,
    (CareDayPart.night, 'labour_watch') => 21,
    (CareDayPart.lateNight, 'water') => 22,
    (CareDayPart.lateNight, 'stretch') => 22,
    (CareDayPart.lateNight, 'belly_care') => 22,
    (CareDayPart.lateNight, 'talk_to_baby') => 22,
    (CareDayPart.lateNight, 'perineal_massage') => 23,
    (CareDayPart.lateNight, 'left_side_sleep') => 23,
    (CareDayPart.lateNight, 'sleep') => 23,
    _ => null,
  };
  return hour ?? part.startHour;
}
