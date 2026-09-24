import 'package:flutter/material.dart';
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
