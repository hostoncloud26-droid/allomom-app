import 'package:flutter/material.dart';
import 'package:allomom/features/auth/auth_flow_page.dart';

class VerifyOtpPage extends StatelessWidget {
  final String phoneNumber;
  final String rawPhone;
  final String countryCode;
  final String selectedLanguage;

  const VerifyOtpPage({
    super.key,
    required this.phoneNumber,
    this.rawPhone = '9876543210',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return AuthFlowPage(
      initialStep: AuthFlowStep.verifyOtp,
      initialLanguage: selectedLanguage,
      initialPhone: rawPhone,
      initialCountryCode: countryCode,
    );
  }
}
