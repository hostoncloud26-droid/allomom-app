/// Today's Planner's assistant, ported from AlloKonnect's
/// `todays_planner_ai_manager.dart`: Gemini (Firebase AI Logic) transcribes
/// what she says, then works through it by calling the planner's functions.
///
/// Allomom's planner holds her meals and Today's Care's items, so
/// AlloKonnect's task, project and check-in functions are left out; ticking
/// off care items and logging counts (water, snacks) are added.
library;

import 'package:allomom/models/vital_shapes.dart';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_day.dart';
import 'package:allomom/features/overview_section/todays_care/planner/todays_plan_data.dart';

/// What's on the planner when she speaks, given to the model so it can refer
/// to real items.
class PlannerSnapshot {
  final DateTime day;
  final List<PlannedMeal> meals;

  /// Today's Care, whose items (all but its meals) are on the timeline.
  final CareDay care;

  const PlannerSnapshot({
    required this.day,
    required this.meals,
    required this.care,
  });

  /// The care items on the planner, by their [TodaysPlanData.careKey].
  Map<String, CareItem> get careItems => {
    for (final item in TodaysPlanData.careItemsOnPlanner(care))
      TodaysPlanData.careKey(item, care.hourOf(item)): item,
  };
}

/// One change the model asked for. Times are minutes of the day on show.
class PlannerAiAction {
  static const String planMeal = 'plan_meal';
  static const String removeMeal = 'remove_meal';
  static const String logMeal = 'log_meal';
  static const String completeCare = 'complete_care';
  static const String undoCare = 'undo_care';
  static const String logCareCount = 'log_care_count';

  static const List<String> types = [
    planMeal,
    removeMeal,
    logMeal,
    completeCare,
    undoCare,
    logCareCount,
  ];

  final String type;

  /// Short line for the UI, e.g. "Lunch at 1:30 PM".
  final String summary;
  final String? description;
  final int? startMinute;
  final int? endMinute;
  final String? planType;

  /// Calories of a logged meal.
  final double? calories;

  /// The care item's key ([TodaysPlanData.careKey]), and for a count how
  /// much to add.
  final String? careId;
  final int? amount;

  const PlannerAiAction({
    required this.type,
    required this.summary,
    this.description,
    this.startMinute,
    this.endMinute,
    this.planType,
    this.calories,
    this.careId,
    this.amount,
  });

  /// The action a function call from the model stands for, or null when
  /// [call] isn't one of the planner's action functions.
  static PlannerAiAction? fromCall(FunctionCall call) {
    final args = call.args;
    final type = switch (call.name) {
      'set_care_done' => args['done'] == false ? undoCare : completeCare,
      final name when types.contains(name) => name,
      _ => null,
    };
    if (type == null) return null;
    final amount = args['amount'];
    return PlannerAiAction(
      type: type,
      careId: args['care_id'] as String?,
      amount: amount is num ? amount.round() : int.tryParse('${amount ?? ''}'),
      summary: (args['summary'] ?? call.name).toString(),
      description: (args['details'] as String?)?.trim(),
      startMinute: TodaysPlannerAiManager._parseClock(args['start_time']),
      endMinute: TodaysPlannerAiManager._parseClock(args['end_time']),
      planType: args['plan_type'] as String?,
      calories: args['calories'] is num
          ? (args['calories'] as num).toDouble()
          : double.tryParse('${args['calories'] ?? ''}'),
    );
  }

  IconData get icon => switch (type) {
    planMeal => Icons.restaurant_rounded,
    removeMeal => Icons.no_meals_rounded,
    completeCare => Icons.check_circle_outline_rounded,
    undoCare => Icons.undo_rounded,
    logCareCount => Icons.add_circle_outline_rounded,
    _ => Icons.restaurant_menu_rounded,
  };
}

/// How one action went, and the tile it touched (to highlight), if any.
class PlannerActionOutcome {
  final bool ok;
  final String? error;
  final String? tileKey;

  const PlannerActionOutcome.done([this.tileKey]) : ok = true, error = null;
  const PlannerActionOutcome.failed(this.error) : ok = false, tileKey = null;
}

/// Turns a spoken or typed request into planner changes with Gemini
/// (Firebase AI), then carries them out on her meals and activities.
class TodaysPlannerAiManager {
  static const String _model = 'gemini-3.5-flash-lite';

  // Rounds of function calls allowed for one request before giving up.
  static const int _maxTurns = 8;

