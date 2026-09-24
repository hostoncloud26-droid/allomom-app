import 'package:flutter/material.dart';
import 'package:allomom/features/auth/auth_flow_page.dart';

class ContactNumberPage extends StatelessWidget {
  final String selectedLanguage;

  const ContactNumberPage({
    super.key,
    this.selectedLanguage = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return AuthFlowPage(
      initialStep: AuthFlowStep.contact,
      initialLanguage: selectedLanguage,
    );
  }
}
