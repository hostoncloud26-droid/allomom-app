/// The proactive voice companion on the Home screen.
///
/// AlloBot greets the mother when she opens the app and then works through a
/// short queue of questions about her day — meals, water, sleep, symptoms,
/// movements — chosen from the clock and from what she has actually logged.
/// Each answer either records something, gives her advice, or sends her to the
/// screen that can do the job.
///
/// Pure by design: this decides *what* to ask and *what should happen* to an
/// answer, and returns an [HomeFlowAction] describing the side effect. The
/// widget layer performs it. That keeps the timing rules — which meal is due
/// when, when a missed breakfast is worth chasing, when movements are old
/// enough to ask about — testable against a fixed clock with no database.
library;

import 'package:allomom/services/allobot/allobot_context.dart';

/// The subjects AlloBot raises on the home screen.
enum HomePromptKind {
  breakfast,
  lunch,
  dinner,
  water,
  sleep,
  symptoms,
  kicks,

  /// The four questions asked after an antenatal visit.
  ancNextDate,
  ancSummary,
  ancVaccination,
  ancReport,
}

/// What kind of answer a prompt expects, which decides the controls shown.
enum HomeAnswerKind {
  /// Yes or no.
  yesNo,

  /// A calendar date.
  date,

  /// Free text — what the doctor said.
  text,
}

/// The side effect an answer asks for. Performed by the widget layer.
enum HomeFlowAction {
  none,

  /// Log one glass of water.
  logWater,

  /// Log the named meal as eaten.
  logMeal,

  /// Open the Kick Counter.
  openKickCounter,

  /// Open My Health so she can log a sleep duration.
  openSleepLog,

  /// Open My Health so she can record what she is feeling.
  openSymptomLog,

  /// Move the next pending antenatal visit to the date she gave.
  updateNextAncDate,

  /// Store what the doctor said against the visit just completed.
  saveAncSummary,

  /// Mark the next pending vaccine dose as given.
  markVaccineDone,

  /// Open Reports so she can upload one.
  openReportUpload,
}

/// One question AlloBot puts to her.
class HomePrompt {
  const HomePrompt({
    required this.kind,
    required this.question,
    required this.answerKind,
    this.mealKey,
  });

  final HomePromptKind kind;

  /// The question, as spoken and as shown on the card.
  final String question;

  final HomeAnswerKind answerKind;

  /// For the meal prompts, the vital key the meal is stored under.
  final String? mealKey;
}

/// What AlloBot says back, and what should happen as a result.
class HomeFlowResponse {
  const HomeFlowResponse({
    required this.reply,
    this.action = HomeFlowAction.none,
    this.mealKey,
    this.date,
    this.text,
  });

  /// What AlloBot says. Spoken and shown on the card.
  final String reply;

  final HomeFlowAction action;

  /// Meal to log, for [HomeFlowAction.logMeal].
  final String? mealKey;

  /// Date she gave, for [HomeFlowAction.updateNextAncDate].
  final DateTime? date;

  /// Text she gave, for [HomeFlowAction.saveAncSummary].
  final String? text;
}

/// Vital keys the flow reads and writes.
const String waterVitalKey = 'water';
const String sleepVitalKey = 'sleep';
const String kickVitalKey = 'kick_count';

/// Meals in the order they happen, with the hour by which each is normally
/// eaten.
///
/// The "by" hour is what makes a missed meal chase-able: past it, an unlogged
/// meal is worth asking about in the past tense ("did you have breakfast
/// earlier?") rather than the present.
const List<({String key, String label, int dueFrom, int dueBy})> mealWindows = [
  (key: 'breakfast', label: 'breakfast', dueFrom: 5, dueBy: 11),
  (key: 'lunch', label: 'lunch', dueFrom: 11, dueBy: 16),
  (key: 'dinner', label: 'dinner', dueFrom: 19, dueBy: 23),
];

/// The week from which asking about movements makes sense.
///
/// Before this most mothers feel nothing, and asking "do you feel any kicks?"
/// at week 12 invites a worried "no" to a question that has no business being
/// asked yet.
const int kicksFromWeek = 18;

/// Glasses of water below which AlloBot says something rather than just
/// recording the number.
const int lowWaterGlasses = 4;

