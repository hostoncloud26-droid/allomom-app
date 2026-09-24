/// The actions an offline flow can trigger on this device.
///
/// A flow's `action` step names one of these; anything not registered here is
/// reported back as unhandled rather than failing the turn, so a flow authored
/// against a newer app still runs — it just cannot perform that one effect.
library;

import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/baby/my_babies_page.dart';
import 'package:allomom/features/cycle_tracker/cycle_tracker_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/feeds/feeds_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart';
import 'package:allomom/features/offline_chatbot/actions/baby_voice_action.dart';
import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
import 'package:allomom/features/offline_chatbot/actions/open_page_action.dart';
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