  /// Gemini with the planner's functions as tools. The standing rules are the
  /// system instruction; each request's state and transcript are the
  /// prompt.
  late final GenerativeModel _gemini = FirebaseAI.googleAI().generativeModel(
    model: _model,
    systemInstruction: Content.system(_systemInstruction),
    tools: [Tool.functionDeclarations(_functions)],
    toolConfig: ToolConfig(functionCallingConfig: FunctionCallingConfig.auto()),
    generationConfig: GenerationConfig(temperature: 0.2),
  );

  /// Gemini without tools, turning the recording into text first; the
  /// planner model then works from the text alone.
  late final GenerativeModel _transcriber = FirebaseAI.googleAI()
      .generativeModel(
        model: _model,
        systemInstruction: Content.system(_transcriberInstruction),
        generationConfig: GenerationConfig(),
      );

  static const String _transcriberInstruction = """
You transcribe voice notes for a pregnancy and baby-care day planner.
Write down exactly what the speaker says, in the language and script they speak it (mixed languages stay mixed). Don't translate, summarise or answer it.
Return only the transcript as plain text: no quotes, labels or markdown.
""";

  /// What she said in the recording at [audioPath], as spoken. Empty when
  /// nothing came back. [snapshot]'s names are passed as vocabulary, since
  /// they're rarely dictionary words.
  Future<String> transcribe(String audioPath, PlannerSnapshot snapshot) async {
    final audio = await File(audioPath).readAsBytes();
    // 16 kHz, 16-bit mono WAV: 32000 bytes a second after the 44-byte header.
    debugPrint(
      'TodaysPlannerAiManager: audio ${audio.length} bytes, '
      '~${((audio.length - 44) / 32000).toStringAsFixed(1)}s',
    );

    final vocabulary = {
      'Allomom',
      'AlloBaby',
      for (final type in TodaysPlanData.planTypes)
        TodaysPlanData.mealTitle(type),
      for (final item in snapshot.careItems.values) item.title,
    }.join('; ');

    try {
      final response = await _transcriber.generateContent([
        Content.multi([
          TextPart(
            'Transcribe this voice note. '
            'Words the speaker may use (spell them this way): $vocabulary',
          ),
          InlineDataPart('audio/wav', audio),
        ]),
      ]);
      return response.text?.trim() ?? '';
    } on FirebaseAIException catch (e) {
      // A reply with no text (e.g. silence) comes back as empty content,
      // which the SDK fails to parse.
      debugPrint('TodaysPlannerAiManager: transcription failed: $e');
      return '';
    }
  }

  /// Transcribes the recording at [audioPath] (or takes the typed [text]
  /// as is), then sends that text with the planner's state and lets
  /// the model work through it by calling the planner's functions, which are
  /// carried out here as they come. Returns the model's closing reply, which
  /// it writes after seeing how each call went.
  ///
  /// [snapshot] gives the planner as it is now (it changes between calls).
  /// [onTranscript] gets what she said; [onActionStart] and [onActionDone]
  /// bracket each change, so the UI can follow along.
  Future<String> run({
    String? audioPath,
    String? text,
    required PlannerSnapshot Function() snapshot,
    required void Function(String transcript) onTranscript,
    required void Function(PlannerAiAction action) onActionStart,
    required Future<void> Function(
      PlannerAiAction action,
      PlannerActionOutcome outcome,
    )
    onActionDone,
  }) async {
    assert((audioPath == null) != (text == null));
    final request = text?.trim() ?? await transcribe(audioPath!, snapshot());
    debugPrint('TodaysPlannerAiManager: heard: $request');
    onTranscript(request);
    if (request.isEmpty) return '';

    if (_lastTurnAt != null &&
        DateTime.now().difference(_lastTurnAt!) > _historyExpiry) {
      resetConversation();
    }
    final history = [for (final turn in _turns) ...turn];
    final chat = _gemini.startChat(history: history);
    final historyLength = history.length;

    var reply = '';
    try {
      var response = await chat.sendMessage(
        Content.text(_requestPrompt(snapshot(), request)),
      );

      for (var turn = 0; turn < _maxTurns; turn++) {
        final calls = response.functionCalls.toList();
        if (calls.isEmpty) break;

        final results = <FunctionResponse>[];
        for (final call in calls) {
          debugPrint('TodaysPlannerAiManager: ${call.name} ${call.args}');
          results.add(
            FunctionResponse(
              call.name,
              await _handleCall(
                call,
                snapshot,
                onActionStart: onActionStart,
                onActionDone: onActionDone,
              ),
              id: call.id,
            ),
          );
        }
        // Function results go back as a user turn: this backend rejects the
        // 'function' role that Content.functionResponses uses.
        try {
          response = await chat.sendMessage(Content('user', results));
        } on FirebaseAIException catch (e) {
          // The model may close with no text at all, which the SDK can't
          // parse; the changes are made, so the UI falls back to its own
          // summary.
          debugPrint('TodaysPlannerAiManager: no closing reply: $e');
          return '';
        }
      }
      reply = response.text?.trim() ?? '';
      debugPrint('TodaysPlannerAiManager: reply: $reply');
      return reply;
    } finally {
      _remember(chat.history.skip(historyLength).toList(), request, reply);
    }
  }

