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

  /// The youngest baby's week while that baby is inside the 1000 days (weeks
  /// 41–142), or null when there is no baby or the youngest has outgrown them.
  ///
  /// Not tied to the one-year new-mom window: the weekly lines run to 142.
  static int? babyWeekOf(DateTime? birth, {DateTime? now}) {
    if (birth == null) return null;
    final days = (now ?? DateTime.now()).difference(birth).inDays;
    final week = birthWeek + (days < 0 ? 0 : days) ~/ 7;
    return week > lastWeek ? null : week;
  }

  /// Her youngest baby's date of birth, or null when there is none.
  static DateTime? youngestBirth() {
    try {
      final babies = BabyController.instance.babies;
      if (babies.isEmpty) return null;
      return babies
          .map((baby) => baby.deliveryDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    } catch (_) {
      return null;
    }
  }

  /// Days since her youngest baby was born, while that baby is inside the
  /// 1000 days — whether or not she is pregnant again. Drives the baby items
  /// in Today's Care.
  static int? babyAgeDays({DateTime? now}) {
    final birth = youngestBirth();
    if (babyWeekOf(birth, now: now) == null) return null;
    final days = (now ?? DateTime.now()).difference(birth!).inDays;
    return days < 0 ? 0 : days;
  }

  /// The baby's week when she is not pregnant but has a baby in the 1000
  /// days — what the home baby-week card shows.
  static int? currentBabyWeek() {
    if (MainController.instance.isPregnant) return null;
    return babyWeekOf(youngestBirth());
  }

  /// This user's week: the pregnancy week while pregnant, the youngest baby's
  /// week (41–142) otherwise, and null when there is neither.
  static int? currentWeek() {
    final main = MainController.instance;
    if (main.isPregnant) return pregnancyWeek(main.currentGestationalWeek);
    return currentBabyWeek();
  }

  /// "Birth week", "3 weeks old", "5 months old", "1 year 2 months old".
  static String ageLabel(DateTime birth, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = today.difference(birth).inDays;
    if (days < 7)
      return days <= 0 ? 'Born today' : '$days day${days == 1 ? '' : 's'} old';
    if (days < 84) {
      final w = days ~/ 7;
      return '$w week${w == 1 ? '' : 's'} old';
    }
    var months = (today.year - birth.year) * 12 + today.month - birth.month;
    if (today.day < birth.day) months--;
    if (months < 12) return '$months months old';
    final years = months ~/ 12;
    final rest = months % 12;
    final y = '$years year${years == 1 ? '' : 's'}';
    return rest == 0 ? '$y old' : '$y $rest month${rest == 1 ? '' : 's'} old';
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
    final text = (await lines(
      week,
    )).map((line) => line.text).where((line) => line.isNotEmpty).join('\n\n');
    return text.isEmpty ? null : text;
  }

  /// Runs an intent away from the chat. Swappable so a widget test can hand
  /// the card its words without standing up the whole chatbot.
  @visibleForTesting
  static Future<List<({String text, String? audioUrl})>> Function(String key)
  runIntent = (key) => OfflineChatbotController.instance.runIntentDetached(key);
}
