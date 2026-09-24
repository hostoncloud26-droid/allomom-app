import 'package:flutter/material.dart';
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
