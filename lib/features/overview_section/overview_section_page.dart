import 'package:flutter/material.dart';
import 'package:allomom/config/spacings.dart';
import 'package:allomom/features/overview_section/vitals/vitals_overview_section.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_overview_section.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/narration_on_visible.dart';

class OverviewSectionPage extends StatelessWidget {
  const OverviewSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The lines belong to the sections, not to the screen that hosts them:
        // this pair appears on home and inside My Health, and either way the
        // baby says the same thing about them, once.
        const NarrationOnVisible(
          narrationKey: NarrationKeys.pgHomeVitals,
          child: VitalsOverviewSection(),
        ),
        largeSpacingBox(),
        const NarrationOnVisible(
          narrationKey: NarrationKeys.pgNutritionOpen,
          child: NutritionOverviewSection(),
        ),
      ],
    );
  }
}
