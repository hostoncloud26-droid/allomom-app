import 'package:flutter/material.dart';
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
    );
  }
}
