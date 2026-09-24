import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/my_health/vitals/drinks/drinks_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/meals/snacks_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/nutrition_routes.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_day_data.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_detail_page.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';

/// Calories one cup of tea or coffee is worth, matching Today's Care.
const int _kcalPerCup = 45;

const Color _breakfastColor = Color(0xFFFBBF24); // Amber
const Color _lunchColor = Color(0xFF10B981); // Emerald Teal
const Color _dinnerColor = Color(0xFF3B82F6); // Blue
const Color _snackColor = Color(0xFFF472B6); // Pink
const Color _drinksColor = Color(0xFFD97706); // Amber dark
const Color _waterColor = Color(0xFF06B6D4); // Cyan

/// "Daily Nutrition" on Home, laid out after AlloConnect's overview: the meal
/// that matters at this time of day leads, with water, snacks and drinks
/// around it.
///
/// A past day is a record, not a worksheet: it shows every meal and hides
/// every logging affordance. Logging uses Allomom's own sheets.
class NutritionOverviewSection extends StatefulWidget {
  /// Day the meals shown belong to. Defaults to today when omitted.
  final DateTime? date;

  const NutritionOverviewSection({super.key, this.date});

  @override
  State<NutritionOverviewSection> createState() =>
      _NutritionOverviewSectionState();
}

class _NutritionOverviewSectionState extends State<NutritionOverviewSection> {
  NutritionSummary _summary = NutritionSummary.empty(1);
  bool _isLoading = true;
  int _loadToken = 0;

  DateTime get _selectedDate => widget.date ?? DateTime.now();

  bool get _readOnly => !DateUtils.isSameDay(_selectedDate, DateTime.now());

  NutritionDay get _day => _summary.today;

  @override
  void initState() {
    super.initState();
    _load();
    HealthVitalsController.instance.addListener(_load);
  }

