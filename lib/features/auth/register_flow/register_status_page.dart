import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class RegisterStatusPage extends StatelessWidget {
  final String userName;
  final String phone;
  final String countryCode;
  final String selectedLanguage;
  final String selectedRole;

  const RegisterStatusPage({
    super.key,
    required this.userName,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
    this.selectedRole = 'Mom',
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.status,
      userName: userName,
      phone: phone,
      countryCode: countryCode,
      selectedLanguage: selectedLanguage,
      selectedRole: selectedRole,
    );
  }
}

class RegisterStatusStepView extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onNext;

  const RegisterStatusStepView({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.onNext,
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
                'What describes you best?',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 10),

              // Option 1: Pre Pregnancy
              _buildStatusOption(
                title: 'Planning for a Baby',
                subtitle: 'Pre Pregnancy',
                value: 'Pre Pregnancy',
                iconBg: const Color(0xFFFAF5FF),
                iconColor: const Color(0xFFC026D3),
                icon: Icons.child_care_rounded,
              ),
              const SizedBox(height: 6),

              // Option 2: Pregnant
              _buildStatusOption(
                title: 'Pregnant',
                subtitle: 'Expecting a Baby',
                value: 'Pregnant',
                iconBg: const Color(0xFFFFF0F3),
                iconColor: const Color(0xFFFF4E6A),
                icon: Icons.pregnant_woman_rounded,
              ),
              const SizedBox(height: 6),

              // Option 3: New Mom
              _buildStatusOption(
                title: 'New Mom',
                subtitle: 'Caring for your Baby',
                value: 'New Mom',
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                icon: Icons.face_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── NEXT BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedStatus.isNotEmpty
                  ? const Color(0xFFFF5277)
                  : const Color(0xFFFF8FA3),
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
                    'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
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

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required String value,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
  }) {
    final isSelected = selectedStatus.isNotEmpty &&
        (selectedStatus.toLowerCase() == value.toLowerCase() ||
            selectedStatus.toLowerCase() == title.toLowerCase());

    return GestureDetector(
      onTap: () => onStatusSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF4E6A).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF4E6A),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