  // ---- Conversation ------------------------------------------------------

  /// Requests kept as context for the next one, so the model can ask a
  /// question and match the answer to it.
  static const int _historyTurns = 3;

  /// A conversation this old is over; the next request starts afresh.
  static const Duration _historyExpiry = Duration(minutes: 10);

  // Each entry is one request's contents: the request, the model's function
  // calls and their results, and its reply.
  final List<List<Content>> _turns = [];
  DateTime? _lastTurnAt;

  /// Forgets the conversation, e.g. when she closes the panel.
  void resetConversation() {
    _turns.clear();
    _lastTurnAt = null;
  }

  /// Keeps [contents] (one request's exchange) as history, oldest dropped
  /// past [_historyTurns].
  void _remember(List<Content> contents, String request, String reply) {
    if (contents.isEmpty) return;
    final turn = [
      // The planner state in the prompt is outdated by the next request,
      // which brings its own; keep only what was said.
      if (contents.first.role == 'user')
        Content.text('Earlier request: $request')
      else
        contents.first,
      ...contents.skip(1),
    ];
    // History must alternate, ending on the model; a turn that ended on
    // function results (no closing reply) gets one.
    if (turn.last.role != 'model') {
      turn.add(Content.model([TextPart(reply.isEmpty ? 'Done.' : reply)]));
    }
    _turns.add(turn);
    while (_turns.length > _historyTurns) {
      _turns.removeAt(0);
    }
    _lastTurnAt = DateTime.now();
  }

  /// Runs one function call from the model and returns its result.
  Future<Map<String, Object?>> _handleCall(
    FunctionCall call,
    PlannerSnapshot Function() snapshot, {
    required void Function(PlannerAiAction action) onActionStart,
    required Future<void> Function(
      PlannerAiAction action,
      PlannerActionOutcome outcome,
    )
    onActionDone,
  }) async {
    if (call.name == 'get_planner_state') return _stateJson(snapshot());
    final action = PlannerAiAction.fromCall(call);
    if (action == null) {
      return {'ok': false, 'error': 'Unknown function ${call.name}'};
    }
    onActionStart(action);
    PlannerActionOutcome outcome;
    try {
      outcome = await perform(action, snapshot());
    } catch (e) {
      debugPrint('TodaysPlannerAiManager: ${call.name} failed: $e');
      outcome = const PlannerActionOutcome.failed('Something went wrong');
    }
    await onActionDone(action, outcome);
    return {
      'ok': outcome.ok,
      if (outcome.error != null) 'error': outcome.error,
    };
  }

