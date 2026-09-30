import 'dart:async';

import 'package:flutter/foundation.dart';

/// The four parts of her day the Home scene follows.
enum PartOfDay {
  morning, // 6 AM – 12 PM
  afternoon, // 12 PM – 6 PM
  evening, // 6 PM – 9 PM
  night; // 9 PM – 6 AM

  static PartOfDay at(DateTime time) {
    final h = time.hour;
    if (h >= 6 && h < 12) return PartOfDay.morning;
    if (h >= 12 && h < 18) return PartOfDay.afternoon;
    if (h >= 18 && h < 21) return PartOfDay.evening;
    return PartOfDay.night;
  }

  /// The scene painted behind the baby on Home.
  String get backgroundAsset => 'assets/bg/$name.png';

  /// Height over width of every scene in `assets/bg/` (940 × 1000).
  static const sceneAspect = 1000 / 940;

  /// How far down its scene the blanket's edge runs behind the baby, as a
  /// fraction of the image height — where she sits. Measured at the
  /// horizontal centre, a touch below the edge so she sinks in slightly.
  double get bedLine => switch (this) {
        PartOfDay.morning => 0.73,
        PartOfDay.afternoon => 0.79,
        PartOfDay.evening => 0.74,
        PartOfDay.night => 0.78,
      };

  /// Evening and night scenes are dark enough that text over them goes light.
  bool get isDark => this == PartOfDay.evening || this == PartOfDay.night;

  /// When the period after this one starts, counted from [now].
  static DateTime nextChange(DateTime now) {
    const starts = [6, 12, 18, 21];
    for (final h in starts) {
      final t = DateTime(now.year, now.month, now.day, h);
      if (t.isAfter(now)) return t;
    }
    return DateTime(now.year, now.month, now.day + 1, starts.first);
  }
}

/// The current [PartOfDay], changing on the hour it turns over rather than
/// polling. Shared, so Home's scene and the shell's app bar agree.
class PartOfDayClock extends ValueNotifier<PartOfDay> {
  PartOfDayClock._() : super(PartOfDay.at(DateTime.now())) {
    _schedule();
  }

  static final PartOfDayClock instance = PartOfDayClock._();

  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    // A second past the boundary, so the new hour has definitely begun.
    final wait = PartOfDay.nextChange(now).difference(now) + const Duration(seconds: 1);
    _timer = Timer(wait, () {
      value = PartOfDay.at(DateTime.now());
      _schedule();
    });
  }

  /// Rechecks now — after the app comes back from the background, where
  /// timers may not have fired, or the clock was changed.
  void refresh() {
    value = PartOfDay.at(DateTime.now());
    _schedule();
  }
}
