import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_day_data.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_detail_page.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_count_sheet.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';

/// Calories one cup of tea or coffee is worth, matching Today's Care.
const int _kcalPerCup = 45;

/// Calories one snack portion is worth, matching Today's Care.
const int _kcalPerSnack = 150;

class NutritionOverviewSection extends StatefulWidget {
  const NutritionOverviewSection({super.key});

  @override
  State<NutritionOverviewSection> createState() =>
      _NutritionOverviewSectionState();
}

class _NutritionOverviewSectionState extends State<NutritionOverviewSection> {
  NutritionSummary _summary = NutritionSummary.empty(1);

  @override
  void initState() {
    super.initState();
    _load();
    HealthVitalsController.instance.addListener(_load);
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final summary = await loadNutritionSummary();
    if (!mounted) return;
    setState(() => _summary = summary);
  }

  NutritionDay get _today => _summary.today;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Nutrition',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1C1A),
                letterSpacing: -0.5,
              ),
            ),
            GestureDetector(
              onTap: () =>
                  speak(NarrationKeys.pgNutritionReminder, force: true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Set Reminder',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Breakfast & Water Row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildMealCardItem(
                  meal: CareMeal.breakfast,
                  metric: NutritionMetric.breakfast,
                  icon: Icons.breakfast_dining_rounded,
                  color: const Color(0xFFFBBF24),
                  kcal: _today.breakfastKcal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildWaterCardItem()),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Lunch & Snacks Row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildMealCardItem(
                  meal: CareMeal.lunch,
                  metric: NutritionMetric.lunch,
                  icon: Icons.lunch_dining_rounded,
                  color: const Color(0xFF10B981),
                  kcal: _today.lunchKcal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildSnacksCardItem()),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dinner
        _buildMealCardItem(
          meal: CareMeal.dinner,
          metric: NutritionMetric.dinner,
          icon: Icons.dinner_dining_rounded,
          color: const Color(0xFF8B5CF6),
          kcal: _today.dinnerKcal,
        ),
        const SizedBox(height: 12),

        // Drinks Card (Hot/Cold)
        _buildDrinksOverviewCard(),
      ],
    );
  }

  // ─── LOGGING ─────────────────────────────────────────────────

  String? _userIdOrNull() {
    final id = MainController.instance.userId.trim();
    return id.isEmpty ? null : id;
  }

  Future<void> _afterLog() => _load();

  /// Opens a card's own detail page — its trend, its numbers, its entries.
  Future<void> _openDetail(NutritionMetric metric) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NutritionDetailPage(metric: metric)),
    );
    if (mounted) await _afterLog();
  }

  Future<void> _logMeal(CareMeal meal, Color color, IconData icon) async {
    final log = await CareMealSheet.show(
      context,
      meal: meal,
      color: color,
      icon: icon,
    );
    if (log == null) return;

    await HealthVitalsController.instance.addVitalEntry(
      key: meal.vitalKey,
      value: log.calories,
      unit: 'kcal',
      createdAt: DateTime.now(),
      userId: _userIdOrNull(),
      data: {'items': log.details, 'meal': meal.label},
    );
    await _afterLog();
  }

  Future<void> _logWater(int glasses) async {
    if (glasses <= 0) return;
    await HealthVitalsController.instance.addVitalEntry(
      key: 'water',
      value: glasses.toDouble(),
      unit: 'glasses',
      createdAt: DateTime.now(),
      userId: _userIdOrNull(),
      data: {
        'details': '$glasses ${glasses == 1 ? 'glass' : 'glasses'}',
        'type': 'water',
        'count': glasses,
        'count_unit': 'glasses',
      },
    );
    speak(NarrationKeys.pgConfWaterAdded, force: true);
    await _afterLog();
  }

  Future<void> _logSnacks() async {
    final amount = await CareCountSheet.show(
      context,
      title: 'Log a snack',
      unitLabel: 'portions',
      unitLabelSingular: 'portion',
      icon: Icons.cookie_rounded,
      color: const Color(0xFFF472B6),
      loggedToday: _today.snackCount,
      presets: const [1, 2],
      subtitle: 'About $_kcalPerSnack kcal a portion',
      narrationKey: NarrationKeys.pgNutritionSnacks,
    );
    if (amount == null || amount <= 0) return;

    await HealthVitalsController.instance.addVitalEntry(
      key: 'snacks',
      value: (amount * _kcalPerSnack).toDouble(),
      unit: 'kcal',
      createdAt: DateTime.now(),
      userId: _userIdOrNull(),
      data: {
        'details': '$amount ${amount == 1 ? 'portion' : 'portions'}',
        'type': 'snacks',
        'count': amount,
        'count_unit': 'portions',
      },
    );
    await _afterLog();
  }

  Future<void> _logDrink(String name, IconData icon) async {
    final amount = await CareCountSheet.show(
      context,
      title: 'Log $name',
      unitLabel: 'cups',
      unitLabelSingular: 'cup',
      icon: icon,
      color: const Color(0xFFF59E0B),
      loggedToday: _summary.todayDrinkCounts[name] ?? 0,
      presets: const [1, 2],
      subtitle: 'About $_kcalPerCup kcal a cup',
    );
    if (amount == null || amount <= 0) return;

    await HealthVitalsController.instance.addVitalEntry(
      key: 'drinks',
      value: (amount * _kcalPerCup).toDouble(),
      unit: 'kcal',
      createdAt: DateTime.now(),
      userId: _userIdOrNull(),
      data: {
        'details': '$amount ${amount == 1 ? 'cup' : 'cups'} of $name',
        'type': 'drinks',
        'drink': name,
        'count': amount,
        'count_unit': 'cups',
      },
    );
    await _afterLog();
  }

  // ─── CARDS ───────────────────────────────────────────────────

  Widget _buildMealCardItem({
    required CareMeal meal,
    required NutritionMetric metric,
    required IconData icon,
    required Color color,
    required double kcal,
  }) {
    final logged = kcal > 0;
    final note = _summary.todayMealNotes[meal.vitalKey];

    return GestureDetector(
      onTap: () => _openDetail(metric),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                // The card opens the trend; the badge is the quick log.
                GestureDetector(
                  onTap: () => _logMeal(meal, color, icon),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: logged ? 0.1 : 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 11, color: color),
                        const SizedBox(width: 2),
                        Text(
                          logged ? '${kcal.round()} kcal' : 'Log',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meal.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1C1A),
              ),
            ),
            Text(
              note != null && note.isNotEmpty
                  ? note
                  : (logged ? 'Logged today' : 'Not logged yet'),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: logged ? Colors.black45 : Colors.black26,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterCardItem() {
    const color = Color(0xFF06B6D4);
    final glasses = _today.waterGlasses;
    final goal = waterGoalGlasses();
    final ml = glasses * kGlassMl;
    final percent = ((glasses / goal) * 100).clamp(0, 999).toInt();

    return GestureDetector(
      onTap: () => _openDetail(NutritionMetric.water),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
                Text(
                  '$percent%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: glasses > 0 ? color : Colors.black26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$ml ml',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: glasses > 0
                    ? const Color(0xFF1B1C1A)
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ),
            Text(
              '$glasses of $goal glasses',
              style: GoogleFonts.inter(fontSize: 9.5, color: Colors.black38),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _logWater(1),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '+${kGlassMl}ml',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnacksCardItem() {
    const color = Color(0xFFF472B6);
    final kcal = _today.snacksKcal;
    final count = _today.snackCount;
    final logged = count > 0;

    return GestureDetector(
      onTap: () => _openDetail(NutritionMetric.snacks),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cookie_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
                GestureDetector(
                  onTap: _logSnacks,
                  child: const Icon(Icons.add_rounded, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Snacks',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            Text(
              logged ? '${kcal.round()} kcal' : '-- kcal',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: logged
                    ? const Color(0xFF1B1C1A)
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ),
            Text(
              logged
                  ? '$count ${count == 1 ? 'snack' : 'snacks'} today'
                  : 'Tap to log',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: logged ? color : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrinksOverviewCard() {
    final drinks = <({IconData icon, String name, Color tint})>[
      (icon: Icons.local_cafe, name: 'Tea', tint: const Color(0xFFFFF8E1)),
      (icon: Icons.coffee, name: 'Coffee', tint: const Color(0xFFF5F5F5)),
      (icon: Icons.local_drink, name: 'Other', tint: const Color(0xFFE3F2FD)),
    ];

    final cups = _today.drinkCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openDetail(NutritionMetric.drinks),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_cafe,
                          color: Colors.orange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Drinks (Hot/Cold)',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1C1A),
                              ),
                            ),
                            Text(
                              cups > 0
                                  ? '$cups ${cups == 1 ? 'cup' : 'cups'} · ${_today.drinksKcal.round()} kcal today'
                                  : 'Nothing logged today',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: cups > 0
                                    ? Colors.black45
                                    : Colors.black26,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFFB4BAC6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: drinks.map((d) {
              final count = _summary.todayDrinkCounts[d.name] ?? 0;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _logDrink(d.name, d.icon),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: d.tint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(d.icon, size: 22, color: Colors.grey.shade700),
                        const SizedBox(height: 6),
                        Text(
                          d.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textMedium,
                          ),
                        ),
                        Text(
                          count > 0
                              ? '$count ${count == 1 ? 'cup' : 'cups'}'
                              : 'Tap to log',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
