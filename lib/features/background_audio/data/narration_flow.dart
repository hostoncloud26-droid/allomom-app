import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/repositories/pregnancy_state.dart';

/// Which of the three journeys the mother is on.
///
/// Several screens are shared by all three — the partner step, the siblings
/// step, the finish, the home page — but the script gives each journey its own
/// wording, so every one of those screens has to pick. They pick here rather
/// than each re-deriving it from a status string.
enum NarrationFlow { pregnant, prePregnancy, newMom }

extension NarrationFlowKeys on NarrationFlow {
  /// Reads a registration status label ('Pregnant', 'Pre Pregnancy',
  /// 'New Mom', and the lower-case forms carried between screens).
  static NarrationFlow of(String statusLabel) {
    if (isNewMomRegistrationLabel(statusLabel)) return NarrationFlow.newMom;
    if (isPregnantRegistrationLabel(statusLabel)) return NarrationFlow.pregnant;
    return NarrationFlow.prePregnancy;
  }

  /// "Tell me about Daddy…" — the partner step.
  String get partner => switch (this) {
    NarrationFlow.pregnant => NarrationKeys.pregPartner,
    NarrationFlow.prePregnancy => NarrationKeys.prePartner,
    NarrationFlow.newMom => NarrationKeys.newPartner,
  };

  /// "Do I already have a big brother or a big sister?"
  String get kids => switch (this) {
    NarrationFlow.pregnant => NarrationKeys.pregKids,
    NarrationFlow.prePregnancy => NarrationKeys.preKids,
    NarrationFlow.newMom => NarrationKeys.newKids,
  };

  /// "Everything is ready. Come, let's go home."
  String get setupDone => switch (this) {
    NarrationFlow.pregnant => NarrationKeys.pregSetupDone,
    NarrationFlow.prePregnancy => NarrationKeys.preSetupDone,
    NarrationFlow.newMom => NarrationKeys.newSetupDone,
  };

  /// "Mommy, this is our home…"
  String get homeWelcome => switch (this) {
    NarrationFlow.pregnant => NarrationKeys.pregHomeWelcome,
    NarrationFlow.prePregnancy => NarrationKeys.preHomeWelcome,
    NarrationFlow.newMom => NarrationKeys.newHomeWelcome,
  };

  /// "Shall we start? …"
  String get homeFirstQuestion => switch (this) {
    NarrationFlow.pregnant => NarrationKeys.pregHomeFirstQuestion,
    NarrationFlow.prePregnancy => NarrationKeys.preHomeFirstQuestion,
    NarrationFlow.newMom => NarrationKeys.newHomeFirstQuestion,
  };

  /// The line that follows the welcome on the home page, where the journey has
  /// one: the mic hint while pregnant, the "I'm waiting" while planning, and
  /// the promise to look after her too once the baby is here.
  String get homeFollowUp => switch (this) {
    NarrationFlow.pregnant => NarrationKeys.pregHomeMicHint,
    NarrationFlow.prePregnancy => NarrationKeys.preHomeWaiting,
    NarrationFlow.newMom => NarrationKeys.newHomeMotherCare,
  };
}

/// Which third of the pregnancy an LMP puts her in.
///
/// Counted in completed weeks from the LMP, the same basis the rest of the app
/// dates a pregnancy from: 0–13 first, 14–27 second, 28 on third.
String trimesterNarrationKey(DateTime lmp, {DateTime? now}) {
  final weeks = (now ?? DateTime.now()).difference(lmp).inDays ~/ 7;
  if (weeks < 14) return NarrationKeys.pregLmpStageT1;
  if (weeks < 28) return NarrationKeys.pregLmpStageT2;
  return NarrationKeys.pregLmpStageT3;
}

/// How the countdown to the due date is described, by days still to go.
///
/// Four bands rather than a number, because the recordings are fixed lines:
/// the whole stretch ahead, past the halfway mark, the last couple of months,
/// and the fortnight when it could be any day.
String countdownNarrationKey(int daysRemaining) {
  if (daysRemaining <= 14) return NarrationKeys.pregEddCountdownSoon;
  if (daysRemaining <= 60) return NarrationKeys.pregEddCountdownNear;
  if (daysRemaining <= 140) return NarrationKeys.pregEddCountdownHalf;
  return NarrationKeys.pregEddCountdownFar;
}
