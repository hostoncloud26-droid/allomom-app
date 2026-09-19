import 'package:allomom/features/background_audio/data/narration_keys.dart';

/// Where a group of clips lives, and how its files are named.
///
/// The two batches were recorded separately and arrived named differently —
/// onboarding as `onb_lang.mp3`, the in-app screens as `pg_home_open_en.mp3`.
/// Rather than renaming 157 files, the difference is declared once here.
enum NarrationGroup {
  /// The sign-up script: `assets/audio/<lang>/onboard/<key>.mp3`.
  onboarding('onboard', languageSuffixed: false),

  /// Every screen after sign-up: `assets/audio/<lang>/screens/<key>_<lang>.mp3`.
  screens('screens', languageSuffixed: true);

  const NarrationGroup(this.folder, {required this.languageSuffixed});

  /// Folder under `assets/audio/<lang>/`.
  final String folder;

  /// Whether the file name repeats the language code.
  final bool languageSuffixed;

  String fileName(String key, String languageCode) =>
      languageSuffixed ? '${key}_$languageCode.mp3' : '$key.mp3';

  String assetPath(String languageCode, String key) =>
      'assets/audio/$languageCode/$folder/${fileName(key, languageCode)}';
}

/// The script the baby speaks, keyed by the same keywords as the mp3 files.
///
/// The text here is what the baby head card shows while the clip plays, so the
/// mother can read along with her sound off. Only English is written out — a
/// language with no entry falls back to the English line while still playing
/// its own clip, so adding `hi`/`ta`/`kn`/`te` later is a matter of dropping
/// the mp3s into `assets/audio/<code>/` and adding a map below.
class NarrationCatalog {
  NarrationCatalog._();

  /// Folder under `assets/audio/<lang>/` that holds the onboarding clips.
  ///
  /// Kept for call sites that predate [NarrationGroup]; new code asks the
  /// group.
  static const String folder = 'onboard';

  static const String fallbackLanguage = 'en';

  /// Which batch [key] was recorded in. Unknown keys are treated as
  /// onboarding, which is where the flow starts.
  static NarrationGroup groupFor(String key) => _screensEn.containsKey(key)
      ? NarrationGroup.screens
      : NarrationGroup.onboarding;

  static String assetPath(String languageCode, String key) =>
      groupFor(key).assetPath(languageCode, key);

  /// The line for [key] in [languageCode], falling back to English.
  static String? textFor(String key, {String languageCode = fallbackLanguage}) {
    final localised = _byLanguage[languageCode]?[key];
    if (localised != null && localised.isNotEmpty) return localised;
    return _all[key];
  }

  static bool contains(String key) => _all.containsKey(key);

  static Iterable<String> get keys => _all.keys;

  /// Every line, both batches, in one lookup.
  static final Map<String, String> _all = {..._en, ..._screensEn};

