import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class RegisterPartnerDetailsPage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime? eddDate;
  final DateTime? lmpDate;
  final int? averageCycleLength;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const RegisterPartnerDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.partner,
      userName: userName,
      status: status,
      eddDate: eddDate,
      lmpDate: lmpDate,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      familyCode: familyCode,
      registerPregnancyForPartner: registerPregnancyForPartner,
    );
  }
}

class RegisterPartnerStepView extends StatelessWidget {
  final TextEditingController partnerNameController;
  final TextEditingController partnerPhoneController;
  final String partnerWord;
  final bool isDad;
  final VoidCallback onSave;
  final VoidCallback onSkip;
  final bool isKeyboardOpen;

  const RegisterPartnerStepView({
    super.key,
    required this.partnerNameController,
    required this.partnerPhoneController,
    required this.partnerWord,
    required this.isDad,
    required this.onSave,
    required this.onSkip,
    this.isKeyboardOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                Text(
                  "$partnerWord's Name (Optional)",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFFFF4E6A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: partnerNameController,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E2024),
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter $partnerWord's Name",
                            hintStyle: GoogleFonts.poppins(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 13.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Phone field
                Text(
                  "$partnerWord's Phone Number (Optional)",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFFFF4E6A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: partnerPhoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E2024),
                          ),
                          decoration: InputDecoration(
                            hintText: '10-digit Mobile Number',
                            hintStyle: GoogleFonts.poppins(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 13.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Skip Button inside scrollable
                Center(
                  child: TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── SAVE & CONTINUE BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onSave,
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
                    'Save & Continue',
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
}
