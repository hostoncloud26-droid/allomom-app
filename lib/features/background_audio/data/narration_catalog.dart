import 'package:allomom/features/background_audio/data/narration_keys.dart';

/// The script the baby speaks, keyed by the same keywords as the mp3 files.
///
/// Clips live at `assets/audio/<lang>/onboard/<key>.mp3`; the text here is what
/// the baby head card shows while the clip plays, so the mother can read along
/// with her sound off. Only English is written out — a language with no entry
/// falls back to the English line while still playing its own clip, so adding
/// `hi`/`ta`/`kn`/`te` later is a matter of dropping the mp3s into
/// `assets/audio/<code>/onboard/` and adding a map below.
class NarrationCatalog {
  NarrationCatalog._();

  /// Folder under `assets/audio/<lang>/` that holds the onboarding clips.
  static const String folder = 'onboard';

  static const String fallbackLanguage = 'en';

  static String assetPath(String languageCode, String key) =>
      'assets/audio/$languageCode/$folder/$key.mp3';

  /// The line for [key] in [languageCode], falling back to English.
  static String? textFor(String key, {String languageCode = fallbackLanguage}) {
    final localised = _byLanguage[languageCode]?[key];
    if (localised != null && localised.isNotEmpty) return localised;
    return _en[key];
  }

  static bool contains(String key) => _en.containsKey(key);

  static Iterable<String> get keys => _en.keys;

  static const Map<String, Map<String, String>> _byLanguage = {
    fallbackLanguage: _en,
  };