  /// Carries out [action] on [snapshot]'s day.
  Future<PlannerActionOutcome> perform(
    PlannerAiAction action,
    PlannerSnapshot snapshot,
  ) async {
    final day = snapshot.day;
    final start = action.startMinute;

    switch (action.type) {
      case PlannerAiAction.planMeal:
        final type = action.planType;
        if (type == null || !TodaysPlanData.planTypes.contains(type)) {
          return const PlannerActionOutcome.failed('Unknown meal');
        }
        if (start == null) {
          return const PlannerActionOutcome.failed('No time given');
        }
        final existing = snapshot.meals.firstWhereOrNull((m) => m.type == type);
        if (existing?.isLogged == true) {
          return const PlannerActionOutcome.failed('Already logged');
        }
        final length = existing?.isPlanned == true
            ? existing!.planEnd! - existing.planStart!
            : TodaysPlanData.defaultPlanMinutes;
        await TodaysPlanData.savePlan(
          day,
          type,
          start,
          _endAfter(start, action.endMinute, length),
        );
        return PlannerActionOutcome.done('meal-$type');

      case PlannerAiAction.logMeal:
        return _logMeal(action, snapshot);

      case PlannerAiAction.removeMeal:
        final type = action.planType;
        final existing = snapshot.meals.firstWhereOrNull((m) => m.type == type);
        if (existing == null) {
          return const PlannerActionOutcome.failed('Not planned');
        }
        if (existing.isLogged) {
          return const PlannerActionOutcome.failed(
            'Logged meals stay on the plan',
          );
        }
        await TodaysPlanData.removePlan(day, existing.type);
        return const PlannerActionOutcome.done();

      case PlannerAiAction.completeCare:
      case PlannerAiAction.undoCare:
        final item = snapshot.careItems[action.careId];
        if (item == null) return const PlannerActionOutcome.failed('Not found');
        if (item.kind != CareActionKind.checkoff) {
          return const PlannerActionOutcome.failed(
            'This one is logged, not ticked off',
          );
        }
        final saved = await CareItemActions.setCheckoff(
          item,
          snapshot.care,
          action.type == PlannerAiAction.completeCare,
        );
        return saved
            ? PlannerActionOutcome.done(action.careId)
            : const PlannerActionOutcome.failed("Couldn't save it");

      case PlannerAiAction.logCareCount:
        final item = snapshot.careItems[action.careId];
        if (item == null) return const PlannerActionOutcome.failed('Not found');
        if (item.kind != CareActionKind.count) {
          return const PlannerActionOutcome.failed('Not something counted');
        }
        final amount = action.amount ?? 1;
        if (amount <= 0) return const PlannerActionOutcome.failed('No amount');
        final saved = await CareItemActions.addCount(
          item,
          snapshot.care,
          amount,
        );
        return saved
            ? PlannerActionOutcome.done(action.careId)
            : const PlannerActionOutcome.failed("Couldn't log it");
    }
    return const PlannerActionOutcome.failed('Unknown action');
  }

  /// Logs [action]'s meal as eaten, or edits its log when it has one: only
  /// the fields given change, the rest keep their logged (else planned)
  /// values. Written the way Today's Care logs meals, so both read it.
  Future<PlannerActionOutcome> _logMeal(
    PlannerAiAction action,
    PlannerSnapshot snapshot,
  ) async {
    final type = action.planType;
    if (type == null || !TodaysPlanData.mealTypes.contains(type)) {
      return const PlannerActionOutcome.failed(
        'Only breakfast, lunch or dinner',
      );
    }
    final userId = MainController.instance.userId.trim();
    if (userId.isEmpty) {
      return const PlannerActionOutcome.failed('Not signed in');
    }

    final meal = snapshot.meals.firstWhereOrNull((m) => m.type == type);
    final vital = meal?.logged;
    final eaten = meal?.eatenWindow;
    final day = snapshot.day;
    final now = DateTime.now();
    final nowMinute = DateUtils.isSameDay(day, now)
        ? now.hour * 60 + now.minute
        : TodaysPlanData.defaultStart(type);

    final previousStart = eaten != null
        ? eaten.$1.hour * 60 + eaten.$1.minute
        : meal?.planStart ?? nowMinute;
    final previousLength = eaten != null
        ? eaten.$2.difference(eaten.$1).inMinutes
        : meal?.isPlanned == true
        ? meal!.planEnd! - meal.planStart!
        : MealTimes.defaultDuration.inMinutes;
    final startMinute = action.startMinute ?? previousStart;
    final endMinute = _endAfter(startMinute, action.endMinute, previousLength);
    final start = _at(day, startMinute);
    final end = _at(day, endMinute);

    final details = action.description ?? meal?.details ?? '';
    final calories = action.calories ?? vital?.value ?? 0;
    if (vital == null && details.isEmpty && calories <= 0) {
      return const PlannerActionOutcome.failed('Say what you ate');
    }

    final data = logMealData(
      type: type,
      details: details,
      start: start,
      end: end,
      previous: vital?.data,
    );
    final vitals = HealthVitalsController.instance;
    final saved = vital != null
        ? await vitals.updateVitalEntry(
            vitalId: vital.id,
            key: vital.key,
            value: calories,
            unit: 'kcal',
            createdAt: start,
            userId: userId,
            data: data,
          )
        : await vitals.addVitalEntry(
            key: VitalShapes.food,
            value: calories,
            unit: 'kcal',
            createdAt: start,
            userId: userId,
            data: data,
          );
    if (saved == null) {
      return const PlannerActionOutcome.failed("Couldn't save the meal");
    }
    return PlannerActionOutcome.done('meal-$type');
  }

