import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelectionStepView extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleSelected;
  final VoidCallback onProceed;

  const RoleSelectionStepView({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.onProceed,
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
                'I am a:',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 16),

              // 2 Large Role Cards
              Row(
                children: [
                  // Mom Card
                  Expanded(
                    child: _buildRoleCard(
                      role: 'Mom',
                      iconBg: const Color(0xFFFFE4E9),
                      avatarColor: const Color(0xFFFF4E6A),
                      isFemale: true,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Dad Card
                  Expanded(
                    child: _buildRoleCard(
                      role: 'Dad',
                      iconBg: const Color(0xFFDBEAFE),
                      avatarColor: const Color(0xFF2563EB),
                      isFemale: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── PROCEED BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onProceed,
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
                    'Proceed',
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

  Widget _buildRoleCard({
    required String role,
    required Color iconBg,
    required Color avatarColor,
    required bool isFemale,
  }) {
    final isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () => onRoleSelected(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E6A)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF4E6A).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Custom Avatar Icon Circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(
                child: Icon(
                  isFemale ? Icons.face_3_rounded : Icons.face_6_rounded,
                  color: isSelected ? const Color(0xFFFF4E6A) : avatarColor,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              role,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xFFFF4E6A)
                    : const Color(0xFF1E2024),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
