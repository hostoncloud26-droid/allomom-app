import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_day_data.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_count_sheet.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';
import 'package:allomom/models/vitals_stream_model.dart';

/// Which of the Daily Nutrition cards a detail page is showing.
enum NutritionMetric {
  breakfast,
  lunch,
  dinner,
  snacks,
  drinks,
  water;

  /// Vital key this metric is stored under.
  String get vitalKey => switch (this) {
        NutritionMetric.breakfast => 'breakfast',
        NutritionMetric.lunch => 'lunch',
        NutritionMetric.dinner => 'dinner',
        NutritionMetric.snacks => 'snacks',
        NutritionMetric.drinks => 'drinks',
        NutritionMetric.water => 'water',
      };

  /// Alias written by earlier builds, which readers must also check.
  String? get legacyVitalKey =>
      this == NutritionMetric.breakfast ? 'break_fast' : null;

  String get label => switch (this) {
        NutritionMetric.breakfast => 'Breakfast',
        NutritionMetric.lunch => 'Lunch',
        NutritionMetric.dinner => 'Dinner',
        NutritionMetric.snacks => 'Snacks',
        NutritionMetric.drinks => 'Drinks',
        NutritionMetric.water => 'Water',
      };

  /// The meal this maps to, when it is one; snacks, drinks and water are counts.
  CareMeal? get meal => switch (this) {
        NutritionMetric.breakfast => CareMeal.breakfast,
        NutritionMetric.lunch => CareMeal.lunch,
        NutritionMetric.dinner => CareMeal.dinner,
        _ => null,
      };

  /// What the vital's value means: kcal for food, glasses for water.
  String get unit => this == NutritionMetric.water ? 'glasses' : 'kcal';

  Color get color => switch (this) {
        NutritionMetric.breakfast => const Color(0xFFFBBF24),
        NutritionMetric.lunch => const Color(0xFF10B981),
        NutritionMetric.dinner => const Color(0xFF8B5CF6),
        NutritionMetric.snacks => const Color(0xFFF472B6),
        NutritionMetric.drinks => const Color(0xFFF59E0B),
        NutritionMetric.water => const Color(0xFF06B6D4),
      };

  Color get tint => switch (this) {
        NutritionMetric.breakfast => const Color(0xFFFFFBEB),
        NutritionMetric.lunch => const Color(0xFFE6F9F0),
        NutritionMetric.dinner => const Color(0xFFF5F3FF),
        NutritionMetric.snacks => const Color(0xFFFDF2F8),
        NutritionMetric.drinks => const Color(0xFFFFF8E1),
        NutritionMetric.water => const Color(0xFFE0F2FE),
      };

  IconData get icon => switch (this) {
        NutritionMetric.breakfast => Icons.breakfast_dining_rounded,
        NutritionMetric.lunch => Icons.lunch_dining_rounded,
        NutritionMetric.dinner => Icons.dinner_dining_rounded,
        NutritionMetric.snacks => Icons.cookie_rounded,
        NutritionMetric.drinks => Icons.local_cafe_rounded,
        NutritionMetric.water => Icons.water_drop_rounded,
      };

  /// Calories one portion or cup is worth, for the count-based metrics.
  int? get caloriesPerUnit => switch (this) {
        NutritionMetric.snacks => 150,
        NutritionMetric.drinks => 45,
        _ => null,
      };

  String get unitPlural => switch (this) {
        NutritionMetric.snacks => 'portions',
        NutritionMetric.drinks => 'cups',
        NutritionMetric.water => 'glasses',
        _ => 'kcal',
      };

  String get unitSingular => switch (this) {
        NutritionMetric.snacks => 'portion',
        NutritionMetric.drinks => 'cup',
        NutritionMetric.water => 'glass',
        _ => 'kcal',
      };

  /// Daily goal for the chart's reference line, when the metric has one.
  double? get dailyGoal => switch (this) {
        NutritionMetric.water => waterGoalGlasses().toDouble(),
        NutritionMetric.breakfast => 400,
        NutritionMetric.lunch => 600,
        NutritionMetric.dinner => 550,
        _ => null,
      };

  String get speechText => switch (this) {
        NutritionMetric.water =>
          "Sip through the day, Amma. I'll keep count for you.",
        NutritionMetric.snacks =>
          "Small, steady snacks keep us both going, Amma.",
        NutritionMetric.drinks =>
          "Tell me what you drank and I'll note it down, Amma.",
        _ => "Tell me what you ate, Amma, and I'll note it down.",
      };
}

/// A full-page view of one nutrition card: its trend over the day, week or
/// month, the numbers behind it, and everything logged in the period.
///
/// Built to read like the vitals detail pages (Sleep, HRV and the rest) so a
/// chart means the same thing wherever it appears.
class NutritionDetailPage extends StatefulWidget {
  const NutritionDetailPage({super.key, required this.metric});

  final NutritionMetric metric;

  @override
  State<NutritionDetailPage> createState() => _NutritionDetailPageState();
}

