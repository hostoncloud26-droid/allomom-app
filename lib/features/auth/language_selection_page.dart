import 'package:flutter/material.dart';
import 'package:allomom/features/auth/auth_flow_page.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFlowPage(initialStep: AuthFlowStep.language);
  }
}
