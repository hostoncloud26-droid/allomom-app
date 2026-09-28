import 'package:flutter/material.dart';

/// 3D illustrations from `assets/Quick Actions/`, shared by the Home overview
/// cards, the My Health tiles, and anywhere the app pictures mom or dad.
class QuickActionImages {
  QuickActionImages._();

  static const _dir = 'assets/Quick Actions';

  // People
  static const mom = '$_dir/Mom.png';
  static const dad = '$_dir/Dad.png';

  // Vitals
  static const steps = '$_dir/Daily Activity.png';
  static const heartRate = '$_dir/Heart Rate.png';
  static const hrv = '$_dir/HRV.png';
  static const sleep = '$_dir/Sleep.png';
  static const stress = '$_dir/Stress load.png';
  static const bloodOxygen = '$_dir/Blood oxygen.png';
  static const bloodPressure = '$_dir/BP.png';
  static const bloodGlucose = '$_dir/Blood glucose.png';
  static const hemoglobin = '$_dir/Hemoglobin.png';
  static const weight = '$_dir/Weight.png';
  static const kickCount = '$_dir/Kick Count.png';
  static const feeding = '$_dir/Feeding.png';

  // Nutrition
  static const breakfast = '$_dir/Breakfast.png';
  static const lunch = '$_dir/Lunch.png';
  static const dinner = '$_dir/Dinner.png';
  static const snacks = '$_dir/Snacks.png';
  static const water = '$_dir/Water.png';
  static const drinks = '$_dir/Drinks.png';

  /// Mom or dad, from the user's gender or role. Anything that is not
  /// clearly male reads as mom — she is who the app is for.
  static String person({String? gender, bool isDad = false}) {
    final g = (gender ?? '').trim().toLowerCase();
    return isDad || g == 'male' || g == 'father' || g == 'dad' ? dad : mom;
  }
}

/// A Quick Actions illustration sized to sit where an icon used to.
class QuickActionImage extends StatelessWidget {
  const QuickActionImage(this.asset, {super.key, this.size = 28});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      filterQuality: FilterQuality.medium,
    );
  }
}