  /// A meal log's data, in Today's Care's fields plus when it was eaten.
  static Map<String, dynamic> logMealData({
    required String type,
    required String details,
    required DateTime start,
    required DateTime end,
    Map<String, dynamic>? previous,
  }) => <String, dynamic>{
    ...?previous,
    'items': details,
    'details': details,
    'meal': TodaysPlanData.mealTitle(type),
    'meal_type': type,
    'type': type,
    'eating_time': DateFormat('h:mm a').format(start),
    'time': DateFormat('HH:mm').format(start),
    ...MealTimes.toData(start, end),
  };

  // ---- Helpers -----------------------------------------------------------

  static int? _parseClock(Object? raw) {
    final parts = raw?.toString().trim().split(':');
    if (parts == null || parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 24 || m < 0 || m > 59) {
      return null;
    }
    return (h * 60 + m).clamp(0, 1439).toInt();
  }

  static String _clock(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  static DateTime _at(DateTime day, int minute) =>
      DateTime(day.year, day.month, day.day).add(Duration(minutes: minute));

  /// [end] when it comes after [start], else [start] plus [length], within
  /// the day.
  static int _endAfter(int start, int? end, int length) =>
      (end != null && end > start ? end : start + length)
          .clamp(start + 1, 1439)
          .toInt();

  /// The planner on [s]'s day as the model sees it: times are "HH:mm".
  Map<String, Object?> _stateJson(PlannerSnapshot s) {
    return {
      'meals': [
        for (final m in s.meals)
          {
            'plan_type': m.type,
            'title': m.title,
            if (m.isPlanned) 'planned_start': _clock(m.planStart!),
            if (m.isPlanned) 'planned_end': _clock(m.planEnd!),
            'logged': m.isLogged,
            if (m.eatenWindow != null) ...{
              'eaten_start': _clock(
                m.eatenWindow!.$1.hour * 60 + m.eatenWindow!.$1.minute,
              ),
              'eaten_end': _clock(
                m.eatenWindow!.$2.hour * 60 + m.eatenWindow!.$2.minute,
              ),
              'details': m.details,
              'calories': m.calories?.round(),
            },
          },
      ],
      'not_planned_meals': [
        for (final type in TodaysPlanData.planTypes)
          if (!s.meals.any((m) => m.type == type)) type,
      ],
      'care_items': [
        for (final MapEntry(key: id, value: item) in s.careItems.entries)
          {
            'care_id': id,
            'title': item.title,
            'time': _clock(s.care.hourOf(item) * 60),
            'kind': switch (item.kind) {
              CareActionKind.checkoff => 'tick_off',
              CareActionKind.count => 'count',
              CareActionKind.navigate => 'opens_a_tracker',
              CareActionKind.meal => 'meal',
            },
            'done': s.care.isDone(item),
            if (item.kind == CareActionKind.count) ...{
              'logged_today': s.care.countFor(item),
              'unit': item.unitPlural,
              if (item.dailyTarget != null) 'daily_target': item.dailyTarget,
            },
          },
      ],
    };
  }

  /// The prompt for one request: only what changes per request.
  String _requestPrompt(PlannerSnapshot s, String request) {
    final now = DateTime.now();
    return 'Planner day: ${DateFormat('EEEE, d MMMM yyyy').format(s.day)}.\n'
        'Time now: ${DateFormat('HH:mm').format(now)}.\n'
        'Planner state (JSON):\n${jsonEncode(_stateJson(s))}\n\n'
        'The user\'s request (a transcript if spoken, or typed):\n$request';
  }

  /// The standing rules: who the assistant is and how to use the functions.
  static const String _systemInstruction = """
You are the voice assistant of Allomom's day planner, for a mother who is pregnant or caring for a new baby. Each request comes with the day's planner state as JSON and a transcript of her spoken request. It may be in any language or a mix (often Tamil or Hindi with English), and speech-to-text may have misheard names: match them loosely to the planner state.

How to work:
1. Call the planner functions needed to do what she asked, in order. Several calls may go in one turn.
   If something you need is missing or unclear (which meal, what time, what she ate), don't guess: ask one short question and call nothing. The earlier requests and your replies in this conversation are in the history; when the new request answers your question, combine the two and act.
2. Each function returns whether it worked. If one fails, don't retry it the same way; mention it in your reply.
3. Finish with a short, warm reply in English saying what changed and what couldn't be done. Plain text, no markdown. If the request isn't about the planner, just reply briefly without calling planner functions; never give medical advice beyond suggesting she ask her doctor.

Rules:
- Times are 24-hour "HH:mm" on the planner's day. Read a spoken time like "1:30" as the sensible time of day for that item (lunch at 1:30 is 13:30).
- The planner holds her meals (breakfast, lunch, dinner), which can be planned, moved, logged and removed, and her Today's Care items (care_items), which stay at their times. Match what she calls things loosely.
- A care item of kind "tick_off" is marked done (or undone) with set_care_done, e.g. "I did my stretches" or "took my iron tablet". A "count" item (water, snacks, drinks) is logged with log_care_count, e.g. "I drank 2 glasses of water"; pick the count item of that kind nearest the time now. An "opens_a_tracker" item (kick counting, feeds) can't be changed here: tell her to tap it on the planner.
- "Arrange" or "rearrange" means reschedule meals so they don't overlap each other or care items, keeping their lengths.
- Call get_planner_state if you need the planner as it is after your changes.
- Never make changes she didn't ask for.
- "I had / ate …" or changing what or when she ate is log_meal (breakfast, lunch and dinner only); plan_meal only moves the plan of a meal not yet eaten. Estimate calories from the food when she doesn't say them.
- Every planner action has a "summary": a very short English line describing the change, shown to her, like "Lunch moved to 1:30 PM".
""";

  static final Schema _summary = Schema.string(
    description:
        'Very short English line describing this change, e.g. "Lunch moved to 1:30 PM".',
  );
  static final Schema _time = Schema.string(description: 'HH:mm, 24-hour.');
  static final Schema _planType = Schema.enumString(
    enumValues: TodaysPlanData.planTypes,
    description: 'The meal.',
  );

  static final List<FunctionDeclaration> _functions = [
    FunctionDeclaration(
      'get_planner_state',
      'Returns the planner\'s current state, including changes made so far.',
      parameters: {},
    ),
    FunctionDeclaration(
      PlannerAiAction.planMeal,
      'Plans a meal at a time, or moves it if already planned. Not for meals already eaten (use log_meal).',
      parameters: {
        'plan_type': _planType,
        'start_time': _time,
        'end_time': Schema.string(
          description: 'HH:mm, 24-hour. Defaults to its current length.',
        ),
        'summary': _summary,
      },
      optionalParameters: ['end_time'],
    ),
    FunctionDeclaration(
      PlannerAiAction.logMeal,
      'Logs breakfast, lunch or dinner as eaten, or edits its log if already logged. Only the fields given change.',
      parameters: {
        'plan_type': Schema.enumString(
          enumValues: TodaysPlanData.mealTypes,
          description: 'The meal.',
        ),
        'details': Schema.string(description: 'What was eaten.'),
        'calories': Schema.number(
          description: 'Calories in kcal, estimated if unsaid.',
        ),
        'start_time': Schema.string(
          description: 'HH:mm, 24-hour: when she started eating.',
        ),
        'end_time': Schema.string(
          description: 'HH:mm, 24-hour: when she finished.',
        ),
        'summary': _summary,
      },
      optionalParameters: ['details', 'calories', 'start_time', 'end_time'],
    ),
    FunctionDeclaration(
      'set_care_done',
      'Marks a Today\'s Care item of kind "tick_off" done, or not done again.',
      parameters: {
        'care_id': Schema.string(description: 'care_id from care_items.'),
        'done': Schema.boolean(
          description: 'true to mark done, false to undo.',
        ),
        'summary': _summary,
      },
    ),
    FunctionDeclaration(
      PlannerAiAction.logCareCount,
      'Adds to a Today\'s Care item of kind "count" (glasses of water, snacks, drinks).',
      parameters: {
        'care_id': Schema.string(description: 'care_id from care_items.'),
        'amount': Schema.integer(
          description: 'How many to add, in the item\'s unit.',
        ),
        'summary': _summary,
      },
    ),
    FunctionDeclaration(
      PlannerAiAction.removeMeal,
      'Takes a planned meal off the day. Not for logged meals.',
      parameters: {'plan_type': _planType, 'summary': _summary},
    ),
  ];
}