  @override
  void didUpdateWidget(covariant NutritionOverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDate = oldWidget.date ?? DateTime.now();
    if (!DateUtils.isSameDay(oldDate, _selectedDate)) _load();
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    final summary = await loadNutritionSummary(endDate: _selectedDate);
    if (!mounted || token != _loadToken) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  // ─── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;

    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hour = DateTime.now().hour;
    final isMorning = hour >= 5 && hour < 12;
    final isAfternoon = hour >= 12 && hour < 17;

    final List<Widget> cards;
    if (_readOnly) {
      // Every meal of the day, since the day is over.
      cards = [
        _row(
          _mealCard(CareMeal.breakfast, isWide: true),
          _waterCard(isCompact: true),
        ),
        const SizedBox(height: 12),
        _row(
          _mealCard(CareMeal.lunch, isWide: true),
          _snacksCard(),
        ),
        const SizedBox(height: 12),
        _row(
          _mealCard(CareMeal.dinner, isWide: true),
          _drinksCard(isWide: false),
        ),
      ];
    } else if (isMorning) {
      cards = [
        _row(
          _mealCard(CareMeal.breakfast, isWide: true),
          _waterCard(isCompact: true),
        ),
        const SizedBox(height: 12),
        _drinksCard(isWide: true),
      ];
    } else if (isAfternoon) {
      cards = [
        _row(
          _mealCard(CareMeal.lunch, isWide: true),
          _mealCard(CareMeal.breakfast, isWide: false),
        ),
        const SizedBox(height: 12),
        _row(_snacksCard(), _drinksCard(isWide: true), wideFirst: false),
        const SizedBox(height: 12),
        _waterCard(isCompact: false),
      ];
    } else {
      cards = [
        _row(
          _mealCard(CareMeal.dinner, isWide: true),
          _mealCard(CareMeal.lunch, isWide: false),
        ),
        const SizedBox(height: 12),
        _row(_snacksCard(), _drinksCard(isWide: true), wideFirst: false),
        const SizedBox(height: 12),
        _waterCard(isCompact: false),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Nutrition',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                  letterSpacing: -0.5,
                ),
              ),
              if (!_readOnly) _reminderButton(isDark),
            ],
          ),
        ),
        ...cards,
      ],
    );
  }

  /// A 2:1 row; [wideFirst] false puts the wide card on the right.
  Widget _row(Widget first, Widget second, {bool wideFirst = true}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: wideFirst ? 2 : 1, child: first),
          const SizedBox(width: 12),
          Expanded(flex: wideFirst ? 1 : 2, child: second),
        ],
      ),
    );
  }

  Widget _reminderButton(bool isDark) {
    return GestureDetector(
      onTap: () => speak(NarrationKeys.pgNutritionReminder, force: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFF3B82F6).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              size: 16,
              color: isDark ? Colors.white70 : const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 6),
            Text(
              'Set Reminder',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOGGING (Allomom's own sheets) ─────────────────────────

  String? _userIdOrNull() {
    final id = MainController.instance.userId.trim();
    return id.isEmpty ? null : id;
  }

  Future<void> _openDetail(NutritionMetric metric) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            nutritionOverviewScreen(metric, userId: _userIdOrNull()),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _logMeal(CareMeal meal) async {
    if (_readOnly) return;
    final saved = await showNutritionEntrySheet(
      context,
      _mealMetric(meal),
      userId: _userIdOrNull(),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _logWater(int glasses) async {
    if (_readOnly || glasses <= 0) return;
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
    await _load();
  }

  Future<void> _logSnacks() async {
    if (_readOnly) return;
    final saved = await showSnacksEntrySheet(context, userId: _userIdOrNull());
    if (saved == true && mounted) await _load();
  }

  Future<void> _logDrink(String name, IconData icon) async {
    if (_readOnly) return;
    final saved = await showDrinksEntrySheet(
      context,
      userId: _userIdOrNull(),
      initialType: name,
    );
    if (saved == true && mounted) await _load();
  }

  // ─── MEAL CARD ──────────────────────────────────────────────

  Color _mealColor(CareMeal meal) => switch (meal) {
        CareMeal.breakfast => _breakfastColor,
        CareMeal.lunch => _lunchColor,
        CareMeal.dinner => _dinnerColor,
      };

  IconData _mealIcon(CareMeal meal) => switch (meal) {
        CareMeal.breakfast => Icons.breakfast_dining_rounded,
        CareMeal.lunch => Icons.lunch_dining_rounded,
        CareMeal.dinner => Icons.dinner_dining_rounded,
      };

  NutritionMetric _mealMetric(CareMeal meal) => switch (meal) {
        CareMeal.breakfast => NutritionMetric.breakfast,
        CareMeal.lunch => NutritionMetric.lunch,
        CareMeal.dinner => NutritionMetric.dinner,
      };

  double _mealKcal(CareMeal meal) => switch (meal) {
        CareMeal.breakfast => _day.breakfastKcal,
        CareMeal.lunch => _day.lunchKcal,
        CareMeal.dinner => _day.dinnerKcal,
      };

  Widget _mealCard(CareMeal meal, {required bool isWide}) {
    final isDark = context.palette.isDark;
    final color = _mealColor(meal);
    final icon = _mealIcon(meal);
    final kcal = _mealKcal(meal);
    final hasData = kcal > 0;
    final details = _summary.todayMealNotes[meal.vitalKey] ?? '';

    return _shell(
      onTap: _readOnly
          ? () => _openDetail(_mealMetric(meal))
          : () => _showOptionsSheet(
                title: meal.label,
                subtitle: hasData
                    ? '${kcal.round()} kcal tracked today'
                    : 'No logs recorded for today',
                icon: icon,
                color: color,
                primaryLabel:
                    hasData ? 'Add to ${meal.label}' : 'Record ${meal.label}',
                onPrimary: () => _logMeal(meal),
                onDetails: () => _openDetail(_mealMetric(meal)),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconBubble(icon, color, size: 18),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasData
                        ? color.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasData ? 'Tracked' : 'Empty',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: hasData
                          ? color
                          : (isDark ? Colors.white30 : Colors.black38),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(meal.label, isDark),
              const SizedBox(height: 2),
              if (hasData)
                _kcalValue(kcal.round(), isDark)
              else
                _emptyText(isDark),
              if (isWide && hasData && details.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  details,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── SNACKS CARD ────────────────────────────────────────────

  Widget _snacksCard() {
    final isDark = context.palette.isDark;
    final count = _day.snackCount;
    final kcal = _day.snacksKcal;
    final hasData = count > 0 || kcal > 0;

    return _shell(
      onTap: _readOnly
          ? () => _openDetail(NutritionMetric.snacks)
          : () => _showOptionsSheet(
                title: 'Snacks',
                subtitle: hasData
                    ? '${kcal.round()} kcal ($count ${count == 1 ? 'snack' : 'snacks'}) logged today'
                    : 'No snack logs recorded for today',
                icon: Icons.cookie_rounded,
                color: _snackColor,
                primaryLabel: 'Record Another Snack',
                onPrimary: _logSnacks,
                onDetails: () => _openDetail(NutritionMetric.snacks),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconBubble(Icons.cookie_rounded, _snackColor),
              if (!_readOnly) _plusButton(_snackColor, _logSnacks),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Snacks', isDark),
              const SizedBox(height: 2),
              if (hasData) ...[
                _kcalValue(kcal.round(), isDark),
                const SizedBox(height: 4),
                Text(
                  count == 1 ? '1 snack' : '$count snacks',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _snackColor,
                  ),
                ),
              ] else ...[
                _emptyText(isDark),
                const SizedBox(height: 4),
                Text(
                  _readOnly ? '0 times' : '0 times today',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── WATER CARD ─────────────────────────────────────────────

  Widget _waterCard({required bool isCompact}) {
    final isDark = context.palette.isDark;
    final glasses = _day.waterGlasses;
    final goal = waterGoalGlasses();
    final ml = glasses * kGlassMl;
    final goalMl = goal * kGlassMl;
    final progress = goal > 0 ? (glasses / goal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    void openWater() => _openDetail(NutritionMetric.water);

    if (isCompact) {
      return _shell(
        onTap: openWater,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconBubble(Icons.local_drink_rounded, _waterColor),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _waterColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$glasses gls',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: _waterColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$glasses',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'gls',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$ml ml',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.04),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_waterColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_readOnly)
              GestureDetector(
                onTap: () => _logWater(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _waterColor.withValues(alpha: isDark ? 0.22 : 0.15),
                        _waterColor.withValues(alpha: isDark ? 0.12 : 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _waterColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_drink_rounded,
                        size: 12,
                        color: _waterColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '+1 Glass',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : _waterColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Wide layout: one indicator per glass of the day's goal.
    return _shell(
      onTap: openWater,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconBubble(Icons.local_drink_rounded, _waterColor),
                  const SizedBox(width: 8),
                  _label(_readOnly ? 'Water' : 'Water Today', isDark),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _waterColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _waterColor.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.water_drop_rounded,
                      size: 10,
                      color: _waterColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$glasses / $goal glasses',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _waterColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$glasses',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                glasses == 1 ? 'glass' : 'glasses',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '($ml / $goalMl ml)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _waterColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(goal, (index) {
              final isFilled = glasses > index;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < goal - 1 ? 4 : 0),
                  height: 22,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? _waterColor.withValues(alpha: 0.22)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isFilled
                          ? _waterColor.withValues(alpha: 0.55)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05)),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_drink_rounded,
                      size: 11,
                      color: isFilled
                          ? _waterColor
                          : (isDark ? Colors.white24 : Colors.black26),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (!_readOnly) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _logWater(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _waterColor.withValues(alpha: isDark ? 0.22 : 0.15),
                            _waterColor.withValues(alpha: isDark ? 0.12 : 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _waterColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: _waterColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 11,
                              color: _waterColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_drink_rounded,
                            size: 14,
                            color: _waterColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+1 Glass',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : _waterColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${kGlassMl}ml)',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _waterColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _logWater(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+${kGlassMl * 2}ml',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── DRINKS CARD ────────────────────────────────────────────

  /// Names match what Today's Care writes into `data['drink']`.
  static const _drinkOptions = <({String name, IconData icon})>[
    (name: 'Tea', icon: Icons.emoji_food_beverage_rounded),
    (name: 'Coffee', icon: Icons.coffee_rounded),
    (name: 'Other', icon: Icons.local_drink_rounded),
  ];

  Color _drinkShade(String name) => switch (name) {
        'Tea' => Colors.orange.shade600,
        'Coffee' => Colors.brown.shade400,
        _ => Colors.blue.shade500,
      };

  Widget _drinksCard({required bool isWide}) {
    final isDark = context.palette.isDark;
    final counts = _summary.todayDrinkCounts;
    final total = _day.drinkCount;

    void openDrinks() => _openDetail(NutritionMetric.drinks);

    if (!isWide) {
      return _shell(
        onTap: _readOnly ? openDrinks : _showDrinkPicker,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: openDrinks,
                  child: _iconBubble(Icons.coffee_rounded, _drinksColor),
                ),
                if (!_readOnly) _plusButton(_drinksColor, _showDrinkPicker),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Drinks', isDark),
                const SizedBox(height: 2),
                Text(
                  total > 0
                      ? '$total ${total == 1 ? 'drink' : 'drinks'}'
                      : (_readOnly ? 'Not logged' : 'Tap to track'),
                  style: GoogleFonts.manrope(
                    fontSize: total > 0 ? 18 : 12,
                    fontWeight: FontWeight.w800,
                    color: total > 0
                        ? (isDark ? Colors.white : const Color(0xFF1B1C1A))
                        : (isDark ? Colors.white30 : Colors.black38),
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final d in _drinkOptions)
                        if ((counts[d.name] ?? 0) > 0) ...[
                          Icon(d.icon, size: 12, color: _drinkShade(d.name)),
                          const SizedBox(width: 2),
                        ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    final tagged = _drinkOptions.where((d) => (counts[d.name] ?? 0) > 0);

    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: openDrinks,
                child: Row(
                  children: [
                    _iconBubble(Icons.coffee_rounded, _drinksColor),
                    const SizedBox(width: 8),
                    _label('Drinks (Hot/Cold)', isDark),
                  ],
                ),
              ),
              if (!_readOnly)
                _plusButton(_drinksColor, _showDrinkPicker, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          if (!_readOnly)
            Row(
              children: [
                for (var i = 0; i < _drinkOptions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _quickDrinkButton(
                      label: _drinkOptions[i].name,
                      icon: _drinkOptions[i].icon,
                      color: _drinkShade(_drinkOptions[i].name),
                      count: counts[_drinkOptions[i].name] ?? 0,
                      onTap: () => _logDrink(
                        _drinkOptions[i].name,
                        _drinkOptions[i].icon,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          if (tagged.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final d in tagged)
                  _countTag('${d.name}: ${counts[d.name]}', _drinkShade(d.name)),
              ],
            ),
          ] else if (_readOnly)
            _emptyText(isDark),
        ],
      ),
    );
  }

  Widget _quickDrinkButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int count = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$_kcalPerCup kcal',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.card, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _countTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ─── SHEETS ─────────────────────────────────────────────────

  /// AlloConnect's small chooser: log now, or go to the full history.
  void _showOptionsSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String primaryLabel,
    required VoidCallback onPrimary,
    required VoidCallback onDetails,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = sheetContext.palette.isDark;
        return _sheetFrame(
          sheetContext,
          children: [
            _sheetHeader(sheetContext, title, subtitle, icon, color),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onPrimary();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  primaryLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onDetails();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'View History & Trends',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.87)
                        : Colors.black.withValues(alpha: 0.87),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Which drink to log, from the card's "+".
  void _showDrinkPicker() {
    if (_readOnly) return;
    final total = _day.drinkCount;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _sheetFrame(
          sheetContext,
          children: [
            _sheetHeader(
              sheetContext,
              'Drinks',
              total > 0
                  ? '$total ${total == 1 ? 'cup' : 'cups'} · ${_day.drinksKcal.round()} kcal logged today'
                  : 'No drinks recorded for today',
              Icons.coffee_rounded,
              _drinksColor,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                for (var i = 0; i < _drinkOptions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _quickDrinkButton(
                      label: _drinkOptions[i].name,
                      icon: _drinkOptions[i].icon,
                      color: _drinkShade(_drinkOptions[i].name),
                      count:
                          _summary.todayDrinkCounts[_drinkOptions[i].name] ?? 0,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _logDrink(
                          _drinkOptions[i].name,
                          _drinkOptions[i].icon,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openDetail(NutritionMetric.drinks);
                },
                child: Text(
                  'View History & Trends',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _drinksColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sheetFrame(BuildContext sheetContext, {required List<Widget> children}) {
    final isDark = sheetContext.palette.isDark;
    return Container(
      decoration: BoxDecoration(
        color: sheetContext.palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(sheetContext).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _sheetHeader(
    BuildContext sheetContext,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isDark = sheetContext.palette.isDark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SMALL PIECES ───────────────────────────────────────────

  Widget _shell({VoidCallback? onTap, required Widget child}) {
    final isDark = context.palette.isDark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _iconBubble(IconData icon, Color color, {double size = 16}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _plusButton(Color color, VoidCallback onTap, {double size = 12}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add_rounded, color: color, size: size),
      ),
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _kcalValue(int kcal, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$kcal',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1B1C1A),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          'kcal',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _emptyText(bool isDark) {
    return Text(
      _readOnly ? 'Not logged' : 'Tap to track',
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white30 : Colors.black38,
      ),
    );
  }
}
