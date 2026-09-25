/// The actions an offline flow can trigger on this device.
///
/// A flow's `action` step names one of these; anything not registered here is
/// reported back as unhandled rather than failing the turn, so a flow authored
/// against a newer app still runs — it just cannot perform that one effect.
library;

import 'package:flutter/material.dart';

import 'package:allomom/features/allobot/allobot_page.dart';
import 'package:allomom/features/allobot/pages/daily_activity_page.dart';
import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/baby/my_babies_page.dart';
import 'package:allomom/features/cycle_tracker/cycle_tracker_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/feeds/feeds_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/my_health/details/blood_glucose_detail_page.dart';
import 'package:allomom/features/my_health/details/blood_pressure_detail_page.dart';
import 'package:allomom/features/my_health/details/heart_rate_detail_page.dart';
import 'package:allomom/features/my_health/details/hemoglobin_detail_page.dart';
import 'package:allomom/features/my_health/details/sleep_detail_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart';
import 'package:allomom/features/my_health/vitals/drinks/drinks_overview_screen.dart';
import 'package:allomom/features/my_health/vitals/meals/snacks_overview_screen.dart';
import 'package:allomom/features/offline_chatbot/actions/baby_voice_action.dart';
import 'package:allomom/features/offline_chatbot/actions/log_care_action.dart';
import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
import 'package:allomom/features/offline_chatbot/actions/open_page_action.dart';
import 'package:allomom/features/offline_chatbot/actions/show_family_code_action.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/todays_care_checklist_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_journey_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/prescriptions/prescriptions_page.dart';
import 'package:allomom/features/reminders/reminders_page.dart';
import 'package:allomom/features/reports/reports_page.dart';
import 'package:allomom/features/settings/edit_profile_page.dart';
import 'package:allomom/features/settings/settings_page.dart';

export 'package:allomom/features/offline_chatbot/actions/baby_voice_action.dart';
export 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
export 'package:allomom/features/offline_chatbot/actions/open_page_action.dart';
export 'package:allomom/features/offline_chatbot/actions/open_sheet_action.dart';

class OfflineChatbotActions {
  OfflineChatbotActions._();

  static const _openHome = OpenHomeAction();

  static final _openKickCounter = OpenPageAction(
    name: 'open_kick_counter',
    description: "Opens the Kick Counter to record the baby's movements.",
    label: 'Kick Counter',
    builder: (_) => const KickCounterPage(),
  );

  static final _openAlloCry = OpenPageAction(
    name: 'open_allocry',
    description: 'Opens AlloCry, which listens to a cry and names its reason.',
    label: 'AlloCry',
    builder: (_) => const AlloCryPage(),
  );

  static final _openHealth = OpenPageAction(
    name: 'open_my_health',
    description: 'Opens My Health — vitals, readings and trends.',
    label: 'My Health',
    builder: (_) => const MyHealthPage(),
  );

  static final _openReports = OpenPageAction(
    name: 'open_reports',
    description: 'Opens the lab and scan reports.',
    label: 'Reports',
    builder: (_) => const ReportsPage(),
  );

  static final _openPrescriptions = OpenPageAction(
    name: 'open_prescriptions',
    description: 'Opens the prescriptions and their daily timings.',
    label: 'Prescriptions',
    builder: (_) => const PrescriptionsPage(),
  );

  static final _openAnc = OpenPageAction(
    name: 'open_anc_schedule',
    description: 'Opens the antenatal checkup schedule.',
    label: 'ANC Schedule',
    builder: (_) => const AncSchedulePage(),
  );

  static final _openVaccination = OpenPageAction(
    name: 'open_vaccination_schedule',
    description: 'Opens the vaccination and immunisation schedule.',
    label: 'Vaccination Schedule',
    builder: (_) => const VaccinationSchedulePage(),
  );

  static final _openLabSchedule = OpenPageAction(
    name: 'open_lab_schedule',
    description: 'Opens the lab test schedule for this pregnancy.',
    label: 'Lab Schedule',
    builder: (_) => const LabReportsSchedulePage(),
  );

  static final _openJourney = OpenPageAction(
    name: 'open_pregnancy_journey',
    description: 'Opens the week-by-week pregnancy journey.',
    label: 'Pregnancy Journey',
    builder: (_) => const PregnancyJourneyPage(),
  );

  static final _openFeeding = OpenPageAction(
    name: 'open_feeding_tracker',
    description: 'Opens the feeding tracker.',
    label: 'Feeding Tracker',
    builder: (_) => const FeedingTrackerPage(),
  );

  static final _openCycle = OpenPageAction(
    name: 'open_cycle_tracker',
    description: 'Opens the cycle tracker.',
    label: 'Cycle Tracker',
    builder: (_) => const CycleTrackerPage(),
  );