  static final Map<String, Map<String, String>> _byLanguage = {
    fallbackLanguage: _all,
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

  /// The in-app screens, recorded as a second batch.
  ///
  /// One line per screen, plus a `pgConf*` line for each save. The screen lines
  /// tell her what a page is for the first time she opens it; the confirmations
  /// tell her the thing she just did landed.
  static const Map<String, String> _screensEn = {
    // ─── Home ───
    NarrationKeys.pgHomeOpen:
        "Everything about today is here, Mommy. Your food, your water, your rest — I'll keep track.",
    NarrationKeys.pgHomeCare:
        'These are the small things to finish today. One by one, Mommy.',
    NarrationKeys.pgHomeSummary:
        "This shows how far we've come and how much is left, Mommy.",
    NarrationKeys.pgHomeVitals:
        "Your body's readings are here, Mommy. Steps, heart, sleep.",

    // ─── Pregnancy journey ───
    NarrationKeys.pgJourneyOpen:
        "This is our whole journey, Mommy. Which week we're in, when we'll meet, and what's coming next.",
    NarrationKeys.pgJourneyUpcoming:
        "These are the visits and tests coming up soon, Mommy. I'll remind you before each one.",
    NarrationKeys.pgJourneyBabies:
        'You can add your newborn or an older child here, Mommy.',
    NarrationKeys.pgJourneyComplete:
        "When I arrive in your arms, tap here, Mommy. Then we'll start looking after me together.",
    NarrationKeys.pgJourneyDelete:
        "Mommy, this will gently remove our whole record and we'd start again from the beginning. Are you sure?",

    // ─── Care schedules ───
    NarrationKeys.pgAncOpen:
        "All our doctor visits are here, Mommy. I'll call you before every one.",
    NarrationKeys.pgAncEmpty:
        "No visits are picked yet, Mommy. Register the pregnancy and I'll set them month by month.",
    NarrationKeys.pgLabOpen:
        "Every blood test, urine test and scan is listed here, Mommy, in the month it's due.",
    NarrationKeys.pgLabEmpty:
        "Nothing is listed yet, Mommy. Register the pregnancy and I'll lay them all out for you.",
    NarrationKeys.pgVaccOpen:
        'Your injections and mine are here, Mommy. They keep us both safe.',
    NarrationKeys.pgVaccEmpty:
        "Nothing is booked yet, Mommy. Register the pregnancy and I'll book each one for the right month.",

    // ─── Vitals ───
    NarrationKeys.pgVitalsOpen:
        'Your readings live here, Mommy. Blood pressure, sugar, and your blood count.',
    NarrationKeys.pgVitalsBp:
        "Tell me the two numbers from the machine and I'll save them, Mommy.",
    NarrationKeys.pgVitalsGlucose:
        'Tell me the sugar reading, and whether it was before food or after, Mommy.',
    NarrationKeys.pgVitalsHb:
        'Tell me the hemoglobin from your blood report, Mommy. This one matters most for your strength.',
    NarrationKeys.pgVitalsEmpty:
        "Nothing is added yet, Mommy. Give me one reading and I'll start watching for you.",

    // ─── Nutrition ───
    NarrationKeys.pgNutritionOpen:
        'Everything you eat and drink today goes here, Mommy. Just tell me.',
    NarrationKeys.pgNutritionMeal:
        "Tell me what you ate, and I'll note it down for you, Mommy.",
    NarrationKeys.pgNutritionWater:
        "Every time you drink water, tap here, Mommy. I'll keep the count for you.",
    NarrationKeys.pgNutritionSnacks:
        'Small snacks in between are good for us, Mommy. Add them here too.',
    NarrationKeys.pgNutritionReminder:
        "Shall I call you at meal times, Mommy? Then you won't forget.",

    // ─── Feeds ───
    NarrationKeys.pgFeedsOpen:
        'Small tips and easy recipes for you, Mommy. Listen while you work.',
    NarrationKeys.pgFeedsRecipe:
        "This is something simple you can make from what's already in your kitchen, Mommy.",
    NarrationKeys.pgFeedsOffline:
        'A few of these are kept on the phone, Mommy. You can hear them even without internet.',

    // ─── Family ───
    NarrationKeys.pgFamilyOpen:
        'This is where Appa and the family join us, Mommy.',
    NarrationKeys.pgFamilyEmpty:
        'No one has joined yet, Mommy. Make our family, or enter the code someone gave you.',
    NarrationKeys.pgFamilyCreate: 'Give our family a name, Mommy.',
    NarrationKeys.pgFamilyCreated:
        'Our family is made, Mommy. Now share the code with Appa so he can join.',
    NarrationKeys.pgFamilyJoin:
        'Enter the six-letter code they gave you, Mommy.',
    NarrationKeys.pgFamilyJoined:
        "You've joined, Mommy. Now we're all together.",
    NarrationKeys.pgFamilyCode:
        'This is our family code, Mommy. Show it to them, or share it.',

    // ─── Community ───
    NarrationKeys.pgCommunityOpen:
        'Other mothers like you are here, Mommy. You can ask them, and share with them.',
    NarrationKeys.pgCommunityOffline:
        "This one needs internet, Mommy. Let's come back when we're connected.",
    NarrationKeys.pgCommunityDisclaimer:
        'This is what other mothers say, Mommy. For your health, always ask the doctor.',

    // ─── Settings ───
    NarrationKeys.pgSettingsOpen:
        'You can change how I talk to you, and what I remind you about, here, Mommy.',
    NarrationKeys.pgSettingsProfile:
        "Your details are here, Mommy. Change anything that isn't right.",
    NarrationKeys.pgSettingsTimeline:
        "If the doctor changes the date, tell me here and I'll count again, Mommy.",
    NarrationKeys.pgSettingsBand:
        'Connect your Allowear band here, Mommy, and I can look after you all day — even while you sleep.',
    NarrationKeys.pgSettingsBandMac:
        "Enter the number printed on your Allowear band, Mommy. Take your time, there's no hurry.",
    NarrationKeys.pgSettingsBandOk:
        'Your Allowear band is connected, Mommy. Now I can watch over you on my own.',
    NarrationKeys.pgSettingsLanguage:
        "Choose the language you're most comfortable in, Mommy. I'll talk that way from now.",
    NarrationKeys.pgSettingsVoice:
        'If I talk too fast or too softly, you can fix it here, Mommy.',

    // ─── Reminders ───
    NarrationKeys.pgRemindersOpen:
        'All your reminders are here, Mommy. Turn on whatever you need, and switch off the rest.',
    NarrationKeys.pgRemindersWater:
        "Turn this on, Mommy, and I'll gently remind you to drink water through the day.",
    NarrationKeys.pgRemindersMedicine:
        "Turn this on, Mommy, and I'll softly remind you about your iron, calcium and folic acid.",
    NarrationKeys.pgRemindersAdd:
        'Tell me what to remind you about, and at what time, Mommy.',

    // ─── AlloBot ───
    NarrationKeys.pgAllobotOpen:
        'Ask me anything, Mommy. About me, about your body, about anything at all.',
    NarrationKeys.pgAllobotListening: "I'm listening, Mommy. Tell me.",
    NarrationKeys.pgAllobotTopics:
        "If you're not sure what to ask, pick one of these and I'll take it from there, Mommy.",
    NarrationKeys.pgAllobotOffline:
        'Without internet I can answer only the common questions, Mommy. The rest can wait.',
    NarrationKeys.pgAllobotDisclaimer:
        "I'm here to help, Mommy, but the doctor's word is always final.",

    // ─── Confirmations ───
    NarrationKeys.pgConfReminderSet:
        'Your reminder is set, Mommy. Rest easy now.',
    NarrationKeys.pgConfReminderWater:
        "Your water reminder is set, Mommy. I'll be with you through the day.",
    NarrationKeys.pgConfReminderMedicine:
        "Your medicine reminder is set, Mommy. You won't have to remember it alone now.",
    NarrationKeys.pgConfReminderMeal:
        "Your meal reminder is set, Mommy. I'll be there at every meal time.",
    NarrationKeys.pgConfReminderSleep:
        "Your sleep reminder is set, Mommy. At night I'll tell you softly when it's time to rest.",
    NarrationKeys.pgConfReminderOff:
        "I've turned it off, Mommy. Switch it on again whenever you feel like it.",
    NarrationKeys.pgConfReminderTime:
        "The time is changed, Mommy. I'll come at the new time now.",
    NarrationKeys.pgConfReminderDeleted:
        "I've removed it, Mommy. You can always add it back.",
    NarrationKeys.pgConfAncSaved:
        "Your visit is saved, Mommy. I'll call you before the day comes.",
    NarrationKeys.pgConfLabSaved:
        "The test is saved, Mommy. I'll remind you in good time.",
    NarrationKeys.pgConfVaccSaved:
        "The vaccine is saved, Mommy. I won't let it be missed.",
    NarrationKeys.pgConfVitalsSaved: 'Saved, Mommy. Thank you for telling me.',
    NarrationKeys.pgConfMealSaved:
        "I've noted it down, Mommy. You ate well today.",
    NarrationKeys.pgConfWaterAdded:
        "Added, Mommy. That's good — keep sipping through the day.",
    NarrationKeys.pgConfBandSaved:
        "Your Allowear band is saved, Mommy. I'll start watching over you now.",
    NarrationKeys.pgConfProfileSaved:
        'Your details are saved, Mommy. Everything looks right now.',
    NarrationKeys.pgConfLanguageSaved:
        "Done, Mommy. I'll speak to you in this language from now on.",
    NarrationKeys.pgConfVoiceSaved: 'Done, Mommy. Is this easier to hear now?',
    NarrationKeys.pgConfBabyAdded:
        'Your little one is added, Mommy. Now I know about them too.',
    NarrationKeys.pgConfJourneyDone:
        'Congratulations, Mommy. Our journey together is complete, and a new one begins today.',
    NarrationKeys.pgConfFamilySaved:
        'Our family is ready, Mommy. Share the code and they can come in.',
  };
}
