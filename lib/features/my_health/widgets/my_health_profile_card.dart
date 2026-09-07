import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/health_info_editor_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class MyHealthProfileCard extends StatelessWidget {
  const MyHealthProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([UserSessionManager.instance, HealthVitalsController.instance]),
      builder: (context, _) {
        final session = UserSessionManager.instance;
        final vitals = HealthVitalsController.instance;

        final name = session.userName;
        final week = session.currentGestationalWeek;
        final trimester = session.currentTrimester;
        final bg = session.bloodGroup ?? vitals.bloodGroupVital?.unit ?? '--';
        final heightVal = vitals.heightVital?.value ?? (session.currentHealthData?.height ?? 162.0);
        final weightVal = vitals.weightVital?.value ?? (session.currentHealthData?.weight ?? 62.5);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D3142),
                Color(0xFF1E2024),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5277), Color(0xFFFF3B5C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B5C).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Gestational Week
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Week $week • $trimester',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF8FA3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit button
                  IconButton(
                    onPressed: () {
                      HealthInfoEditorSheet.show(
                        context: context,
                        userId: session.userId,
                        height: heightVal,
                        weight: weightVal,
                        bloodGroup: bg != '--' ? bg : null,
                        primaryColor: const Color(0xFFFF3B5C),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metric chips (Blood Group, Height, Weight)
              Row(
                children: [
                  _buildMetricPill(
                    icon: Icons.bloodtype_rounded,
                    iconColor: const Color(0xFFFF4E6A),
                    label: 'Blood',
                    value: bg,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricPill(
                    icon: Icons.height_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    label: 'Height',
                    value: '${heightVal.toStringAsFixed(0)} cm',
                  ),
                  const SizedBox(width: 8),
                  _buildMetricPill(
                    icon: Icons.monitor_weight_outlined,
                    iconColor: const Color(0xFF34D399),
                    label: 'Weight',
                    value: '${weightVal.toStringAsFixed(1)} kg',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
    );
  }
}