  static final _openBabies = OpenPageAction(
    name: 'open_my_babies',
    description: 'Opens the list of babies and their details.',
    label: 'My Babies',
    builder: (_) => const MyBabiesPage(),
  );

  static final _openFamily = OpenPageAction(
    name: 'open_family',
    description: 'Opens the care circle — family, doctors and contacts.',
    label: 'My People',
    builder: (_) => const PeoplePage(),
  );

  static final _openCommunity = OpenPageAction(
    name: 'open_community',
    description: 'Opens the Community tab — other mothers\' groups and posts.',
    label: 'Community',
    builder: (_) => const PeoplePage(initialTab: 1),
  );

  static final _openFeed = OpenPageAction(
    name: 'open_feed',
    description: 'Opens the feed.',
    label: 'Feed',
    builder: (_) => const FeedsPage(),
  );

  static final _openReminders = OpenPageAction(
    name: 'open_reminders',
    description: 'Opens the reminders.',
    label: 'Reminders',
    builder: (_) => const RemindersPage(),
  );

  static final _openSettings = OpenPageAction(
    name: 'open_settings',
    description: 'Opens the app settings.',
    label: 'Settings',
    builder: (_) => const SettingsPage(),
  );

  static final _openEditProfile = OpenPageAction(
    name: 'open_edit_profile',
    description: 'Opens the profile editor.',
    label: 'Edit Profile',
    builder: (_) => const EditProfilePage(),
  );

  static const _enableSpeech = SetBabyVoiceAction(enable: true);
  static const _disableSpeech = SetBabyVoiceAction(enable: false);

  /// Family-add actions go to the People screen with the relationship
  /// pre-selected there, rather than popping `AddFamilyMemberSheet` straight
  /// over the chat — "add father" is a shortcut into the real screen, not a
  /// parallel mini-UI bolted onto the chatbot.
  static OpenPageAction _addFamilyMember(String actionName, String relationship) {
    return OpenPageAction(
      name: actionName,
      description: "Goes to People and opens Add Member pre-set to '$relationship'.",
      label: 'Add $relationship',
      builder: (_) => PeoplePage(pendingAddMemberRelationship: relationship),
    );
  }

  static final _addMother = _addFamilyMember('mother_add', 'Mother');
  static final _addFather = _addFamilyMember('father_add', 'Father');
  static final _addBrother = _addFamilyMember('brother_add', 'Brother');
  static final _addSister = _addFamilyMember('sister_add', 'Sister');
  static final _addPartner = _addFamilyMember('partner_add', 'Wife');
  static final _addGrandmother = _addFamilyMember('grandmother_add', 'Grandmother');
  static final _addGrandfather = _addFamilyMember('grandfather_add', 'Grandfather');
  static final _addRelative = _addFamilyMember('relative_add', 'Relative');

  static const _showFamilyCode = ShowFamilyCodeAction();

  static final _openVaccineAdd = OpenPageAction(
    name: 'open_add_vaccine',
    description: 'Opens the vaccination schedule to add a vaccine.',
    label: 'Vaccination Schedule',
    builder: (_) => const VaccinationSchedulePage(),
  );

  static final _openBloodGlucose = OpenPageAction(
    name: 'open_blood_glucose',
    description: 'Opens the blood glucose readings.',
    label: 'Blood Glucose',
    builder: (_) => const BloodGlucoseDetailPage(),
  );

  static final _openBloodPressure = OpenPageAction(
    name: 'open_blood_pressure',
    description: 'Opens the blood pressure readings.',
    label: 'Blood Pressure',
    builder: (_) => const BloodPressureDetailPage(),
  );

  static final _openHeartRate = OpenPageAction(
    name: 'open_heart_rate',
    description: 'Opens the heart rate readings.',
    label: 'Heart Rate',
    builder: (_) => const HeartRateDetailPage(),
  );

  static final _openHemoglobin = OpenPageAction(
    name: 'open_hemoglobin',
    description: 'Opens the hemoglobin readings.',
    label: 'Hemoglobin',
    builder: (_) => const HemoglobinDetailPage(),
  );

  static final _openDrinks = OpenPageAction(
    name: 'open_drinks_sheet',
    description: 'Opens the drinks overview.',
    label: 'Drinks',
    builder: (_) => const DrinksOverviewScreen(),
  );

  static final _openSleep = OpenPageAction(
    name: 'open_sleep_sheet',
    description: 'Opens the sleep overview.',
    label: 'Sleep',
    builder: (_) => const SleepDetailPage(),
  );