  static const Map<String, String> _en = {
    // ─── Onboarding: language ───
    NarrationKeys.onbLang: 'Hello! Which language should we speak in?',
    NarrationKeys.onbLangSelected:
        "Lovely. From now we'll talk in this language.",
    NarrationKeys.onbLangOther:
        'That language is coming soon. Shall we use English for now?',

    // ─── Onboarding: mobile number ───
    NarrationKeys.onbMobile:
        "What's your mobile number, so I can stay close to you?",
    NarrationKeys.onbMobileInvalid:
        "That number doesn't look complete. Please check once.",
    NarrationKeys.onbMobileInternet:
        'Just for this step we need internet. After this I can stay with you even without it.',
    NarrationKeys.onbMobileGoogle:
        "If it's easier, you can continue with Google.",

    // ─── Onboarding: OTP ───
    NarrationKeys.onbOtp:
        "I've sent a secret 6-digit code to your phone. It will come by SMS and on WhatsApp.",
    NarrationKeys.onbOtpWhere: 'Look in your messages, and also in WhatsApp.',
    NarrationKeys.onbOtpWrong:
        "That code isn't matching. Please check and type it again.",
    NarrationKeys.onbOtpResend:
        "I'll send it once more. Watch for the SMS and the WhatsApp message.",
    NarrationKeys.onbOtpSuccess:
        "We're in! Thank you for letting me come to you.",

    // ─── Onboarding: role ───
    NarrationKeys.onbRole: 'Yay! Are you my Mommy, or my Daddy?',
    NarrationKeys.onbRoleMom: "Mommy! I'm so happy it's you.",
    NarrationKeys.onbRoleDad: "Daddy! Let's look after Mommy together.",

    // ─── Onboarding: name ───
    NarrationKeys.onbNamePromptMom: 'Mommy, what is your name?',
    NarrationKeys.onbNamePromptDad: 'Daddy, what is your name?',
    NarrationKeys.onbNameReaction: 'What a lovely name!',
    NarrationKeys.onbNameEmpty:
        'Tell me your name, so I know what to call you.',

    // ─── Onboarding: status ───
    NarrationKeys.onbStatus: 'Tell me where we are on our journey.',
    NarrationKeys.onbStatusPregnant:
        "You're carrying me right now! I'm here with you.",
    NarrationKeys.onbStatusPrePregnancy:
        "You're getting ready for me. I'm waiting to come to you.",
    NarrationKeys.onbStatusNewMom:
        "I'm already in your arms! Let's look after me together.",

    // ─── Pregnant: LMP ───
    NarrationKeys.pregLmp: 'Mommy, when did your last period start?',
    NarrationKeys.pregLmpWhy:
        "I'm asking because this tells us the day we will meet.",
    NarrationKeys.pregLmpUnknown:
        "If you don't remember the exact date, give the closest one. The doctor's scan will confirm it.",
    NarrationKeys.pregLmpFutureError:
        'That date is after today. Please check once.',
    NarrationKeys.pregLmpConfirm:
        'All done! Now I know exactly which week we are in.',
    NarrationKeys.pregLmpStageT1:
        "We're in the early months. I'm still very tiny.",
    NarrationKeys.pregLmpStageT2:
        "We're in the middle months now. This part is usually the easiest.",
    NarrationKeys.pregLmpStageT3:
        "We're already in the last months. Not long to go now.",

    // ─── Pregnant: EDD ───
    NarrationKeys.pregEddBubble:
        "Yay! That's the day we'll meet. I can't wait!",
    NarrationKeys.pregEddDays:
        "That's how many days are left. Then we'll meet.",
    NarrationKeys.pregEddCountdownFar:
        "We have a long and lovely journey ahead. Let's take it slowly.",
    NarrationKeys.pregEddCountdownHalf:
        "We're past halfway. The days are going by.",
    NarrationKeys.pregEddCountdownNear:
        "Not many days left now. I'm getting ready.",
    NarrationKeys.pregEddCountdownSoon:
        'Very soon now. Any day, your arms will be full.',
    NarrationKeys.pregEddDoctorDate:
        'If the doctor gave you a different date, tell me that one instead.',
    NarrationKeys.pregEddSaved: "Saved. I'll count the days with you.",

    // ─── Pregnant: family ───
    NarrationKeys.pregPartner:
        'Tell me about Daddy, so he can be part of our journey too.',
    NarrationKeys.pregPartnerDad:
        'Tell me about Mommy, so I can look after her with you.',
    NarrationKeys.pregPartnerSkip: "That's okay. You can add them anytime.",
    NarrationKeys.pregPartnerSaved: 'Now Daddy is with us too.',
    NarrationKeys.pregKids:
        'Do I already have a big brother or a big sister?',
    NarrationKeys.pregKidsYes: "How lovely! Then I'm not alone.",
    NarrationKeys.pregKidsNo:
        "So I'm your first! That makes this extra special.",

    // ─── Pregnant: done + home ───
    NarrationKeys.pregSetupDone: "Everything is ready. Come, let's go home.",
    NarrationKeys.pregHomeWelcome:
        "Mommy, this is our home. I'll be here for you every day.",
    NarrationKeys.pregHomeMicHint:
        'Whenever you want to talk to me, press the mic and just speak.',
    NarrationKeys.pregHomeFirstQuestion:
        'Shall we start? Have you eaten today?',

    // ─── Pre-pregnancy ───
    NarrationKeys.preCycle: 'Mommy, when did your last period start?',
    NarrationKeys.preCycleLength: 'Usually, how many days is your cycle?',
    NarrationKeys.preCycleIrregular:
        "If it isn't regular, that's alright. Tell me what you remember and we'll learn together.",
    NarrationKeys.preCycleSaved:
        "Saved. I'll tell you your fertile days and when the next period is due.",
    NarrationKeys.preFolicAcid:
        'One important thing. Start folic acid now — it keeps me safe even before I come.',
    NarrationKeys.preHabits:
        "Good food, good sleep, and no tobacco or alcohol. That's how we get ready for me.",
    NarrationKeys.prePartner:
        'Tell me about your partner, so you can plan for me together.',
    NarrationKeys.preKids: 'Do you already have children?',
    NarrationKeys.preSetupDone: "All set. Come, let's go home.",
    NarrationKeys.preHomeWelcome:
        "Mommy, this is our home. I'll keep track of your dates and look after you.",
    NarrationKeys.preHomeWaiting:
        "I'm waiting to come to you. Let's get ready together.",
    NarrationKeys.preHomeFirstQuestion:
        'Shall we start? How are you feeling today?',

    // ─── New mom ───
    NarrationKeys.newBabyName: 'What name did you give me?',
    NarrationKeys.newBabyNameReaction: 'What a beautiful name. I love it.',
    NarrationKeys.newBabyDob: 'When was I born?',
    NarrationKeys.newBabyGender: 'Am I a boy or a girl?',
    NarrationKeys.newBabySaved: 'Now I know all about me. Thank you, Mommy.',
    NarrationKeys.newBabyTwin: 'Do I have a twin? Add them here too.',
    NarrationKeys.newFeedingIntro:
        "You can note down my feeds here, so you don't have to keep remembering.",
    NarrationKeys.newAllocryIntro:
        "When I cry, hold the phone near me. I'll help you understand what I need.",
    NarrationKeys.newVaccineIntro:
        "And don't worry about my injections. I'll remind you every time.",
    NarrationKeys.newPartner:
        'Tell me about Daddy, so he can help look after me too.',
    NarrationKeys.newKids: 'Do I have a big brother or a big sister?',
    NarrationKeys.newSetupDone: "All done. Come, let's go home.",
    NarrationKeys.newHomeWelcome:
        'Mommy, this is our home. My feeds, my sleep, my cries — everything is here.',
    NarrationKeys.newHomeFirstQuestion: 'Shall we start? Did you feed me?',
    NarrationKeys.newHomeMotherCare:
        "And Mommy — I'll look after you too, not just me.",

    // ─── Shared across the whole flow ───
    NarrationKeys.onbAlmostDone: 'Almost there. Just a little more.',
    NarrationKeys.onbBack: 'Going back.',
    NarrationKeys.onbPermMic:
        'Allow the microphone, so I can hear you when you talk.',
    NarrationKeys.onbPermNotification:
        'Allow notifications, so I can remind you at the right time.',
    NarrationKeys.onbOfflineNote:
        "From now, even without internet, I'll be with you.",
  };
}
