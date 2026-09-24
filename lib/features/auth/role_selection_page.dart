import 'package:flutter/material.dart';
import 'package:allomom/features/auth/auth_flow_page.dart';

class RoleSelectionPage extends StatelessWidget {
  final String selectedLanguage;
  final String phone;
  final String countryCode;

  const RoleSelectionPage({
    super.key,
    this.selectedLanguage = 'en',
    this.phone = '',
    this.countryCode = '+91',
  });

  @override
  Widget build(BuildContext context) {
    return AuthFlowPage(
      initialStep: AuthFlowStep.role,
      initialLanguage: selectedLanguage,
      initialPhone: phone,
      initialCountryCode: countryCode,
    );
  }
}