  static final _openSnacks = OpenPageAction(
    name: 'open_snacks_sheet',
    description: 'Opens the snacks overview.',
    label: 'Snacks',
    builder: (_) => const SnacksOverviewScreen(),
  );

  static final _openActivity = OpenPageAction(
    name: 'open_activity_sheet',
    description: "Opens today's activity.",
    label: 'Activity',
    builder: (_) => const DailyActivityPage(),
  );

  static final _openTodayCare = OpenPageAction(
    name: 'open_today_care',
    description: "Opens Today's Care checklist.",
    label: "Today's Care",
    builder: (_) => const TodaysCareChecklistPage(),
  );

  static final _openLanguageSettings = OpenPageAction(
    name: 'open_language_settings',
    description: 'Opens the language settings.',
    label: 'Language Settings',
    builder: (_) => const LanguageSelectionPage(),
  );

  static final _openAgents = OpenPageAction(
    name: 'open_agents',
    description: 'Opens the Allobot Agents tab.',
    label: 'Agents',
    builder: (_) => const AlloBotPage(initialTab: 1),
  );

  static final _logBreakfast = LogMealAction(
    meal: CareMeal.breakfast,
    icon: Icons.free_breakfast_rounded,
    color: const Color(0xffFF9800),
  );

  static final _logLunch = LogMealAction(
    meal: CareMeal.lunch,
    icon: Icons.lunch_dining_rounded,
    color: const Color(0xffEF6C00),
  );

  static final _logDinner = LogMealAction(
    meal: CareMeal.dinner,
    icon: Icons.dinner_dining_rounded,
    color: const Color(0xffD84315),
  );

  static const _logWater = LogWaterAction();

