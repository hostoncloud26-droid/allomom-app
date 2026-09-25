import 'package:flutter/foundation.dart';

import 'package:allomom/controllers/baby_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

/// The baby's message for each of the 1000 days' 142 weeks, from AlloBot.
///
/// Every week is an intent in the offline chatbot catalogue,
/// `pregnancy_week_<week>_info`, authored in the Flow Builder. Its flow picks
/// Amma's or Appa's line off `profile.type` and names the clip for it
/// (`pregnant_week_<week>_info_mom` / `_dad`), so running the intent gives both
/// the words and the voice — the same way the AlloBot page runs a flow. Weeks
/// 1–40 are pregnancy counted from the LMP, 41 is birth, and from 42 the baby
/// is (week − 41) weeks old.
abstract final class WeeklyBabyTalk {
  /// The sheet week for a pregnancy at [completedWeeks] (as
  /// `MainController.currentGestationalWeek` counts them). Overdue weeks keep
  /// the week-40 message: week 41 is the birth itself.
  static int pregnancyWeek(int completedWeeks) => completedWeeks.clamp(1, 40);

  /// The birth week; a baby [ageDays] old is in `41 + ageDays ~/ 7`.
  static const int birthWeek = 41;

  /// The last week there is a line for — 1000 days.
  static const int lastWeek = 142;

  /// The week for a baby born on [birth], clamped to 41–142.
  static int babyWeek(DateTime birth, {DateTime? now}) {
    final days = (now ?? DateTime.now()).difference(birth).inDays;
    return (birthWeek + (days < 0 ? 0 : days) ~/ 7).clamp(birthWeek, lastWeek);
  }

  /// This user's week: the pregnancy week while pregnant, the youngest baby's
  /// age as a new mom, and null otherwise.
  static int? currentWeek() {
    final main = MainController.instance;
    if (main.isPregnant) return pregnancyWeek(main.currentGestationalWeek);
    if (!main.isNewMom) return null;
    try {
      final babies = BabyController.instance.babies;
      if (babies.isEmpty) return null;
      final youngest = babies
          .map((baby) => baby.deliveryDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return babyWeek(youngest);
    } catch (_) {
      return null;
    }
  }

  /// The AlloBot intent that holds [week]'s line, e.g.
  /// `pregnancy_week_6_info`.
  static String intentKey(int week) => 'pregnancy_week_${week}_info';

  /// What [week]'s flow says, step by step, with the clip for each step —
  /// already Amma's or Appa's, in her language where the catalogue has it.
  /// Empty until the catalogue has the intent.
  static Future<List<({String text, String? audioUrl})>> lines(int week) =>
      runIntent(intentKey(week));

  /// What the baby says in [week], as one block of text for the week card.
  /// Null until the catalogue has the intent.
  static Future<String?> message(int week) async {
    final text = (await lines(week))
        .map((line) => line.text)
        .where((line) => line.isNotEmpty)
        .join('\n\n');
    return text.isEmpty ? null : text;
  }

  /// Runs an intent away from the chat. Swappable so a widget test can hand
  /// the card its words without standing up the whole chatbot.
  @visibleForTesting
  static Future<List<({String text, String? audioUrl})>> Function(String key)
  runIntent = (key) => OfflineChatbotController.instance.runIntentDetached(key);
}
