import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

class FitnessTiles extends StatefulWidget {
  final String? userId;

  const FitnessTiles({
    super.key,
    this.userId,
  });

  @override
  State<FitnessTiles> createState() => _FitnessTilesState();
}

class _FitnessTilesState extends State<FitnessTiles> {
  int _workoutMinutes = 20;
  int _exerciseMinutes = 15;

  @override
  void initState() {
    super.initState();
    _loadFitnessData();
    HealthVitalsController.instance.addListener(_loadFitnessData);
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_loadFitnessData);
    super.dispose();
  }

  Future<void> _loadFitnessData() async {
    if (!mounted) return;
    try {
      final targetUserId = widget.userId ?? UserSessionManager.instance.userId;
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final workoutRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'workout',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      final exerciseRows = await VitalsSqLiteService().getVitalsHistory(
        targetUserId,
        'exercise',
        fromDate: startOfToday,
        toDate: endOfToday,
      );

      int wMins = 0;
      for (final r in workoutRows) {
        wMins += (r['value'] as num?)?.toInt() ?? 0;
      }

      int eMins = 0;
      for (final r in exerciseRows) {
        eMins += (r['value'] as num?)?.toInt() ?? 0;
      }

      if (mounted) {
        setState(() {
          _workoutMinutes = wMins > 0 ? wMins : 20;
          _exerciseMinutes = eMins > 0 ? eMins : 15;
        });
      }
    } catch (_) {}
  }

  void _showAddFitnessSheet(String type, String title, Color color, IconData icon) {
    final minsController = TextEditingController();
    final nameController = TextEditingController();

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
                    'Log $title',
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
                'Activity Type',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Prenatal Yoga / Pelvic Floor / Gentle Walk',
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
                'Duration (Minutes)',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: minsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 20',
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
                    final mins = double.tryParse(minsController.text.trim()) ?? 20.0;
                    final text = nameController.text.trim();

                    await HealthVitalsController.instance.addVitalEntry(
                      key: type.toLowerCase(),
                      value: mins,
                      unit: 'minutes',
                      createdAt: DateTime.now(),
                      userId: widget.userId ?? UserSessionManager.instance.userId,
                      data: {'activity': text, 'type': title},
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save $title',
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
            'Gentle Pregnancy Fitness',
            style: GoogleFonts.manrope(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildFitnessCard(
                  icon: Icons.self_improvement_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Prenatal Yoga',
                  subtitle: '$_workoutMinutes mins today',
                  onTap: () => _showAddFitnessSheet('workout', 'Prenatal Yoga', const Color(0xFF6366F1), Icons.self_improvement_rounded),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFitnessCard(
                  icon: Icons.fitness_center_rounded,
                  color: const Color(0xFFEC4899),
                  title: 'Pelvic Exercise',
                  subtitle: '$_exerciseMinutes mins today',
                  onTap: () => _showAddFitnessSheet('exercise', 'Pelvic Exercise', const Color(0xFFEC4899), Icons.fitness_center_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
                Icon(Icons.add_circle_outline_rounded, color: color.withValues(alpha: 0.8), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
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