/// Hours of sleep below which the same applies.
const double lowSleepHours = 6;

/// Builds the greeting AlloBot speaks when the app opens.
///
/// Leads with "Hi mommy", then where she is, then what this part of the day is
/// for — the today's-care framing, drawn from [AlloBotContext.dayPartHeadline].
String composeHomeGreeting(AlloBotContext context) {
  final parts = <String>['Hi mommy 🌸'];

  if (context.isPregnant && context.gestationalWeek > 0) {
    parts.add(
      'You are at week ${context.gestationalWeek} of your pregnancy, '
      'in your ${context.trimesterLabel}.',
    );
  } else if (context.isNewMom) {
    parts.add('I am here for you and your little one.');
  }

  final headline = context.dayPartHeadline;
  if (headline.isNotEmpty) {
    parts.add('$headline — let us get through it together.');
  }

  final pending = context.outstandingCare;
  if (pending.isNotEmpty) {
    final names = pending.take(2).map((item) => item.title.toLowerCase());
    parts.add('${names.join(' and ')} still to go on your care list.');
  }

  return parts.join(' ');
}

/// Decides what AlloBot asks on the home screen, and what answers mean.
///
/// Hold one per screen: it remembers what has been asked so the same question
/// is not put twice in a session.
class HomeVoiceFlow {
  HomeVoiceFlow({required AlloBotContext context}) : _context = context;

  AlloBotContext _context;

  final Set<HomePromptKind> _asked = <HomePromptKind>{};

  /// The antenatal questions, once that sequence has been started.
  List<HomePrompt> _ancQueue = const [];
  int _ancIndex = 0;

  AlloBotContext get context => _context;

  /// Subjects already raised this session.
  Set<HomePromptKind> get asked => Set.unmodifiable(_asked);

  /// Whether the antenatal sequence is part-way through.
  bool get isInAncFlow => _ancIndex < _ancQueue.length;

  void updateContext(AlloBotContext context) => _context = context;

  /// Starts the four questions that follow an antenatal visit.
  ///
  /// Entered two ways: automatically when a visit is scheduled for today, and
  /// on demand when she marks a visit complete in the ANC calendar.
  void startAncFollowUp() {
    _ancQueue = const [
      HomePrompt(
        kind: HomePromptKind.ancNextDate,
        question: 'When is your next ANC check-up?',
        answerKind: HomeAnswerKind.date,
      ),
      HomePrompt(
        kind: HomePromptKind.ancSummary,
        question: 'What did the doctor say today?',
        answerKind: HomeAnswerKind.text,
      ),
      HomePrompt(
        kind: HomePromptKind.ancVaccination,
        question: 'Did you get your vaccination?',
        answerKind: HomeAnswerKind.yesNo,
      ),
      HomePrompt(
        kind: HomePromptKind.ancReport,
        question: 'Do you have a report to upload?',
        answerKind: HomeAnswerKind.yesNo,
      ),
    ];
    _ancIndex = 0;
  }

  /// Whether an antenatal visit is scheduled for today.
  bool get hasAncToday {
    final visit = _context.nextAncVisit;
    if (visit == null) return false;
    return visit.daysFrom(_context.now) == 0;
  }

  /// The next question, or null when there is nothing left to ask.
  ///
  /// The antenatal sequence takes priority and runs in order; everything else
  /// is picked by the clock and by what is missing from today's log.
  HomePrompt? nextPrompt() {
    if (isInAncFlow) return _ancQueue[_ancIndex];

    for (final prompt in _candidates()) {
      if (!_asked.contains(prompt.kind)) return prompt;
    }
    return null;
  }

