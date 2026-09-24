import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/widgets/narration_hint_chips.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class RegisterEddDueDatePage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime lmpDate;
  final DateTime eddDate;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? partnerName;
  final String? partnerPhone;
  final bool registerPregnancyForPartner;

  const RegisterEddDueDatePage({
    super.key,
    required this.userName,
    required this.status,
    required this.lmpDate,
    required this.eddDate,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.partnerName,
    this.partnerPhone,
    this.registerPregnancyForPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.edd,
      userName: userName,
      status: status,
      lmpDate: lmpDate,
      eddDate: eddDate,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      registerPregnancyForPartner: registerPregnancyForPartner,
    );
  }
}

class RegisterEddStepView extends StatelessWidget {
  final DateTime eddDate;
  final String narrationKey;
  final ValueChanged<String> onHintSelected;
  final VoidCallback onConfirm;

  const RegisterEddStepView({
    super.key,
    required this.eddDate,
    required this.narrationKey,
    required this.onHintSelected,
    required this.onConfirm,
  });

  String _formatEddDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final eddString = _formatEddDate(eddDate);
    final daysRemaining = eddDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED DUE DATE (EDD)',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8E95A5),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // Due Date Display Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F3), Color(0xFFFFE4E8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFD1DC),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        eddString,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4E6A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$daysRemaining Days to go!',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                NarrationHintChips(
                  selectedKey: narrationKey,
                  onSelected: onHintSelected,
                  padding: const EdgeInsets.only(bottom: 4),
                  hints: [
                    const NarrationHint(
                      'What are these days?',
                      NarrationKeys.pregEddDays,
                    ),
                    NarrationHint(
                      'How long is that?',
                      countdownNarrationKey(daysRemaining),
                    ),
                    const NarrationHint(
                      'Doctor said another date',
                      NarrationKeys.pregEddDoctorDate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── CONFIRM DUE DATE BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onConfirm,
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
                    'Confirm & Next',
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
}
