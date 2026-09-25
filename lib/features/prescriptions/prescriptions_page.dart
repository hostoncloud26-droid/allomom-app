import 'package:flutter/material.dart';
import 'package:allomom/features/prescriptions/prescription_timings_view.dart';

class PrescriptionsPage extends StatelessWidget {
  final String? userId;

  /// Off when the page is a tab inside My Health, which has its own app bar.
  /// On everywhere it is pushed by itself — Home's Quick Actions, the chatbot —
  /// so it gets a back button and stays below the status bar.
  final bool showAppBar;

  const PrescriptionsPage({
    super.key,
    this.userId,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return PrescriptionTimingsView(
      userId: userId,
      showAppBar: showAppBar,
    );
  }
}