  /// Records an answer and says what happens next.
  ///
  /// [affirmed] answers a [HomeAnswerKind.yesNo] prompt, [date] a date prompt
  /// and [text] a text prompt.
  HomeFlowResponse answer(
    HomePrompt prompt, {
    bool? affirmed,
    DateTime? date,
    String? text,
  }) {
    _asked.add(prompt.kind);
    if (isInAncFlow && _ancQueue[_ancIndex].kind == prompt.kind) _ancIndex++;

    switch (prompt.kind) {
      case HomePromptKind.breakfast:
      case HomePromptKind.lunch:
      case HomePromptKind.dinner:
        return _mealResponse(prompt, affirmed ?? false);

      case HomePromptKind.water:
        return _waterResponse(affirmed ?? false);

      case HomePromptKind.sleep:
        return _sleepResponse(affirmed ?? false);

      case HomePromptKind.symptoms:
        return affirmed ?? false
            ? const HomeFlowResponse(
                reply: 'Tell me what you are feeling, mommy — record it and I '
                    'will help you work out whether it needs a doctor today.',
                action: HomeFlowAction.openSymptomLog,
              )
            : const HomeFlowResponse(
                reply: 'That is good to hear. Tell me the moment anything '
                    'changes.',
              );

      case HomePromptKind.kicks:
        return affirmed ?? false
            ? const HomeFlowResponse(
                reply: 'Lovely. Let us count them — ten movements in two hours '
                    'is the guide.',
                action: HomeFlowAction.openKickCounter,
              )
            : HomeFlowResponse(
                reply: 'At week ${_context.gestationalWeek}, movements come and '
                    'go through the day. Lie on your left side after something '
                    'to eat and give it two hours. If you count fewer than ten, '
                    'please get checked today rather than waiting.',
              );

      case HomePromptKind.ancNextDate:
        if (date == null) {
          return const HomeFlowResponse(
            reply: 'No problem — ask at the clinic and I will keep the date '
                'once you have it.',
          );
        }
        return HomeFlowResponse(
          reply: 'Noted — your next check-up is on '
              '${formatShortDate(date)}. I will remind you.',
          action: HomeFlowAction.updateNextAncDate,
          date: date,
        );

      case HomePromptKind.ancSummary:
        final summary = text?.trim() ?? '';
        if (summary.isEmpty) {
          return const HomeFlowResponse(
            reply: 'That is fine. You can add the doctor\'s notes to this visit '
                'any time.',
          );
        }
        return HomeFlowResponse(
          reply: 'Saved to this visit, mommy. Now it is on the record for next '
              'time.',
          action: HomeFlowAction.saveAncSummary,
          text: summary,
        );

      case HomePromptKind.ancVaccination:
        return affirmed ?? false
            ? const HomeFlowResponse(
                reply: 'Marked as done. Make sure it is written on your ANC '
                    'card too — that card is the record everyone works from.',
                action: HomeFlowAction.markVaccineDone,
              )
            : const HomeFlowResponse(
                reply: 'I have left it pending. Please ask about it at your '
                    'next visit — these doses protect your baby in the first '
                    'weeks after birth.',
              );

      case HomePromptKind.ancReport:
        return affirmed ?? false
            ? const HomeFlowResponse(
                reply: 'Let us get it in now, while you have it in your hand.',
                action: HomeFlowAction.openReportUpload,
              )
            : const HomeFlowResponse(
                reply: 'All done then. Well done for going, mommy. ❤️',
              );
    }
  }

  HomeFlowResponse _mealResponse(HomePrompt prompt, bool affirmed) {
    final label = prompt.mealKey == null
        ? 'that meal'
        : mealWindows
            .firstWhere(
              (meal) => meal.key == prompt.mealKey,
              orElse: () => (
                key: prompt.mealKey!,
                label: prompt.mealKey!,
                dueFrom: 0,
                dueBy: 24,
              ),
            )
            .label;

    if (affirmed) {
      return HomeFlowResponse(
        reply: 'Good, I have logged your $label.',
        action: HomeFlowAction.logMeal,
        mealKey: prompt.mealKey,
      );
    }

    return HomeFlowResponse(
      reply: 'Please do not skip $label, mommy. Your baby draws everything '
          'from what you eat, and going long without food makes the tiredness '
          'and the nausea worse. Even something small helps.',
    );
  }

  HomeFlowResponse _waterResponse(bool affirmed) {
    final logged = _context.totalToday(waterVitalKey) ?? 0;

    if (affirmed) {
      final after = logged + 1;
      final reply = after < lowWaterGlasses
          ? 'Logged — that is ${after.toStringAsFixed(0)} today. Still a fair '
              'way to go, mommy. Little and often is easiest.'
          : 'Logged — that is ${after.toStringAsFixed(0)} glasses today. '
              'Keep it steady. 💧';
      return HomeFlowResponse(reply: reply, action: HomeFlowAction.logWater);
    }

    return const HomeFlowResponse(
      reply: 'Mommy, you need to drink more water. Have a glass now if you '
          'can — it helps with the swelling, the constipation and those '
          'practice tightenings, and it keeps your amniotic fluid up.',
    );
  }

