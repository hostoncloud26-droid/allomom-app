import 'package:flutter/material.dart';
import 'package:allomom/features/auth/auth_flow_page.dart';

class RegisterNamePage extends StatelessWidget {
  final String phone;
  final String countryCode;
  final String selectedLanguage;
  final String selectedRole;

  const RegisterNamePage({
    super.key,
    this.phone = '9876543210',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
    this.selectedRole = 'Mom',
  });

  @override
  Widget build(BuildContext context) {
    return AuthFlowPage(
      initialStep: AuthFlowStep.name,
      initialPhone: phone,
      initialCountryCode: countryCode,
      initialLanguage: selectedLanguage,
      initialRole: selectedRole,
    );
  }
}
