import 'package:flutter/material.dart';

import 'package:allomom/config/quick_action_images.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/widgets/baby_feature_row.dart';

/// The pregnancy's features as the baby's are: a sideways slider of Home's
/// quick-action boxes — Kick Counter, Vaccination, Lab Reports and ANC.
class PregnancyFeatureRow extends StatelessWidget {
  const PregnancyFeatureRow({super.key, required this.onChanged});

  /// Called after a feature page closes, so the page can reload.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    Future<void> push(Widget page) async {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => page));
      onChanged();
    }

    return FeatureSlider(
      boxes: [
        FeatureBox(
          title: 'Kick Counter',
          image: QuickActionImages.kickCount,
          onTap: () => push(const KickCounterPage()),
        ),
        FeatureBox(
          title: 'Vaccination',
          icon: Icons.vaccines_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => push(const VaccinationSchedulePage()),
        ),
        FeatureBox(
          title: 'Lab Reports',
          icon: Icons.science_rounded,
          color: const Color(0xFF3898EC),
          onTap: () => push(const LabReportsSchedulePage()),
        ),
        FeatureBox(
          title: 'ANC',
          icon: Icons.local_hospital_rounded,
          onTap: () => push(const AncSchedulePage()),
        ),
      ],
    );
  }
}