  /// Every name a flow may use, with the aliases an author is likely to reach
  /// for. Matched case-insensitively after trimming.
  static final Map<String, OfflineChatbotAction> _registry = {
    _openHome.name: _openHome,
    'home': _openHome,
    'go_home': _openHome,
    'home_page': _openHome,

    _openKickCounter.name: _openKickCounter,
    'kick_counter': _openKickCounter,
    'kicks': _openKickCounter,
    'count_kicks': _openKickCounter,

    _openAlloCry.name: _openAlloCry,
    'allocry': _openAlloCry,
    'cry': _openAlloCry,
    'cry_detection': _openAlloCry,
    'action.tools.open_allocry': _openAlloCry,

    _openHealth.name: _openHealth,
    'open_health': _openHealth,
    'my_health': _openHealth,
    'health': _openHealth,
    'vitals': _openHealth,

    _openReports.name: _openReports,
    'reports': _openReports,
    'lab_reports': _openReports,
    'scans': _openReports,

    _openPrescriptions.name: _openPrescriptions,
    'open_prescription': _openPrescriptions,
    'prescriptions': _openPrescriptions,
    'medicines': _openPrescriptions,
    'medication': _openPrescriptions,

    _openAnc.name: _openAnc,
    'anc': _openAnc,
    'anc_schedule': _openAnc,
    'checkups': _openAnc,

    _openVaccination.name: _openVaccination,
    'vaccination': _openVaccination,
    'vaccines': _openVaccination,
    'immunization': _openVaccination,

    _openLabSchedule.name: _openLabSchedule,
    'lab_schedule': _openLabSchedule,
    'lab_tests': _openLabSchedule,

    _openJourney.name: _openJourney,
    'pregnancy_journey': _openJourney,
    'journey': _openJourney,
    'baby_growth': _openJourney,
    'open_pregnancy_week': _openJourney,
    'pregnancy_week': _openJourney,
    'action.tools.show_pregnancy_progress': _openJourney,

    _openFeeding.name: _openFeeding,
    'feeding_tracker': _openFeeding,
    'feeding': _openFeeding,
    'breastfeeding': _openFeeding,

    _openCycle.name: _openCycle,
    'cycle_tracker': _openCycle,
    'cycle': _openCycle,
    'periods': _openCycle,

    _openBabies.name: _openBabies,
    'my_babies': _openBabies,
    'babies': _openBabies,

    _openFamily.name: _openFamily,
    'family': _openFamily,
    'my_family': _openFamily,
    'people': _openFamily,
    'contacts': _openFamily,

    _openCommunity.name: _openCommunity,
    'community': _openCommunity,
    'communities': _openCommunity,
    'my_community': _openCommunity,

    _openFeed.name: _openFeed,
    'feed': _openFeed,
    'feeds': _openFeed,
    'news': _openFeed,

    _openReminders.name: _openReminders,
    'reminders': _openReminders,
    'my_reminders': _openReminders,
    'manage_reminders': _openReminders,

    _openSettings.name: _openSettings,
    'settings': _openSettings,
    'preferences': _openSettings,

    _openEditProfile.name: _openEditProfile,
    'edit_profile': _openEditProfile,
    'profile': _openEditProfile,
    'my_profile': _openEditProfile,

    _enableSpeech.name: _enableSpeech,
    'turn_on_speech': _enableSpeech,
    'speech_on': _enableSpeech,
    'enable_voice': _enableSpeech,

    _disableSpeech.name: _disableSpeech,
    'turn_off_speech': _disableSpeech,
    'speech_off': _disableSpeech,
    'disable_voice': _disableSpeech,

    _addMother.name: _addMother,
    'add_mother': _addMother,

    _addFather.name: _addFather,
    'add_father': _addFather,

    _addBrother.name: _addBrother,
    'add_brother': _addBrother,

    _addSister.name: _addSister,
    'add_sister': _addSister,

    _addRelative.name: _addRelative,
    'add_relative': _addRelative,

    _addPartner.name: _addPartner,
    'add_partner': _addPartner,

    _addGrandmother.name: _addGrandmother,
    'add_grandmother': _addGrandmother,

    _addGrandfather.name: _addGrandfather,
    'add_grandfather': _addGrandfather,

    _showFamilyCode.name: _showFamilyCode,
    'family_code': _showFamilyCode,
    'invite_code': _showFamilyCode,

    _logBreakfast.name: _logBreakfast,
    'log_breakfast': _logBreakfast,

    _logLunch.name: _logLunch,
    'log_lunch': _logLunch,

    _logDinner.name: _logDinner,
    'log_dinner': _logDinner,

    _logWater.name: _logWater,
    'log_water': _logWater,
    'drink_water': _logWater,

    _openVaccineAdd.name: _openVaccineAdd,
    'add_vaccine': _openVaccineAdd,

    _openBloodGlucose.name: _openBloodGlucose,
    'blood_glucose': _openBloodGlucose,

    _openBloodPressure.name: _openBloodPressure,
    'blood_pressure': _openBloodPressure,

    _openHeartRate.name: _openHeartRate,
    'heart_rate': _openHeartRate,

    _openHemoglobin.name: _openHemoglobin,
    'hemoglobin': _openHemoglobin,

    _openDrinks.name: _openDrinks,
    'drinks': _openDrinks,

    _openSleep.name: _openSleep,
    'sleep': _openSleep,

    _openSnacks.name: _openSnacks,
    'snacks': _openSnacks,

    _openActivity.name: _openActivity,
    'activity': _openActivity,
    'daily_activity': _openActivity,

    _openTodayCare.name: _openTodayCare,
    'todays_care': _openTodayCare,

    // No dedicated workout page yet — the health overview is the closest
    // real screen, so "open workout" lands there rather than nowhere.
    'open_workout': _openHealth,
    'workout': _openHealth,

    _openLanguageSettings.name: _openLanguageSettings,
    'language_settings': _openLanguageSettings,
    'language': _openLanguageSettings,

    _openAgents.name: _openAgents,
    'agents': _openAgents,

    // AlloWear pairing is a dialog inside Settings, not its own page — the
    // redirect goes to the screen that hosts it.
    'open_allowear': _openSettings,
    'allowear': _openSettings,

    // Name mismatches between the flow-builder export and this registry —
    // same destinations under the names those flows already use.
    'open_anc_calendar': _openAnc,
    'open_baby_journey': _openJourney,
    'open_health_section': _openHealth,
    'open_pregnancy_page': _openJourney,
    'open_reports_sheet': _openReports,
  };

  /// Every action name a flow may use, for the builder's reference.
  static List<String> get names => _registry.keys.toList()..sort();

  static OfflineChatbotAction? find(String? name) {
    var key = (name ?? '').trim().toLowerCase();
    if (key.endsWith('()')) {
      key = key.substring(0, key.length - 2).trim();
    }
    return key.isEmpty ? null : _registry[key];
  }

  /// An action step's payload is whatever the author typed — a JSON object, a
  /// bare string, or nothing. Normalise it to a map so every action reads its
  /// arguments the same way; a bare string becomes `{"mode": "..."}`, which is
  /// what `open_my_health: vitals` is plainly meant to say.
  static Map<String, dynamic> normalizeData(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return {'mode': raw.trim()};
    }
    return const {};
  }

  /// Runs the action a flow asked for. Never throws — a broken action reports
  /// itself instead of derailing the conversation.
  static Future<ActionResult> run(String? name, dynamic data) async {
    final action = find(name);
    if (action == null) return ActionResult.unhandled(name ?? '');

    try {
      return await action.run(normalizeData(data));
    } catch (e) {
      return ActionResult.failed('Could not run "$name": $e');
    }
  }
}
