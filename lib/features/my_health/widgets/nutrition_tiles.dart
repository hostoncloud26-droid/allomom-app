import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class NutritionTiles extends StatefulWidget {
  final String? userId;

  const NutritionTiles({
    super.key,
    this.userId,
  });

  @override
  State<NutritionTiles> createState() => _NutritionTilesState();
}

class _NutritionTilesState extends State<NutritionTiles> {
  double _breakfastCal = 0.0;
  double _lunchCal = 0.0;
  double _dinnerCal = 0.0;
  double _snacksCal = 0.0;
  int _waterGlasses = 0;

  @override
  void initState() {
    super.initState();
    _loadMeals();
    HealthVitalsController.instance.addListener(_loadMeals);
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_loadMeals);
    super.dispose();
  }

  Future<void> _loadMeals() async {
    if (!mounted) return;
    try {
      final targetUserId = widget.userId ?? UserSessionManager.instance.userId;
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final bfRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'breakfast',
        fromDate: startOfToday,
        toDate: endOfToday,
      );
      final bfAltRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'break_fast',
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
      final waterRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'water',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      double bSum = 0.0;
      for (final r in [...bfRows, ...bfAltRows]) {
        bSum += (r['value'] as num?)?.toDouble() ?? 0.0;
      }
      double lSum = 0.0;
      for (final r in lunchRows) {
        lSum += (r['value'] as num?)?.toDouble() ?? 0.0;
      }
      double dSum = 0.0;
      for (final r in dinnerRows) {
        dSum += (r['value'] as num?)?.toDouble() ?? 0.0;
      }
      double sSum = 0.0;
      for (final r in snacksRows) {
        sSum += (r['value'] as num?)?.toDouble() ?? 0.0;
      }

      int wSum = 0;
      for (final r in waterRows) {
        wSum += ((r['value'] as num?)?.toDouble() ?? 0).round();
      }
      if (wSum < 0) wSum = 0;

      if (mounted) {
        setState(() {
          _breakfastCal = bSum;
          _lunchCal = lSum;
          _dinnerCal = dSum;
          _snacksCal = sSum;
          _waterGlasses = wSum;
        });
      }
    } catch (_) {}
  }

  void _showAddMealDialog(String mealType, String label, Color color, IconData icon) {
    final calController = TextEditingController();
    final itemController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log $label',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Text(
                'Meal Description / Food Items',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: itemController,
                decoration: InputDecoration(
                  hintText: 'e.g. Oats porridge with almonds & milk',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Calories (kcal)',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: calController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 350',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final cal = double.tryParse(calController.text.trim()) ?? 300.0;
                    final text = itemController.text.trim();

                    await HealthVitalsController.instance.addVitalEntry(
                      key: mealType.toLowerCase(),
                      value: cal,
                      unit: 'kcal',
                      createdAt: DateTime.now(),
                      userId: widget.userId ?? UserSessionManager.instance.userId,
                      data: {'items': text, 'meal': label},
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save $label',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Nutrition & Hydration',
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
        ),

        // Row 1: Breakfast & Lunch
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMealCard(
                  icon: Icons.wb_sunny_rounded,
                  color: const Color(0xFFFF9800),
                  label: 'Breakfast',
                  calories: _breakfastCal,
                  onTap: () => _showAddMealDialog('breakfast', 'Breakfast', const Color(0xFFFF9800), Icons.wb_sunny_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMealCard(
                  icon: Icons.lunch_dining_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Lunch',
                  calories: _lunchCal,
                  onTap: () => _showAddMealDialog('lunch', 'Lunch', const Color(0xFF10B981), Icons.lunch_dining_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 2: Snacks & Dinner
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMealCard(
                  icon: Icons.cookie_rounded,
                  color: const Color(0xFFF59E0B),
                  label: 'Snacks',
                  calories: _snacksCal,
                  onTap: () => _showAddMealDialog('snacks', 'Snacks', const Color(0xFFF59E0B), Icons.cookie_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMealCard(
                  icon: Icons.dinner_dining_rounded,
                  color: const Color(0xFF8B5CF6),
                  label: 'Dinner',
                  calories: _dinnerCal,
                  onTap: () => _showAddMealDialog('dinner', 'Dinner', const Color(0xFF8B5CF6), Icons.dinner_dining_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 3: Water Hydration Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hydration Tracker',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _waterGlasses > 0
                              ? '$_waterGlasses of 10 glasses (${(_waterGlasses * 0.25).toStringAsFixed(1)}L)'
                              : '0 of 10 glasses • Tap + to log',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_waterGlasses > 0)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        setState(() => _waterGlasses = _waterGlasses - 1);
                        // Rows hold increments (the reader sums them), so a
                        // correction is logged as -1, not as the new total.
                        await HealthVitalsController.instance.addVitalEntry(
                          key: 'water',
                          value: -1,
                          unit: 'glasses',
                          createdAt: DateTime.now(),
                          userId: widget.userId ?? UserSessionManager.instance.userId,
                          data: const {'details': 'Corrected by 1 glass', 'type': 'water'},
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove_rounded, color: Color(0xFF64748B), size: 16),
                      ),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      setState(() => _waterGlasses = _waterGlasses + 1);
                      await HealthVitalsController.instance.addVitalEntry(
                        key: 'water',
                        value: 1,
                        unit: 'glasses',
                        createdAt: DateTime.now(),
                        userId: widget.userId ?? UserSessionManager.instance.userId,
                        data: const {'details': '1 glass', 'type': 'water'},
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Color(0xFF0284C7), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_waterGlasses / 10.0).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard({
    required IconData icon,
    required Color color,
    required String label,
    required double calories,
    required VoidCallback onTap,
  }) {
    final hasLogged = calories > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasLogged ? const Color(0xFFE6F9F0) : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasLogged ? 'Logged' : '+ Add',
                    style: GoogleFonts.manrope(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: hasLogged ? const Color(0xFF10B981) : color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLogged ? '${calories.toInt()} kcal' : '0 kcal',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: hasLogged ? FontWeight.w700 : FontWeight.w500,
                    color: hasLogged ? const Color(0xFF1E2024) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
