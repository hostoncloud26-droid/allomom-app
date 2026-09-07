import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class CaloriesTrackerTile extends StatefulWidget {
  final String? userId;

  const CaloriesTrackerTile({
    super.key,
    this.userId,
  });

  @override
  State<CaloriesTrackerTile> createState() => _CaloriesTrackerTileState();
}

class _CaloriesTrackerTileState extends State<CaloriesTrackerTile> {
  double _consumedCalories = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCalories();
    HealthVitalsController.instance.addListener(_loadCalories);
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_loadCalories);
    super.dispose();
  }

  Future<void> _loadCalories() async {
    if (!mounted) return;
    try {
      final targetUserId = widget.userId ?? UserSessionManager.instance.userId;
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final foodRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'food',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      final breakfastRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'breakfast',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      final lunchRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'lunch',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      final dinnerRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'dinner',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      final snacksRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'snacks',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      double totalFood = 0.0;
      for (final r in [...foodRows, ...breakfastRows, ...lunchRows, ...dinnerRows, ...snacksRows]) {
        totalFood += (r['value'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _consumedCalories = totalFood > 0 ? totalFood : HealthVitalsController.instance.calculateTodayTotalCalories();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _consumedCalories = HealthVitalsController.instance.calculateTodayTotalCalories();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const dailyTarget = 2200.0; // Recommended pregnancy dietary energy intake approx
    final progress = (_consumedCalories / dailyTarget).clamp(0.0, 1.0);
    final remaining = (dailyTarget - _consumedCalories).clamp(0.0, dailyTarget);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: Color(0xFFFF9800),
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Calories & Diet',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                ],
              ),
              Text(
                'Goal: ${dailyTarget.toInt()} kcal',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_consumedCalories.toInt()}',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kcal eaten',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${remaining.toInt()} kcal remaining today',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
