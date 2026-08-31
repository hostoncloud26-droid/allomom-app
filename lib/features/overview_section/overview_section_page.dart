import 'package:flutter/material.dart';
import 'package:allomom/config/spacings.dart';
import 'package:allomom/features/overview_section/vitals/vitals_overview_section.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_overview_section.dart';

class OverviewSectionPage extends StatelessWidget {
  const OverviewSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VitalsOverviewSection(),
        largeSpacingBox(),
        const NutritionOverviewSection(),
      ],
    );
  }
}
