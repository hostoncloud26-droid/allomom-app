import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class FamilyDetailsPage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime? eddDate;
  final DateTime? lmpDate;
  final int? averageCycleLength;
  final String? partnerName;
  final String? partnerPhone;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const FamilyDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.partnerName,
    this.partnerPhone,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.family,
      userName: userName,
      status: status,
      eddDate: eddDate,
      lmpDate: lmpDate,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      familyCode: familyCode,
      registerPregnancyForPartner: registerPregnancyForPartner,
    );
  }
}

class FamilyDetailsStepView extends StatelessWidget {
  final bool hasKids;
  final ValueChanged<bool> onHasKidsChanged;
  final bool isLoading;
  final VoidCallback onNext;

  const FamilyDetailsStepView({
    super.key,
    required this.hasKids,
    required this.onHasKidsChanged,
    required this.isLoading,
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
                'Do you have other children?',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 14),

              // Yes / No Choice Cards Row
              Row(
                children: [
                  // YES Card
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Yes',
                      subtitle: 'I have kids',
                      isSelected: hasKids,
                      onTap: () => onHasKidsChanged(true),
                      icon: Icons.child_friendly_rounded,
                      iconBg: const Color(0xFFFFF0F3),
                      iconColor: const Color(0xFFFF4E6A),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // NO Card
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'No',
                      subtitle: 'This is my first',
                      isSelected: !hasKids,
                      onTap: () => onHasKidsChanged(false),
                      icon: Icons.favorite_border_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── NEXT / FINISH BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5277),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          hasKids ? 'Add Children Details' : 'Complete Setup',
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

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFE5E7EB),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF1E2024),
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
    );
  }
}
