import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

import 'nutrition/health_tile_parts.dart';

/// AlloConnect's "Pulse & Daily Activity" card: steps, calories and active
/// minutes as three stat chips beside nested activity rings, for [date]
/// (today when null). [stepsForDate] overrides the day's step count.
class FitnessSummaryCard extends StatefulWidget {
  /// Day the activity totals are for. Defaults to today when omitted.
  final DateTime? date;

  /// Steps recorded on [date]. Falls back to that day's stored steps.
  final int? stepsForDate;

  const FitnessSummaryCard({super.key, this.date, this.stepsForDate});

  @override
  State<FitnessSummaryCard> createState() => _FitnessSummaryCardState();
}

class _FitnessSummaryCardState extends State<FitnessSummaryCard>
    with SingleTickerProviderStateMixin {
  static const int _calorieTarget = 600;
  static const int _activeMinutesTarget = 60;

  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 1800),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutQuart,
  );

  /// Stored steps for a past [widget.date]; null while loading or for today.
  int? _pastSteps;
  int _loadSeq = 0;

  bool get _isToday =>
      widget.date == null || DateUtils.isSameDay(widget.date!, DateTime.now());

  @override
  void initState() {
    super.initState();
    _animationController.forward();
    _loadPastSteps();
  }

  @override
  void didUpdateWidget(covariant FitnessSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(
      oldWidget.date ?? DateTime.now(),
      widget.date ?? DateTime.now(),
    )) {
      _loadPastSteps();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPastSteps() async {
    final seq = ++_loadSeq;
    if (_isToday || widget.stepsForDate != null) {
      if (_pastSteps != null) setState(() => _pastSteps = null);
      return;
    }
    try {
      final bounds = dayBounds(widget.date!);
      final rows = await VitalsSqLiteService().getVitalsHistory(
        MainController.instance.userId,
        'steps',
        fromDate: bounds.start,
        toDate: bounds.end,
      );
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _pastSteps =
            rows.isEmpty ? 0 : (rows.first['value'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      debugPrint('FitnessSummaryCard: failed to load steps: $e');
    }
  }

  int _stepsFor(HealthVitalsController vitals) {
    if (widget.stepsForDate != null) return widget.stepsForDate!;
    if (_isToday) return vitals.stepsValue;
    return _pastSteps ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.palette.isDark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = tileTextColor(context);
    final stepsColor = Colors.blue.shade400;
    final caloriesColor = Colors.orange.shade400;
    final minutesColor = Colors.teal.shade400;

    return AnimatedBuilder(
      animation: HealthVitalsController.instance,
      builder: (context, _) {
        final vitals = HealthVitalsController.instance;
        final steps = _stepsFor(vitals);

        // Average stride 0.762 m, walking speed ~80 m/min, ~0.04 kcal a step.
        final distanceInMeters = steps * 0.762;
        final activeMinutes = (distanceInMeters / 80).round();
        final calories = (steps * 0.04).round();

        final stepTarget =
            vitals.currentStepTarget > 0 ? vitals.currentStepTarget : 6000;
        final stepProgress = (steps / stepTarget).clamp(0.0, 1.0);
        final calorieProgress = (calories / _calorieTarget).clamp(0.0, 1.0);
        final minuteProgress =
            (activeMinutes / _activeMinutesTarget).clamp(0.0, 1.0);
        final dayLabel = _isToday
            ? 'Today'
            : DateFormat('d MMM').format(widget.date!);

        return HealthTileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealthTileHeader(
                title: 'Pulse & Daily Activity',
                accent: primaryColor,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      children: [
                        _AnimatedMetricTile(
                          icon: Icons.directions_walk_rounded,
                          value: steps.toString(),
                          label: 'Steps',
                          color: stepsColor,
                          isDark: isDarkMode,
                          delay: 0.1,
                        ),
                        const SizedBox(height: 10),
                        _AnimatedMetricTile(
                          icon: Icons.local_fire_department_rounded,
                          value: calories.toString(),
                          label: 'Calories',
                          color: caloriesColor,
                          isDark: isDarkMode,
                          delay: 0.3,
                        ),
                        const SizedBox(height: 10),
                        _AnimatedMetricTile(
                          icon: Icons.timer_rounded,
                          value: '$activeMinutes',
                          label: 'Mins',
                          color: minutesColor,
                          isDark: isDarkMode,
                          delay: 0.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 9,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final t = _animation.value.clamp(0.0, 1.0);
                          return SizedBox(
                            width: 140,
                            height: 140,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularPercentIndicator(
                                  radius: 64,
                                  lineWidth: 9.5,
                                  percent: stepProgress * t,
                                  circularStrokeCap: CircularStrokeCap.round,
                                  backgroundColor:
                                      stepsColor.withValues(alpha: 0.1),
                                  progressColor: stepsColor,
                                  startAngle: 270,
                                  animation: false,
                                ),
                                CircularPercentIndicator(
                                  radius: 49,
                                  lineWidth: 9.5,
                                  percent: calorieProgress * t,
                                  circularStrokeCap: CircularStrokeCap.round,
                                  backgroundColor:
                                      caloriesColor.withValues(alpha: 0.1),
                                  progressColor: caloriesColor,
                                  startAngle: 270,
                                  animation: false,
                                ),
                                CircularPercentIndicator(
                                  radius: 34,
                                  lineWidth: 9.5,
                                  percent: minuteProgress * t,
                                  circularStrokeCap: CircularStrokeCap.round,
                                  backgroundColor:
                                      minutesColor.withValues(alpha: 0.1),
                                  progressColor: minutesColor,
                                  startAngle: 270,
                                  animation: false,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(stepProgress * 100).round()}%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      dayLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            textColor.withValues(alpha: 0.5),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedMetricTile extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final double delay;

  const _AnimatedMetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    required this.delay,
  });

  @override
  State<_AnimatedMetricTile> createState() => _AnimatedMetricTileState();
}

class _AnimatedMetricTileState extends State<_AnimatedMetricTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  late final Animation<double> _scaleAnimation =
      Tween<double>(begin: 0.8, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
  );
  late final Animation<double> _opacityAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacityAnimation.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: _scaleAnimation.value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : widget.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.color.withValues(alpha: widget.isDark ? 0.1 : 0.2),
          ),
        ),
        child: Row(
          children: [
            _PulseIcon(icon: widget.icon, color: widget.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: (widget.isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.5),
                      letterSpacing: 0.2,
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
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulseIcon({required this.icon, required this.color});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<double> _animation = Tween<double>(begin: 1.0, end: 1.2)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, color: widget.color, size: 15),
      ),
    );
  }
}