  HomeFlowResponse _sleepResponse(bool affirmed) {
    if (affirmed) {
      return const HomeFlowResponse(
        reply: 'I am glad. Rest is doing real work right now, even when it '
            'feels like doing nothing.',
      );
    }

    return const HomeFlowResponse(
      reply: 'Mommy, you need more rest than this. Try to get seven or eight '
          'hours, on your left side, and take twenty minutes off your feet in '
          'the afternoon. Log tonight\'s sleep and I will keep an eye on it.',
      action: HomeFlowAction.openSleepLog,
    );
  }

  /// The questions worth asking right now, most pressing first.
  List<HomePrompt> _candidates() {
    final hour = _context.now.hour;
    final prompts = <HomePrompt>[];

    // 1. The meal for this part of the day, if it is not logged.
    for (final meal in mealWindows) {
      if (hour < meal.dueFrom || hour >= meal.dueBy) continue;
      if (_isMealLogged(meal.key)) continue;
      prompts.add(
        HomePrompt(
          kind: _mealKind(meal.key),
          question: 'Have you had your ${meal.label}?',
          answerKind: HomeAnswerKind.yesNo,
          mealKey: meal.key,
        ),
      );
    }

    // 2. Water, whenever she is short of it.
    final water = _context.totalToday(waterVitalKey) ?? 0;
    if (hour >= 6 && water < 10) {
      prompts.add(
        HomePrompt(
          kind: HomePromptKind.water,
          question: water == 0
              ? 'Have you had any water yet today?'
              : 'You are at ${water.toStringAsFixed(0)} glasses — shall I add '
                  'another?',
          answerKind: HomeAnswerKind.yesNo,
        ),
      );
    }

    // 3. A meal whose window has passed and was never logged, asked in the
    //    past tense. This is the "if she did not log breakfast, ask later"
    //    case — chased once the window is over, not while it is still open.
    for (final meal in mealWindows) {
      if (hour < meal.dueBy) continue;
      if (_isMealLogged(meal.key)) continue;
      prompts.add(
        HomePrompt(
          kind: _mealKind(meal.key),
          question: 'Did you manage to have ${meal.label} earlier?',
          answerKind: HomeAnswerKind.yesNo,
          mealKey: meal.key,
        ),
      );
    }

    // 4. Movements, once they are worth asking about.
    if (_context.isPregnant && _context.gestationalWeek >= kicksFromWeek) {
      prompts.add(
        const HomePrompt(
          kind: HomePromptKind.kicks,
          question: 'Do you feel any kicks today?',
          answerKind: HomeAnswerKind.yesNo,
        ),
      );
    }

    // 5. Sleep, in the morning about last night and late at night about now.
    if (hour < 11 || hour >= 21) {
      prompts.add(
        HomePrompt(
          kind: HomePromptKind.sleep,
          question: hour < 11
              ? 'Did you sleep well last night?'
              : 'Are you getting enough rest, mommy?',
          answerKind: HomeAnswerKind.yesNo,
        ),
      );
    }

    // 6. Symptoms, last: it is the broadest question and the least urgent
    //    unless she raises something.
    prompts.add(
      const HomePrompt(
        kind: HomePromptKind.symptoms,
        question: 'Is anything bothering you today?',
        answerKind: HomeAnswerKind.yesNo,
      ),
    );

    return prompts;
  }

  bool _isMealLogged(String key) {
    if ((_context.totalToday(key) ?? 0) > 0) return true;
    // Earlier builds wrote breakfast under a different key; readers have to
    // check both or a logged breakfast looks missing.
    if (key == 'breakfast') return (_context.totalToday('break_fast') ?? 0) > 0;
    return false;
  }

  static HomePromptKind _mealKind(String key) => switch (key) {
        'breakfast' => HomePromptKind.breakfast,
        'lunch' => HomePromptKind.lunch,
        _ => HomePromptKind.dinner,
      };
}
