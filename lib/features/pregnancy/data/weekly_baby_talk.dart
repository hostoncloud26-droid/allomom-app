import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The baby's message for each week, from the Baby Talk audio-script sheet.
///
/// Built by `tool/make_weekly_baby_talk.py` from
/// `lib/seeds/Baby_Talk_1000_Days_142W_Audio_Scripts.xlsx` — edit the sheet and
/// rerun the script rather than the JSON. Weeks 1–40 are pregnancy counted from
/// the LMP, 41 is birth, and from 42 the baby is (week − 41) weeks old.
abstract final class WeeklyBabyTalk {
  static const asset = 'lib/seeds/weekly_baby_talk.json';

  /// Languages the sheet is written in. Anything else reads the English.
  static const languages = {'en', 'ta', 'hi'};

  static Future<Map<String, dynamic>>? _load;

  static Future<Map<String, dynamic>> _weeks() => _load ??= rootBundle
      .loadString(asset)
      .then((raw) => jsonDecode(raw) as Map<String, dynamic>)
      .catchError((Object e) {
        debugPrint('WeeklyBabyTalk: could not load $asset: $e');
        _load = null;
        return <String, dynamic>{};
      });

  /// The sheet week for a pregnancy at [completedWeeks] (as
  /// `MainController.currentGestationalWeek` counts them). Overdue weeks keep
  /// the week-40 message: week 41 in the sheet is the birth itself.
  static int pregnancyWeek(int completedWeeks) => completedWeeks.clamp(1, 40);

  /// What the baby says to Amma in [week], in [language] if the sheet has it.
  /// Null when the week is not in the sheet.
  static Future<String?> momMessage(int week, String language) async {
    final entry = (await _weeks())['$week'];
    if (entry is! Map) return null;
    final mom = entry['mom'];
    if (mom is! Map) return null;
    final text =
        mom[languages.contains(language) ? language : 'en'] ?? mom['en'];
    return text is String && text.isNotEmpty ? text : null;
  }
}
