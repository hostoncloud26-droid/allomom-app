import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/lmp_wheel_picker.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class RegisterLmpTimelinePage extends StatelessWidget {
  final String userName;
  final String status;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? partnerName;
  final String? partnerPhone;
  final bool registerPregnancyForPartner;

  const RegisterLmpTimelinePage({
    super.key,
    required this.userName,
    required this.status,
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
      initialStep: RegisterStep.lmp,
      userName: userName,
      status: status,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      registerPregnancyForPartner: registerPregnancyForPartner,
    );
  }
}

class RegisterLmpStepView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onCalculate;
  final bool isPregnancyFlow;
  final String status;

  const RegisterLmpStepView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onCalculate,
    required this.isPregnancyFlow,
    this.status = 'Pregnant',
  });

  bool get _isPregnant {
    if (isPregnancyFlow) return true;
    final s = status.toLowerCase().trim();
    return s.contains('pregnan') && !s.startsWith('pre');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: LmpWheelPicker(
              selectedDate: selectedDate,
              onDateChanged: onDateChanged,
              isPregnant: _isPregnant,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── CALCULATE BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onCalculate,
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
                Text(
                  isPregnancyFlow ? 'Calculate Due Date' : 'Calculate My Cycle',
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