class _NutritionDetailPageState extends State<NutritionDetailPage> {
  String _selectedTab = 'Day';

  NutritionMetric get _metric => widget.metric;

  /// Every row for this metric in the chosen period, oldest first.
  List<VitalsStreamResponse> get _history {
    final vitals = HealthVitalsController.instance;
    final rows = [
      ...vitals.getHistoryForPeriod(_metric.vitalKey, _selectedTab),
      if (_metric.legacyVitalKey != null)
        ...vitals.getHistoryForPeriod(_metric.legacyVitalKey!, _selectedTab),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return rows;
  }

  /// Water is logged as +1 and -1 increments, so a correction must not draw a
  /// column of its own.
  List<VitalsStreamResponse> get _plottable =>
      _history.where((r) => r.value > 0).toList();

  double get _periodTotal =>
      _history.fold(0.0, (sum, r) => sum + r.value);

  /// Portions or cups behind the calories; rows written elsewhere carry no
  /// count, so they stand for one unit.
  int get _periodUnits {
    if (_metric.caloriesPerUnit == null) return _history.length;
    return _history.fold(0, (sum, r) {
      final recorded = r.data?['count'];
      final parsed = recorded is num
          ? recorded.round()
          : int.tryParse(recorded?.toString() ?? '');
      return sum + (parsed ?? 1);
    });
  }

  int get _daysInPeriod => switch (_selectedTab) {
        'Week' => 7,
        'Month' => 30,
        _ => 1,
      };

  /// How many days in the period actually hold an entry.
  int get _daysLogged {
    final seen = <String>{};
    for (final row in _history) {
      seen.add(DateFormat('yyyy-MM-dd').format(row.createdAt));
    }
    return seen.length;
  }

  Future<void> _openLogSheet() async {
    final meal = _metric.meal;
    if (meal != null) {
      final log = await CareMealSheet.show(
        context,
        meal: meal,
        color: _metric.color,
        icon: _metric.icon,
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
      if (mounted) setState(() {});
      return;
    }

    final perUnit = _metric.caloriesPerUnit;
    final amount = await CareCountSheet.show(
      context,
      title: 'Log ${_metric.label.toLowerCase()}',
      unitLabel: _metric.unitPlural,
      unitLabelSingular: _metric.unitSingular,
      icon: _metric.icon,
      color: _metric.color,
      loggedToday: _todayUnits(),
      target: _metric == NutritionMetric.water ? waterGoalGlasses() : null,
      presets: const [1, 2, 3],
      subtitle: perUnit != null
          ? 'About $perUnit kcal a ${_metric.unitSingular}'
          : 'One glass is about $kGlassMl ml',
    );
    if (amount == null || amount <= 0) return;

    await HealthVitalsController.instance.addVitalEntry(
      key: _metric.vitalKey,
      value: perUnit == null ? amount.toDouble() : (amount * perUnit).toDouble(),
      unit: perUnit == null ? _metric.unitPlural : 'kcal',
      createdAt: DateTime.now(),
      userId: _userIdOrNull(),
      data: {
        'details':
            '$amount ${amount == 1 ? _metric.unitSingular : _metric.unitPlural}',
        'type': _metric.vitalKey,
        'count': amount,
        'count_unit': _metric.unitPlural,
      },
    );
    if (mounted) setState(() {});
  }

  int _todayUnits() {
    final today = DateTime.now();
    var total = 0;
    for (final row in HealthVitalsController.instance
        .getHistoryForPeriod(_metric.vitalKey, 'Day')) {
      if (row.createdAt.day != today.day) continue;
      final recorded = row.data?['count'];
      final parsed = recorded is num
          ? recorded.round()
          : int.tryParse(recorded?.toString() ?? '');
      total += parsed ?? (_metric.caloriesPerUnit == null ? row.value.round() : 1);
    }
    return total < 0 ? 0 : total;
  }

  String? _userIdOrNull() {
    final id = MainController.instance.userId.trim();
    return id.isEmpty ? null : id;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [MainController.instance, HealthVitalsController.instance]),
      builder: (context, child) {
        final week = MainController.instance.currentGestationalWeek;

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBFBFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF2D3142),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _metric.label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: Icon(Icons.add_rounded, size: 18, color: _metric.color),
                label: Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _metric.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: _metric.color,
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Log ${_metric.label}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── FIXED TOP SECTION (Baby Hero Card & Period Tabs) ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Column(
                  children: [
                    BabyHeroBanner(
                      speechText: "Week $week, Amma!\n${_metric.speechText}",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 250,
                      greetingText: "",
                    ),
                    const SizedBox(height: 14),
                    _buildPeriodTabs(),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ─── SCROLLABLE BOTTOM SECTION (After the tab) ───
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainChartCard(),
                      const SizedBox(height: 16),
                      _buildBottomStatsRow(),
                      const SizedBox(height: 16),
                      _buildEntriesCard(),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
      ),
      child: Row(
        children: ['Day', 'Week', 'Month'].map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _metric.tint : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? _metric.color : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainChartCard() {
    final now = DateTime.now();
    final String headerTitle;
    final String dateRangeText;

    if (_selectedTab == 'Day') {
      headerTitle = 'TODAY';
      dateRangeText = DateFormat('EEE, dd MMM yyyy').format(now);
    } else if (_selectedTab == 'Week') {
      headerTitle = 'THIS WEEK';
      final start = now.subtract(const Duration(days: 6));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
    } else {
      headerTitle = 'THIS MONTH';
      final start = now.subtract(const Duration(days: 29));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
    }

    final goal = _metric.dailyGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                headerTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                dateRangeText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          VitalTrendChart(
            period: _selectedTab,
            accent: _metric.color,
            // Glasses need a singular, so water spells the amount out in the
            // formatter and leaves the trailing unit empty.
            unit: _metric == NutritionMetric.water ? '' : _metric.unit,
            valueFormatter: _metric == NutritionMetric.water
                ? (v) => '${v.round()} ${v.round() == 1 ? 'glass' : 'glasses'}'
                : null,
            bars: true,
            // Entries add up within a day — two snacks are two snacks.
            aggregate: VitalAggregate.sum,
            minY: 0,
            // The goal is a daily one, so it only frames a per-day chart.
            bands: goal != null && _selectedTab != 'Day'
                ? [
                    VitalBand(
                      min: goal * 0.9,
                      max: goal * 1.1,
                      color: _metric.color.withValues(alpha: 0.07),
                    ),
                  ]
                : const [],
            emptyTitle: 'No ${_metric.label.toLowerCase()} logged',
            emptySubtitle: 'Tap "Log ${_metric.label}" to add one',
            series: [
              VitalSeries.fromHistory(
                label: _metric.label,
                color: _metric.color,
                history: _plottable,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    final logged = _history.isNotEmpty;
    final isWater = _metric == NutritionMetric.water;
    final total = _periodTotal;

    // Averaged over the days that were actually logged, so a quiet week does
    // not drag the number down to something meaningless.
    final perDay = _daysLogged == 0 ? 0.0 : total / _daysLogged;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: _selectedTab == 'Day' ? 'Today' : '$_selectedTab total',
            value: logged
                ? (isWater ? total.round().toString() : total.round().toString())
                : '--',
            unit: isWater ? 'glasses' : 'kcal',
            subtitle: isWater && logged ? '${(total * kGlassMl).round()} ml' : '',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: _selectedTab == 'Day' ? 'Entries' : 'Daily average',
            value: _selectedTab == 'Day'
                ? (logged ? '$_periodUnits' : '--')
                : (logged ? perDay.round().toString() : '--'),
            // On Day this tile counts what was logged, so it is portions or
            // cups where those are the unit, and plain entries otherwise.
            unit: _selectedTab == 'Day'
                ? (_metric.caloriesPerUnit != null
                    ? _metric.unitPlural
                    : (_periodUnits == 1 ? 'entry' : 'entries'))
                : (isWater ? 'glasses' : 'kcal'),
            subtitle: _selectedTab == 'Day' ? '' : 'on days logged',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: _selectedTab == 'Day' ? 'Goal' : 'Days logged',
            value: _selectedTab == 'Day'
                ? (_metric.dailyGoal?.round().toString() ?? '--')
                : '$_daysLogged',
            unit: _selectedTab == 'Day'
                ? (isWater ? 'glasses' : 'kcal')
                : 'of $_daysInPeriod',
            subtitle: '',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required String subtitle,
  }) {
    final empty = value == '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E95A5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: empty ? const Color(0xFFB4BAC6) : const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E95A5),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFFB4BAC6)),
            ),
          ],
        ],
      ),
    );
  }

  /// What was logged in the period, newest first — the numbers behind the chart.
  Widget _buildEntriesCard() {
    final entries = _history.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedTab == 'Day' ? "Today's entries" : 'Recent entries',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Nothing logged in this period yet.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            )
          else
            for (final entry in entries.take(10)) _buildEntryRow(entry),
        ],
      ),
    );
  }

  Widget _buildEntryRow(VitalsStreamResponse row) {
    final isCorrection = row.value < 0;
    final note = (row.data?['items'] ?? row.data?['details'])?.toString().trim();
    final when = _selectedTab == 'Day'
        ? DateFormat('h:mm a').format(row.createdAt)
        : DateFormat('dd MMM · h:mm a').format(row.createdAt);

    final amount = _metric == NutritionMetric.water
        ? '${row.value.abs().round()} ${row.value.abs() == 1 ? 'glass' : 'glasses'}'
        : '${row.value.abs().round()} kcal';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: _metric.tint, shape: BoxShape.circle),
            child: Icon(
              isCorrection ? Icons.remove_rounded : _metric.icon,
              size: 16,
              color: _metric.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note != null && note.isNotEmpty
                      ? note
                      : (isCorrection ? 'Correction' : _metric.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                Text(
                  when,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            isCorrection ? '-$amount' : amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isCorrection ? const Color(0xFF8E95A5) : _metric.color,
            ),
          ),
        ],
      ),
    );
  }
}
