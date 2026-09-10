/// Drives the Home screen's voice companion: owns the flow, speaks through
/// TTS, and performs the writes an answer asks for.
///
/// The impure half of `home_voice_flow.dart`. Kept out of the widget so the
/// home page only has to render `message`, `prompt` and a handful of
/// callbacks, and so the flow's timing rules stay testable on their own.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/allobot/allobot_context.dart';
import 'package:allomom/services/allobot/allobot_context_loader.dart';
import 'package:allomom/services/allobot/allobot_engine.dart' show stripForSpeech;
import 'package:allomom/services/allobot/home_voice_flow.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/services/tts_service.dart';

/// Where an answer wants the mother taken. The widget performs the push.
enum HomeVoiceDestination {
  kickCounter,
  sleepLog,
  symptomLog,
  reportUpload,
}

/// Lets another screen ask the Home screen's voice companion to run the
/// post-visit questions.
///
/// The controller belongs to the Home screen, but the natural moment to ask
/// those questions is when she ticks a visit off in the ANC calendar. Rather
/// than duplicate the flow there — on top of a calendar the questions are not
/// about — the calendar raises a request here and pops back home, where the
/// card is already the place AlloBot talks.
class HomeVoiceLauncher {
  HomeVoiceLauncher._();

  static final HomeVoiceLauncher instance = HomeVoiceLauncher._();

  /// Bumped for each request. A counter rather than a flag so two requests in
  /// a row both register.
  final ValueNotifier<int> ancFollowUpRequests = ValueNotifier<int>(0);

  Future<void> requestAncFollowUp() async {
    ancFollowUpRequests.value++;
  }
}

class HomeVoiceController extends ChangeNotifier {
  HomeVoiceController();

  final TtsService _tts = TtsService();

  HomeVoiceFlow? _flow;

  String _message = '';
  HomePrompt? _prompt;
  bool _isSpeaking = false;
  bool _isVisible = false;
  bool _hasGreeted = false;
  String _language = AppLanguage.fallback;

  /// What AlloBot last said. Also the text shown in the baby card's bubble.
  String get message => _message;

  /// The question awaiting an answer, if any.
  HomePrompt? get prompt => _prompt;

  bool get isSpeaking => _isSpeaking;

  /// Whether the card should be on screen.
  bool get isVisible => _isVisible && _message.isNotEmpty;

  AlloBotContext? get context => _flow?.context;

  /// Where the last answer wants her taken. Cleared by [consumeDestination].
  HomeVoiceDestination? _destination;
  HomeVoiceDestination? get destination => _destination;

  /// Takes the pending destination, clearing it so a rebuild does not navigate
  /// twice.
  HomeVoiceDestination? consumeDestination() {
    final pending = _destination;
    _destination = null;
    return pending;
  }

  /// Greets her and asks the first question.
  ///
  /// Runs once per screen: [_hasGreeted] guards against the rebuilds a GetX
  /// listener or a returning navigation would otherwise trigger.
  Future<void> start() async {
    if (_hasGreeted) return;
    _hasGreeted = true;

    try {
      _language = await AppLanguage.current();
      await _tts.init();
      final loaded = await AlloBotContextLoader.load();
      _flow = HomeVoiceFlow(context: loaded);
    } catch (e) {
      debugPrint('HomeVoiceController: could not start: $e');
      _hasGreeted = false;
      return;
    }

    final flow = _flow!;
    // Only pregnant and postpartum mothers get the unprompted greeting. For
    // anyone else there is no day's care to talk through.
    if (!flow.context.isPregnant && !flow.context.isNewMom) return;

    // An antenatal visit today outranks the daily questions: the four
    // post-visit questions are only useful on the day.
    if (flow.hasAncToday) flow.startAncFollowUp();

    _say(composeHomeGreeting(flow.context), flow.nextPrompt());
  }

  /// Starts the post-visit questions on demand — used when she marks a visit
  /// complete in the ANC calendar.
  Future<void> startAncFollowUp() async {
    if (_flow == null) {
      try {
        _language = await AppLanguage.current();
        await _tts.init();
        _flow = HomeVoiceFlow(context: await AlloBotContextLoader.load());
      } catch (e) {
        debugPrint('HomeVoiceController: could not start ANC follow-up: $e');
        return;
      }
    }
    _hasGreeted = true;

    final flow = _flow!;
    flow.startAncFollowUp();
    _say(
      'Well done for going, mommy. A few things and I will have this visit on '
      'the record.',
      flow.nextPrompt(),
    );
  }

