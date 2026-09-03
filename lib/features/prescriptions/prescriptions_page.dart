import 'package:flutter/material.dart';
import 'package:allomom/features/prescriptions/prescription_timings_view.dart';

class PrescriptionsPage extends StatelessWidget {
  final String? userId;

  const PrescriptionsPage({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return PrescriptionTimingsView(
      userId: userId,
      showAppBar: false,
    );
  }
}
