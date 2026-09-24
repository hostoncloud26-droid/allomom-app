import 'package:flutter/material.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class FamilyDetailsPage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime? eddDate;
  final DateTime? lmpDate;
  final int? averageCycleLength;
  final String? partnerName;
  final String? partnerPhone;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const FamilyDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.partnerName,
    this.partnerPhone,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.family,
      userName: userName,
      status: status,
      eddDate: eddDate,
      lmpDate: lmpDate,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      familyCode: familyCode,
      registerPregnancyForPartner: registerPregnancyForPartner,
    );
  }
}
