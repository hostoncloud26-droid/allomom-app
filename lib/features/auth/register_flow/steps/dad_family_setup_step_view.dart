import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DadFamilySetupStepView extends StatelessWidget {
  final VoidCallback onJoinByCode;
  final VoidCallback onRegisterPregnancy;
  final VoidCallback onContinue;
  final String partnerWord;

  const DadFamilySetupStepView({
    super.key,
    required this.onJoinByCode,
    required this.onRegisterPregnancy,
    required this.onContinue,
    required this.partnerWord,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect with Your Family',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Join with Code
              _buildOptionTile(
                title: 'Join with Family Code',
                subtitle: "Have a code from $partnerWord? Enter it here",
                icon: Icons.vpn_key_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                onTap: onJoinByCode,
              ),
              const SizedBox(height: 8),

              // Option 2: Register Mommy's Pregnancy
              _buildOptionTile(
                title: "Register $partnerWord's Pregnancy",
                subtitle: "Set up LMP & Due Date for $partnerWord",
                icon: Icons.favorite_rounded,
                iconBg: const Color(0xFFFFF0F3),
                iconColor: const Color(0xFFFF4E6A),
                onTap: onRegisterPregnancy,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── CONTINUE BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5277),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    'Continue as Dad',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
