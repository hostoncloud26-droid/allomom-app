import 'package:flutter/material.dart';
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
