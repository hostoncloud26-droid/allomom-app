import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

import 'nutrition/health_tile_parts.dart';

/// Keys whose value is kcal eaten or drunk.
const List<String> _intakeKeys = [
  'food',
  'breakfast',
  'break_fast',
  'lunch',
  'dinner',
  'snacks',
  'drinks',
];

/// AlloConnect's "Calories" balance tile: kcal in vs. kcal out (BMR + activity
/// + the extra energy pregnancy needs) for [date], with the net balance, a
/// progress track and a one-line insight.
///
/// [date] defaults to today; [stepsForDate] overrides the day's step count.
class CaloriesTrackerTile extends StatefulWidget {
  final String? userId;

  /// Day the balance is computed for. Defaults to today when omitted.
  final DateTime? date;

  /// Steps recorded on [date]. Falls back to that day's stored steps.
  final int? stepsForDate;

  const CaloriesTrackerTile({
    super.key,
    this.userId,
    this.date,
    this.stepsForDate,
  });

  @override
  State<CaloriesTrackerTile> createState() => _CaloriesTrackerTileState();
}

class _CaloriesTrackerTileState extends State<CaloriesTrackerTile>
    with SingleTickerProviderStateMixin {
  double _consumedCalories = 0.0;
  double _workoutMinutes = 0.0;

  /// Past-day readings (steps, weight, height); null for today.
  int? _pastSteps;
  double? _pastWeight;
  double? _pastHeight;

  int _loadSeq = 0;

  late final AnimationController _mainController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );
  late final Animation<double> _scaleAnimation =
      Tween<double>(begin: 0.9, end: 1.0).animate(
    CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
  );

  DateTime get _selectedDate => widget.date ?? DateTime.now();
  bool get _isToday => DateUtils.isSameDay(_selectedDate, DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadCalories();
    HealthVitalsController.instance.addListener(_loadCalories);
    _mainController.forward();
  }

  @override
  void didUpdateWidget(covariant CaloriesTrackerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        !DateUtils.isSameDay(oldWidget.date ?? DateTime.now(), _selectedDate)) {
      _loadCalories();
    }
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_loadCalories);
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _loadCalories() async {
    if (!mounted) return;
    final seq = ++_loadSeq;
    final isToday = _isToday;
    try {
      final targetUserId = widget.userId ?? MainController.instance.userId;
      final bounds = dayBounds(_selectedDate);
      final service = VitalsSqLiteService();

      Future<double> sum(List<String> keys) async {
        final lists = await Future.wait([
          for (final k in keys)
            service.getVitalsHistory(
              targetUserId,
              k,
              fromDate: bounds.start,
              toDate: bounds.end,
            ),
        ]);
        var total = 0.0;
        for (final rows in lists) {
          for (final r in rows) {
            total += (r['value'] as num?)?.toDouble() ?? 0.0;
          }
        }
        return total;
      }

      final food = await sum(_intakeKeys);
      final workout = await sum(const ['workout', 'exercise']);
      // Past days: that day's steps, and weight / height as they stood then.
      double? latestValue(List<Map<String, dynamic>> rows) =>
          rows.isEmpty ? null : (rows.first['value'] as num?)?.toDouble();
      final past = isToday
          ? null
          : await Future.wait([
              service.getVitalsHistory(
                targetUserId,
                'steps',
                fromDate: bounds.start,
                toDate: bounds.end,
              ),
              service.getVitalsHistory(
                targetUserId,
                'weight',
                toDate: bounds.end,
              ),
              service.getVitalsHistory(
                targetUserId,
                'height',
                toDate: bounds.end,
              ),
            ]);
      if (!mounted || seq != _loadSeq) return;

      setState(() {
        _consumedCalories = (food <= 0 && isToday)
            ? HealthVitalsController.instance.calculateTodayTotalCalories()
            : food;
        _workoutMinutes = workout;
        _pastSteps = past == null ? null : latestValue(past[0])?.toInt();
        _pastWeight = past == null ? null : latestValue(past[1]);
        _pastHeight = past == null ? null : latestValue(past[2]);
      });
    } catch (e) {
      debugPrint('CaloriesTrackerTile: failed to load day: $e');
    }
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 28;
    final now = _selectedDate;
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age <= 0 ? 28 : age;
  }

  double _getBMR(double weight, double height, int age, String gender) {
    // Mifflin-St Jeor Equation
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }
    return (10 * weight) + (6.25 * height) - (5 * age) - 161;
  }

  /// Extra daily energy pregnancy needs by trimester (none in the first).
  int _pregnancyExtra() {
    final main = MainController.instance;
    if (!main.isPregnant) return 0;
    final daysBack = DateUtils.dateOnly(DateTime.now())
        .difference(DateUtils.dateOnly(_selectedDate))
        .inDays;
    final week = main.currentGestationalWeek - (daysBack / 7).floor();
    if (week >= 28) return 450;
    if (week >= 14) return 340;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.palette.isDark;
    final textColor = tileTextColor(context);
    final vitals = HealthVitalsController.instance;
    final main = MainController.instance;

    final dbWeight = _isToday ? vitals.weightVital?.value : _pastWeight;
    final dbHeight = _isToday ? vitals.heightVital?.value : _pastHeight;
    final weight = (dbWeight ?? 0) > 0 ? dbWeight! : 60.0;
    final height = (dbHeight ?? 0) > 0 ? dbHeight! : 160.0;
    final bmr = _getBMR(weight, height, _calculateAge(main.dob), main.gender);
    final pregnancyExtra = _pregnancyExtra();

    final stepsCount = widget.stepsForDate ??
        (_isToday ? vitals.stepsValue : (_pastSteps ?? 0));
    final activeBurn = (stepsCount * 0.04).round() +
        (_workoutMinutes * kWorkoutKcalPerMinute).round();

    final consumed = _consumedCalories;
    final totalOutflow = bmr.round() + activeBurn + pregnancyExtra;
    final netBalance = consumed - totalOutflow;
    final dayWord = _isToday ? 'today' : 'that day';

    Color statusColor;
    String statusInsight;
    IconData insightIcon;
    Color gradientEnd;

    if (netBalance < -50) {
      statusColor = const Color(0xFF00E676);
      statusInsight =
          '${netBalance.abs().round()} kcal below your estimated need $dayWord. A nourishing snack can help if you feel hungry.';
      insightIcon = Icons.health_and_safety_rounded;
      gradientEnd = Colors.cyan.shade400;
    } else if (netBalance > 50) {
      statusColor = Colors.orange.shade400;
      statusInsight =
          '${netBalance.round()} kcal above your estimated need $dayWord. Balanced, wholesome meals keep you and baby steady.';
      insightIcon = Icons.local_fire_department_rounded;
      gradientEnd = Colors.pink.shade400;
    } else {
      statusColor = Colors.blue.shade400;
      statusInsight =
          'Intake matches your estimated need $dayWord. Excellent balance!';
      insightIcon = Icons.balance_rounded;
      gradientEnd = Colors.teal.shade400;
    }
    final cardGradient = LinearGradient(
      colors: [
        statusColor.withValues(alpha: 0.06),
        gradientEnd.withValues(alpha: 0.01),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final progressPercent =
        totalOutflow > 0 ? (consumed / totalOutflow).clamp(0.0, 1.0) : 0.0;

    TextStyle bigNumber() => TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: textColor,
        );
    TextStyle smallLabel() => TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor.withValues(alpha: 0.4),
        );

    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) => Opacity(
        opacity: _mainController.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: _scaleAnimation.value, child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tileBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Calories & Balance',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${consumed.round()}', style: bigNumber()),
                    Text('kcal In', style: smallLabel()),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${netBalance.round() > 0 ? "+" : ""}${netBalance.round()} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$totalOutflow', style: bigNumber()),
                    Text('kcal Out', style: smallLabel()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progressPercent,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildStatIndicator(
                  icon: Icons.spa_rounded,
                  label: 'BMR',
                  value: '${bmr.round()}',
                  color: Colors.purple.shade400,
                  textColor: textColor,
                ),
                _buildStatIndicator(
                  icon: Icons.directions_walk_rounded,
                  label: 'Activity',
                  value: '$activeBurn',
                  color: Colors.orange.shade400,
                  textColor: textColor,
                ),
                if (pregnancyExtra > 0)
                  _buildStatIndicator(
                    icon: Icons.pregnant_woman_rounded,
                    label: 'Baby',
                    value: '$pregnancyExtra',
                    color: Theme.of(context).primaryColor,
                    textColor: textColor,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.12),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(insightIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusInsight,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIndicator({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.4),
          ),
        ),
        Text(
          '$value kcal',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
