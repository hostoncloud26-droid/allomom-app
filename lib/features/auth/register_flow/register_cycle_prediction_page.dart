import 'package:flutter/material.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class RegisterCyclePredictionPage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime lmpDate;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? partnerName;
  final String? partnerPhone;

  const RegisterCyclePredictionPage({
    super.key,
    required this.userName,
    required this.status,
    required this.lmpDate,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.partnerName,
    this.partnerPhone,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.cyclePrediction,
      userName: userName,
      status: status,
      lmpDate: lmpDate,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
    );
  }
}