  /// Answers a yes/no question.
  Future<void> answerYesNo(bool affirmed) =>
      _handle((flow, prompt) => flow.answer(prompt, affirmed: affirmed));

  /// Answers a date question.
  Future<void> answerDate(DateTime date) =>
      _handle((flow, prompt) => flow.answer(prompt, date: date));

  /// Answers a text question.
  Future<void> answerText(String text) =>
      _handle((flow, prompt) => flow.answer(prompt, text: text));

  /// Skips the current question without answering it.
  Future<void> skip() => _handle((flow, prompt) => flow.answer(prompt));

  Future<void> _handle(
    HomeFlowResponse Function(HomeVoiceFlow flow, HomePrompt prompt) resolve,
  ) async {
    final flow = _flow;
    final prompt = _prompt;
    if (flow == null || prompt == null) return;

    final response = resolve(flow, prompt);
    await _perform(response);

    // Re-read her data before choosing the next question, so a glass just
    // logged is not asked about again.
    if (response.action != HomeFlowAction.none) {
      try {
        flow.updateContext(await AlloBotContextLoader.load());
      } catch (e) {
        debugPrint('HomeVoiceController: context refresh failed: $e');
      }
    }

    _say(response.reply, flow.nextPrompt());
  }

  /// Hides the card and stops the voice.
  void dismiss() {
    _tts.stop();
    _isSpeaking = false;
    _isVisible = false;
    _prompt = null;
    notifyListeners();
  }

  /// Plays or stops the current message.
  void toggleSpeech() {
    if (_isSpeaking) {
      _tts.stop();
      _isSpeaking = false;
      notifyListeners();
      return;
    }
    _speak(_message, _prompt);
  }

  void _say(String reply, HomePrompt? next) {
    _message = reply;
    _prompt = next;
    _isVisible = true;
    notifyListeners();
    _speak(reply, next);
  }

  void _speak(String reply, HomePrompt? next) {
    final spoken = next == null
        ? stripForSpeech(reply)
        : stripForSpeech('$reply ${next.question}');
    if (spoken.isEmpty) return;

    _isSpeaking = true;
    notifyListeners();
    _tts.speak(
      spoken,
      language: _language,
      onComplete: () {
        _isSpeaking = false;
        notifyListeners();
      },
    );
  }

  // ─── the writes ───

  Future<void> _perform(HomeFlowResponse response) async {
    switch (response.action) {
      case HomeFlowAction.none:
        return;

      case HomeFlowAction.logWater:
        // One glass, as an increment: every reader of these rows sums the day.
        await _logVital(waterVitalKey, 1, 'glasses');

      case HomeFlowAction.logMeal:
        await _logMeal(response.mealKey);

      case HomeFlowAction.logMealDetail:
        await _logMealDetail(response.mealKey, response.text);

      case HomeFlowAction.openKickCounter:
        _destination = HomeVoiceDestination.kickCounter;

      case HomeFlowAction.openSleepLog:
        _destination = HomeVoiceDestination.sleepLog;

      case HomeFlowAction.openSymptomLog:
        _destination = HomeVoiceDestination.symptomLog;

      case HomeFlowAction.openReportUpload:
        _destination = HomeVoiceDestination.reportUpload;

      case HomeFlowAction.updateNextAncDate:
        await _updateNextAncDate(response.date);

      case HomeFlowAction.saveAncSummary:
        await _saveAncSummary(response.text);

      case HomeFlowAction.markVaccineDone:
        await _markVaccineDone();
    }
  }

  Future<void> _logVital(
    String key,
    double value,
    String unit, {
    Map<String, dynamic>? data,
  }) async {
    final userId = UserSessionManager.instance.userId;
    if (userId.isEmpty) return;
    try {
      await VitalsSqLiteService().saveVital(
        key: key,
        value: value,
        unit: unit,
        createdAt: DateTime.now(),
        userId: userId,
        additionalData: data,
      );
    } catch (e) {
      debugPrint('HomeVoiceController: could not log "$key": $e');
    }
  }

  Future<void> _logMeal(String? mealKey) async {
    if (mealKey == null) return;
    // Meals are stored as calories under the meal's own key, matching what the
    // care sheet writes, so Today's Care sees this as the meal being done.
    final meal = CareMeal.values.where((m) => m.vitalKey == mealKey).firstOrNull;
    await _logVital(
      mealKey,
      (meal?.typicalCalories ?? 400).toDouble(),
      'kcal',
      data: {'source': 'allobot_home', 'logged_by': 'voice'},
    );
  }

  /// Stores what she ate against today's row for that meal.
  ///
  /// Written onto the meal's own vital rather than as a row of its own: the
  /// calorie tracker and Today's Care both sum these rows over the day, so a
  /// second row would show as a second meal. Under the same `items` key the
  /// Today's Care meal sheet uses, which is also what stops the question
  /// being asked again — the note is read back out of the vitals stream.
  ///
  /// If nothing is logged for the meal yet (she described it before it was
  /// recorded, or the log failed) the meal is written now, note and all.
  Future<void> _logMealDetail(String? mealKey, String? items) async {
    final note = items?.trim() ?? '';
    if (mealKey == null || note.isEmpty) return;

    final meal = CareMeal.values.where((m) => m.vitalKey == mealKey).firstOrNull;
    final data = <String, dynamic>{
      'items': note,
      'details': note,
      if (meal != null) 'meal': meal.label,
      'meal_type': mealKey,
      'type': mealKey,
      'source': 'allobot_home',
      'logged_by': 'voice',
    };

    final userId = UserSessionManager.instance.userId;
    if (userId.isEmpty) return;

    try {
      final merged = await VitalsSqLiteService().mergeDataIntoLatest(
        key: mealKey,
        data: data,
        userId: userId,
      );
      if (merged) return;
    } catch (e) {
      debugPrint('HomeVoiceController: could not attach the meal note: $e');
    }

    await _logVital(
      mealKey,
      (meal?.typicalCalories ?? 400).toDouble(),
      'kcal',
      data: data,
    );
  }

  /// Moves the next pending visit to the date she gave.
  ///
  /// Today's visit is excluded: she has just been to that one, so "next" means
  /// the one after it.
  Future<void> _updateNextAncDate(DateTime? date) async {
    final flow = _flow;
    if (date == null || flow == null) return;

    final today = flow.context.ancVisitToday;
    final upcoming = flow.context.ancVisits
        .where((visit) =>
            visit.isPending && visit.id.isNotEmpty && visit.id != today?.id)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    if (upcoming.isEmpty) {
      debugPrint('HomeVoiceController: no pending visit to move to $date');
      return;
    }

    try {
      await PregnancyCareDbService.instance.updateAncVisit(
        PregnancyAncScheduleCompanion(
          id: Value(upcoming.first.id),
          scheduledDate: Value(date),
        ),
      );
    } catch (e) {
      debugPrint('HomeVoiceController: could not move the next visit: $e');
    }
  }

  /// Stores what the doctor said against today's visit, and marks it done.
  Future<void> _saveAncSummary(String? summary) async {
    final flow = _flow;
    if (summary == null || summary.isEmpty || flow == null) return;

    final visit = flow.context.ancVisitToday ??
        flow.context.lastCompletedAncVisit ??
        flow.context.nextAncVisit;
    if (visit == null || visit.id.isEmpty) return;

    try {
      await PregnancyCareDbService.instance.updateAncVisit(
        PregnancyAncScheduleCompanion(
          id: Value(visit.id),
          notes: Value(summary),
          status: const Value('done'),
          actualDate: Value(visit.actualDate ?? DateTime.now()),
        ),
      );
    } catch (e) {
      debugPrint('HomeVoiceController: could not save the visit notes: $e');
    }
  }

  Future<void> _markVaccineDone() async {
    final dose = _flow?.context.nextVaccine;
    if (dose == null || dose.id.isEmpty) return;
    try {
      await PregnancyCareDbService.instance.updateVaccination(
        VaccinationsCompanion(
          id: Value(dose.id),
          status: const Value('done'),
          administeredDate: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      debugPrint('HomeVoiceController: could not mark the dose given: $e');
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
