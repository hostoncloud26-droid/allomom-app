/// AlloBot's conversational engine.
///
/// Puts the three halves together: [AlloBotKnowledgeBase] holds the curated
/// answers, [AlloBotContext] holds the mother's live pregnancy / health /
/// vitals / care data, and this file decides which of them a given turn should
/// be answered from and how the answer should be phrased for the day she is on.
///
/// Four rules drive the phrasing:
///
///  1. **AlloBot speaks first.** Opening the chat produces a greeting built
///     from her context, not a static "how can I help".
///  2. **The ANC visit leads.** When an antenatal visit is due within three
///     days (or is overdue) that is the first thing said, before anything else.
///  3. **Answers are staged by day.** The same question about movements gets a
///     different answer at week 12 than at week 32, so retrieved text is framed
///     by gestational age rather than served flat.
///  4. **Off-corpus questions are not guessed at.** Anything retrieval is not
///     confident about returns a "let me think about that" reply that routes
///     her to her care team, never an invented answer.
///
/// The composition functions are top-level and pure so each rule can be tested
/// against a fixed context and clock.
library;

import 'package:allomom/services/allobot/allobot_context.dart';
import 'package:allomom/services/allobot/allobot_intents.dart';
import 'package:allomom/services/allobot/allobot_knowledge_base.dart';
import 'package:allomom/services/allobot/allobot_retriever.dart';

/// Where a reply came from, which the UI uses to style the bubble.
enum AlloBotReplyKind {
  /// The unprompted opening turn.
  greeting,

  /// Answered from the mother's own data.
  contextual,

  /// Answered from the seed corpus.
  knowledge,

  /// A danger sign was mentioned.
  emergency,

  /// Retrieval was not confident enough to answer.
  thinking,

  /// Hello / thanks / yes / no.
  smallTalk,
}

/// One bot turn.
class AlloBotReply {
  const AlloBotReply({
    required this.text,
    required this.kind,
    this.followUp,
    this.chips = const [],
    this.sourceLabel,
    this.showKickCounterCard = false,
    this.grounding = const [],
    this.entryId,
    this.contextPrompt,
  });

  final String text;
  final AlloBotReplyKind kind;

  /// The question AlloBot asks back, taken from the seed sheet's
  /// "Next Trigger Question" column when the answer came from retrieval.
  final String? followUp;

  /// Tappable suggestions for the next turn.
  final List<String> chips;

  /// Topic the answer was retrieved from, shown as a citation.
  final String? sourceLabel;

  final bool showKickCounterCard;

  /// Short facts the answer was grounded in ("Week 24 · Day 168",
  /// "ANC-4 in 2 days"), shown as chips under the bubble so the mother can see
  /// what the bot based its answer on.
  final List<String> grounding;

  /// Seed entry the answer came from, so the engine does not repeat itself.
  final String? entryId;

  /// Set when [followUp] is a question AlloBot asked off her own data rather
  /// than one taken from a seed sheet, so a yes or no can be answered against
  /// the right thing.
  final ContextPrompt? contextPrompt;

  bool get isEmergency => kind == AlloBotReplyKind.emergency;

  /// The full text including the follow-up question, which is what gets spoken
  /// and what a screen reader should read.
  String get fullText =>
      followUp == null || followUp!.isEmpty ? text : '$text\n\n$followUp';

  /// [fullText] with emoji and pictographs removed, for TTS — a speech engine
  /// reads "❤️" aloud as "red heart", which breaks the tone completely.
  String get spokenText => stripForSpeech(fullText);
}

final RegExp _emojiPattern = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2190}-\u{21FF}\u{2B00}-\u{2BFF}'
  r'\u{FE0F}\u{200D}\u{20E3}\u{2022}]',
  unicode: true,
);

/// Strips emoji, bullets and doubled whitespace so TTS reads cleanly.
String stripForSpeech(String text) => text
    .replaceAll(_emojiPattern, '')
    .replaceAll('·', ',')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .replaceAll(RegExp(r'\n{2,}'), '\n')
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .join('. ')
    .replaceAll(RegExp(r'\.\s*\.'), '.')
    .trim();

/// Renders a logged amount without a pointless decimal: 8 rather than 8.0.
String formatCount(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

// ─────────────────────────────────────────────────────────────────────────────
// Grounding fragments
// ─────────────────────────────────────────────────────────────────────────────

/// How AlloBot addresses her. Falls back to "Amma" rather than a blank.
String motherAddress(AlloBotContext context) {
  final name = context.motherName.trim();
  if (name.isEmpty || name.toLowerCase() == 'amma') return 'Amma';
  return name.split(' ').first;
}

/// "week 24, day 3" — the gestational-age phrase every staged answer opens on.
String gestationalPhrase(AlloBotContext context) {
  if (!context.hasGestationalAge) return '';
  final day = context.dayWithinWeek;
  if (day <= 1) return 'week ${context.gestationalWeek}';
  return 'week ${context.gestationalWeek}, day $day';
}

/// The grounding chips shown under a bubble.
List<String> groundingFor(AlloBotContext context) {
  final chips = <String>[];
  if (context.hasGestationalAge) {
    chips.add('Week ${context.gestationalWeek} · Day ${context.pregnancyDay}');
    chips.add(context.trimesterLabel);
  }
  final anc = context.nextAncVisit;
  final days = context.daysUntilNextAnc;
  if (anc != null && days != null) {
    chips.add('ANC-${anc.visitNumber} ${describeDayOffset(days)}');
  }
  if (context.eddDate != null && context.isPregnant) {
    chips.add('EDD ${context.formattedEdd}');
  }
  return chips;
}

/// The ANC sentence, or an empty string when there is nothing scheduled.
///
/// This is the line rule 2 is about: it is phrased by how close the visit is,
/// so an overdue visit reads as a nudge and a distant one as reassurance.
String ancSentence(AlloBotContext context, {bool lead = false}) {
  final visit = context.nextAncVisit;
  final days = context.daysUntilNextAnc;
  if (visit == null || days == null) {
    if (context.lastCompletedAncVisit != null) {
      final last = context.lastCompletedAncVisit!;
      final on = last.actualDate ?? last.scheduledDate;
      return 'Your last check-up (ANC-${last.visitNumber}) was on '
          '${formatShortDate(on)}. There is nothing else booked right now — '
          'ask your nurse when the next one should be.';
    }
    return '';
  }

  final label = 'ANC-${visit.visitNumber}';
  final date = formatShortDate(visit.scheduledDate);

  if (days < 0) {
    final late = -days;
    return '$label was due on $date, so it is $late '
        '${late == 1 ? 'day' : 'days'} overdue. Please book it today — '
        'skipping a visit is the one thing I would gently push you on.';
  }
  if (days == 0) {
    return 'Your $label check-up is **today** ($date). Carry your ANC card, '
        'your last reports and a list of anything you want to ask.';
  }
  if (days == 1) {
    return 'Your $label check-up is **tomorrow** ($date). Keep your ANC card '
        'and reports ready tonight.';
  }
  if (days <= 3) {
    return 'Your $label check-up is in $days days, on $date.';
  }
  if (lead) return '';
  return 'Your next check-up, $label, is on $date (${describeDayOffset(days)}).';
}

// ─────────────────────────────────────────────────────────────────────────────
// Opening turn — rule 1 and rule 2
// ─────────────────────────────────────────────────────────────────────────────

/// The turn AlloBot speaks unprompted when the chat opens.
///
/// Leads with the ANC visit when one is imminent or overdue, otherwise with
/// gestational progress, and always ends with something she can tap.
AlloBotReply composeOpening(AlloBotContext context) {
  final name = motherAddress(context);
  final lines = <String>[];

  lines.add('${context.greetingWord}, $name 🌸');

  if (!context.isPregnant) {
    if (context.isNewMom) {
      lines.add(
        "I'm here for you and your little one. Ask me about feeding, "
        'recovery, sleep or anything that feels off.',
      );
    } else {
      lines.add(
        "I'm AlloBot, your companion here. Ask me about cycles, planning, "
        'nutrition or how you are feeling today.',
      );
    }
    return AlloBotReply(
      text: lines.join('\n\n'),
      kind: AlloBotReplyKind.greeting,
      chips: suggestionChips(context),
      grounding: groundingFor(context),
    );
  }

  // Rule 2: an imminent or overdue visit is said before anything else.
  final ancLead = context.shouldLeadWithAnc ? ancSentence(context, lead: true) : '';
  if (ancLead.isNotEmpty) {
    lines.add(ancLead);
    if (context.hasGestationalAge) {
      lines.add(
        "You're at ${gestationalPhrase(context)} — "
        '${stageHeadline(context)}',
      );
    }
  } else {
    if (context.hasGestationalAge) {
      lines.add(
        "You're at ${gestationalPhrase(context)} of your "
        '${context.trimesterLabel} — ${stageHeadline(context)}',
      );
      if (context.eddDate != null) {
        lines.add(
          'That puts your baby in your arms around ${context.formattedEdd}, '
          '${context.daysLeftUntilEdd} days from today.',
        );
      }
    } else {
      lines.add("I'm here with you. Tell me how you are feeling today.");
    }
    final anc = ancSentence(context);
    if (anc.isNotEmpty) lines.add(anc);
  }

  final pending = context.outstandingCare;
  if (pending.isNotEmpty) {
    lines.add(
      '${context.dayPartHeadline.isEmpty ? 'For now' : context.dayPartHeadline}: '
      '${pending.take(2).map((item) => item.title.toLowerCase()).join(' and ')} '
      'still to go on your care list.',
    );
  }

  lines.add('What would you like to talk about, $name?');

  return AlloBotReply(
    text: lines.join('\n\n'),
    kind: AlloBotReplyKind.greeting,
    chips: suggestionChips(context),
    grounding: groundingFor(context),
  );
}

/// One line on what this stage of pregnancy is about — rule 3, applied to the
/// greeting.
String stageHeadline(AlloBotContext context) {
  final week = context.gestationalWeek;
  if (week <= 8) return 'your baby is just taking shape, and rest matters most now.';
  if (week <= 12) {
    return "the first trimester is nearly behind you, and nausea usually eases from here.";
  }
  if (week <= 16) return 'the tiredness normally lifts around now and appetite returns.';
  if (week <= 20) return 'you may start feeling the very first flutters any day.';
  if (week <= 24) return 'movements are getting stronger and your baby can hear your voice.';
  if (week <= 28) {
    return 'this is a good stretch to build a daily movement-counting habit.';
  }
  if (week <= 32) return 'baby is putting on weight fast, so iron and protein matter.';
  if (week <= 36) return 'time to get your hospital bag and birth plan ready.';
  if (week <= 40) return 'you are full term — labour could start any day now.';
  return 'you are past your due date, so keep in close touch with your doctor.';
}

/// Starter suggestions, drawn from the seed topics where available.
List<String> suggestionChips(AlloBotContext context, {AlloBotKnowledgeBase? knowledgeBase}) {
  final chips = <String>[];
  if (context.isPregnant) {
    if (context.nextAncVisit != null) chips.add('When is my next ANC visit?');
    if (context.hasGestationalAge) {
      chips.add('How is my baby at week ${context.gestationalWeek}?');
    }
    chips.add('What should I eat today?');
    if (context.gestationalWeek >= 20) chips.add('Why does baby kick more at night?');
    chips.add('Which symptoms need a doctor immediately?');
  } else {
    chips.add('What should I eat today?');
    chips.add('How is my cycle looking?');
    chips.add('Which symptoms need a doctor immediately?');
  }

  final seeded = knowledgeBase?.sampleQuestions(limit: 2) ?? const <String>[];
  for (final question in seeded) {
    if (chips.length >= 5) break;
    if (!chips.contains(question)) chips.add(question);
  }
  return chips.take(5).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Emergency
// ─────────────────────────────────────────────────────────────────────────────

/// The escalation turn. Deliberately short, unhedged, and never followed by a
/// chatty question.
AlloBotReply composeEmergencyReply(RedFlag flag, AlloBotContext context) {
  final name = motherAddress(context);
  final lines = <String>[
    '$name, I want you to take this seriously right now. ❤️',
    flag.advice,
  ];

  if (context.hasGestationalAge) {
    lines.add(
      'You are at ${gestationalPhrase(context)}, so tell whoever sees you '
      'that, along with what you are feeling.',
    );
  }
  if (context.isHighRisk) {
    lines.add(
      'Your file is marked as needing extra care, so please do not wait this out.',
    );
  }

  final anc = context.nextAncVisit;
  final days = context.daysUntilNextAnc;
  if (anc != null && days != null && days > 0) {
    lines.add(
      'Do not wait for your ANC-${anc.visitNumber} visit on '
      '${formatShortDate(anc.scheduledDate)} — this needs looking at before then.',
    );
  }

  lines.add('I am not a doctor, and this is one where a person needs to see you.');

  return AlloBotReply(
    text: lines.join('\n\n'),
    kind: AlloBotReplyKind.emergency,
    chips: const ['What are the other danger signs?', 'Which symptoms need a doctor immediately?'],
    grounding: groundingFor(context),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Contextual answers — from her own data
// ─────────────────────────────────────────────────────────────────────────────

/// Answers a context intent from [context], or returns null when the data
/// needed is missing and retrieval should handle it instead.
AlloBotReply? composeContextualReply(
  AlloBotIntent intent,
  AlloBotContext context,
) {
  final name = motherAddress(context);
  final grounding = groundingFor(context);

  AlloBotReply reply(
    String text, {
    String? followUp,
    List<String> chips = const [],
    bool kickCard = false,
  }) =>
      AlloBotReply(
        text: text,
        kind: AlloBotReplyKind.contextual,
        followUp: followUp,
        chips: chips,
        grounding: grounding,
        showKickCounterCard: kickCard,
      );

  switch (intent) {
    case AlloBotIntent.ancSchedule:
      final sentence = ancSentence(context);
      if (sentence.isEmpty) {
        return reply(
          "I don't have any antenatal visits on your schedule yet, $name. "
          'Once your pregnancy is registered with your dates, I can keep track '
          'of every check-up for you.',
          chips: const ['What happens at an ANC visit?'],
        );
      }
      final parts = <String>[sentence];
      if (context.pendingAncCount > 1) {
        parts.add(
          'You have ${context.pendingAncCount} visits left on your plan in all.',
        );
      }
      if (context.missedAncCount > 0) {
        parts.add(
          '${context.missedAncCount} earlier '
          '${context.missedAncCount == 1 ? 'visit was' : 'visits were'} marked '
          'missed — worth mentioning to your nurse.',
        );
      }
      final last = context.lastCompletedAncVisit;
      if (last != null) {
        final readings = <String>[
          if (last.bp != null && last.bp!.isNotEmpty) 'BP ${last.bp}',
          if (last.weightKg != null) '${last.weightKg!.toStringAsFixed(1)} kg',
          if (last.fetalHeartRate != null) 'heartbeat ${last.fetalHeartRate} bpm',
        ];
        if (readings.isNotEmpty) {
          parts.add(
            'At your last visit they noted ${readings.join(', ')}.',
          );
        }
      }
      return reply(
        parts.join('\n\n'),
        followUp: 'Shall I tell you what to carry and what they will check?',
        chips: const ['What happens at an ANC visit?', 'Which tests are done in this month?'],
      );

    case AlloBotIntent.dueDate:
      if (context.eddDate == null) {
        return reply(
          "I don't have your due date yet, $name. If you tell me your last "
          'period date in your profile, I can work it out and count down with you.',
        );
      }
      final weeksLeft = (context.daysLeftUntilEdd / 7).floor();
      return reply(
        'Your due date is ${context.formattedEdd}, $name — '
        '${context.daysLeftUntilEdd} days away, about '
        '$weeksLeft ${weeksLeft == 1 ? 'week' : 'weeks'}.\n\n'
        'You are at ${gestationalPhrase(context)} today, '
        '${stageHeadline(context)}',
        followUp: 'Would you like to know what to get ready before then?',
        chips: const ['What should I pack in my hospital bag?', 'What are the signs of labour?'],
      );

    case AlloBotIntent.gestationalStatus:
      if (!context.hasGestationalAge) {
        return reply(
          "I don't have your dates yet, $name, so I can't tell you which week "
          'you are in. Add your last period date and I will keep count for you.',
        );
      }
      final lines = <String>[
        'You are at ${gestationalPhrase(context)} — day ${context.pregnancyDay} '
            'of your pregnancy, in your ${context.trimesterLabel}.',
        'At this stage, ${stageHeadline(context)}',
      ];
      if (context.eddDate != null) {
        lines.add(
          '${context.daysLeftUntilEdd} days to go until ${context.formattedEdd}.',
        );
      }
      final anc = ancSentence(context);
      if (anc.isNotEmpty) lines.add(anc);
      return reply(
        lines.join('\n\n'),
        followUp: 'Shall I tell you what your baby is doing this week?',
        chips: ['How is my baby growing?', 'What should I eat at week ${context.gestationalWeek}?'],
      );

    case AlloBotIntent.waterIntake:
      final logged = context.totalToday('water');
      final target = _careTarget(context, 'water') ?? 10;
      if (logged == null) {
        return reply(
          "I haven't seen any water logged today yet, $name. Aim for about "
          '$target glasses through the day — it helps with swelling, '
          'constipation and those Braxton-Hicks tightenings.',
          followUp: 'Want me to remind you every couple of hours?',
        );
      }
      final left = (target - logged).clamp(0.0, target.toDouble()).toDouble();
      return reply(
        left <= 0
            ? "You've had ${formatCount(logged)} glasses today, $name — that is "
                'your target met. Lovely. 💧'
            : "You've logged ${formatCount(logged)} of $target glasses today, "
                '$name. About ${formatCount(left)} more to go.',
        followUp: left <= 0 ? null : 'Shall I remind you at your next care slot?',
      );

    case AlloBotIntent.kickCount:
      final week = context.gestationalWeek;
      final kicks = context.totalToday('kick_count');
      // Rule 3: the same question gets a materially different answer by week.
      if (context.hasGestationalAge && week < 16) {
        return reply(
          'At ${gestationalPhrase(context)} it is still early, $name — most '
          'mothers feel the first flutters between week 18 and 22, and later '
          'still with a first baby. Nothing to worry about yet.',
          followUp: 'Shall I tell you what those first movements feel like?',
        );
      }
      if (context.hasGestationalAge && week < 24) {
        return reply(
          'At ${gestationalPhrase(context)} movements come and go, $name — some '
          'days you will feel plenty, some days almost none. Formal counting '
          'usually starts around week 28.',
          followUp: 'Would you like to try the kick counter anyway?',
          kickCard: true,
        );
      }
      final base = kicks == null
          ? 'Nothing counted today yet, $name.'
          : 'You counted ${formatCount(kicks)} movements today, $name.';
      return reply(
        '$base At ${gestationalPhrase(context)} the guide is 10 movements in '
        'two hours. Lie on your left side after a meal — that is when babies '
        'are liveliest.',
        followUp: 'Shall we count together now?',
        kickCard: true,
        chips: const ['Why does baby kick more at night?'],
      );

    case AlloBotIntent.weight:
      final weight = context.vital('weight') ?? context.vital('weight_kg');
      final recorded = weight?.value ?? context.weightKg;
      if (recorded == null) {
        return reply(
          "I don't have a weight logged for you yet, $name. Through pregnancy "
          'a gain of 10–12 kg overall is typical, and your nurse will weigh you '
          'at every visit.',
        );
      }
      final expected = _expectedGain(context.gestationalWeek);
      return reply(
        'Your last recorded weight is ${recorded.toStringAsFixed(1)} kg, $name. '
        'By ${gestationalPhrase(context)}, a total gain of about $expected is '
        'usual — but the trend across visits matters far more than any one '
        'number, so let your nurse read it.',
        followUp: 'Shall I tell you which foods help healthy weight gain?',
      );

    case AlloBotIntent.bloodPressure:
      final bp = context.vital('blood_pressure') ?? context.vital('bp');
      final lastVisit = context.lastCompletedAncVisit;
      if (bp == null && (lastVisit?.bp == null || lastVisit!.bp!.isEmpty)) {
        return reply(
          "I don't have a blood pressure reading for you yet, $name. It is "
          'checked at every ANC visit — around 120/80 is the usual range, and '
          '140/90 or above needs attention.',
          chips: const ['What are the signs of high BP in pregnancy?'],
        );
      }
      final reading = lastVisit?.bp?.isNotEmpty == true
          ? lastVisit!.bp!
          : bp!.displayValue;
      return reply(
        'Your last recorded blood pressure was $reading, $name. Anything from '
        '140/90 upwards, or a headache with blurred vision, means getting '
        'checked the same day.',
        chips: const ['What are the signs of high BP in pregnancy?'],
      );

    case AlloBotIntent.vaccination:
      final dose = context.nextVaccine;
      if (dose == null) {
        final given = context.vaccines.where((v) => v.isDone).toList();
        return reply(
          given.isEmpty
              ? "I don't see any vaccine doses on your schedule yet, $name. TT "
                  'or Tdap and a flu shot are the usual ones in pregnancy — '
                  'worth confirming at your next visit.'
              : 'Every dose on your schedule is done, $name — '
                  '${given.map((v) => v.name).join(', ')}. Nothing pending.',
        );
      }
      final vaccineDays = dose.daysFrom(context.now);
      return reply(
        'Your next dose is **${dose.name}**, due on '
        '**${formatShortDate(dose.scheduledDate)}** '
        '(${describeDayOffset(vaccineDays)}), $name.'
        '${vaccineDays < 0 ? ' It is past due — please get it done this week.' : ''}'
        '${context.vaccines.where((v) => !v.isDone).length > 1 ? '\n\nYou have '
            '${context.vaccines.where((v) => !v.isDone).length} doses left on '
            'your plan in all.' : ''}',
        followUp: 'Would you like to know why this dose matters?',
      );

    case AlloBotIntent.labReport:
      final report = context.nextLabReport;
      final done = context.completedLabReports;
      if (report == null) {
        return reply(
          done.isEmpty
              ? "I don't have any lab tests on your checklist yet, $name. Your "
                  'nurse will order blood and urine tests at your visits, and '
                  'I will track them here once they are on your plan.'
              : 'Nothing pending on your test checklist, $name — '
                  '${done.take(3).map((r) => r.name).join(', ')} '
                  '${done.length == 1 ? 'is' : 'are'} done.',
        );
      }
      final reportDays = report.daysFrom(context.now);
      final due = report.dueDate;
      final lines = <String>[
        due == null
            ? 'Your next test is **${report.name}**, $name — no date set on it '
                'yet, so ask at your next visit.'
            : 'Your next test is **${report.name}**, due on '
                '**${formatShortDate(due)}**'
                '${reportDays == null ? '' : ' (${describeDayOffset(reportDays)})'}'
                ', $name.'
                '${reportDays != null && reportDays < 0 ? ' It is past due — '
                    'please get it done this week.' : ''}',
      ];
      if (context.pendingLabReportCount > 1) {
        lines.add(
          '${context.pendingLabReportCount} tests are pending on your plan in '
          'all.',
        );
      }
      final lastResult = done.firstWhere(
        (r) => r.resultSummary != null && r.resultSummary!.isNotEmpty,
        orElse: () => const LabReportContext(name: '', status: 'pending'),
      );
      if (lastResult.name.isNotEmpty) {
        lines.add(
          'Your last result on file is ${lastResult.name}: '
          '${lastResult.resultSummary}. Your doctor reads these, not me.',
        );
      }
      return reply(
        lines.join('\n\n'),
        followUp: 'Shall I tell you what this test is for?',
      );

    case AlloBotIntent.todayCare:
      final pending = context.outstandingCare;
      if (context.todayCare.isEmpty) {
        return reply(
          "I can't see your care list right now, $name. Open Today's Care from "
          'your home screen and it will be there.',
        );
      }
      if (pending.isEmpty) {
        return reply(
          'Everything on your care list is done for today, $name. '
          '${context.dayPartLabel} is yours — rest. 🌸',
        );
      }
      final items = pending.take(4).map((item) {
        final left = item.remaining;
        final amount = left == null || left == 0
            ? ''
            : ' — ${formatCount(left)} ${item.unit} to go';
        return '• ${item.title}$amount';
      }).join('\n');
      return reply(
        'Still open for ${context.dayPartLabel.toLowerCase()}, $name:\n\n$items',
        followUp: 'Shall I start with the easiest one?',
      );

    case AlloBotIntent.medication:
      final conditions = context.medicalConditions;
      return reply(
        'Your prescriptions and their timings live in the Prescriptions '
        'section, $name — I can remind you, but I will not tell you to start, '
        'stop or change a dose.'
        '${conditions.isEmpty ? '' : ' Your file notes ${conditions.join(', ')}, '
            'so any change really does need your doctor.'}'
        '\n\nIron and calcium are the two most mothers are on; take iron with '
        'something citrus and never with milk or tea.',
        followUp: 'Would you like to know why iron matters so much now?',
      );

    // Not context intents — handled elsewhere.
    case AlloBotIntent.emergency:
    case AlloBotIntent.greeting:
    case AlloBotIntent.gratitude:
    case AlloBotIntent.affirmation:
    case AlloBotIntent.negation:
    case AlloBotIntent.knowledge:
      return null;
  }
}

int? _careTarget(AlloBotContext context, String id) {
  for (final item in context.todayCare) {
    if (item.id.contains(id)) return item.target;
  }
  return null;
}

/// Typical cumulative gain by gestational week, phrased as a range.
String _expectedGain(int week) {
  if (week <= 12) return '1–2 kg';
  if (week <= 20) return '3–5 kg';
  if (week <= 28) return '6–8 kg';
  if (week <= 36) return '9–11 kg';
  return '10–13 kg';
}

// ─────────────────────────────────────────────────────────────────────────────
// Knowledge answers — retrieval, staged by day
// ─────────────────────────────────────────────────────────────────────────────

/// A stage-specific caveat to put in front of a retrieved answer, or null when
/// the topic does not change with gestational age.
///
/// This is rule 3 applied to the corpus: the seed sheets are written
/// stage-neutrally ("yes mom, you can eat mangoes"), so the engine adds the
/// timing the sheet leaves out.
String? stageQualifier(KnowledgeEntry entry, AlloBotContext context) {
  if (!context.hasGestationalAge) return null;
  final week = context.gestationalWeek;
  final haystack = '${entry.slug} ${entry.question} ${entry.topicLabel}'.toLowerCase();

  bool mentions(List<String> words) => words.any(haystack.contains);

  if (mentions(['kick', 'movement', 'moving', 'flutter'])) {
    if (week < 18) {
      return 'You are at ${gestationalPhrase(context)}, so movements may not be '
          'obvious yet — this is for the weeks ahead.';
    }
    if (week >= 28) {
      return 'At ${gestationalPhrase(context)} this matters daily, so count '
          'movements at the same time each day.';
    }
    return null;
  }

  if (mentions(['nausea', 'vomit', 'morning sickness', 'sick'])) {
    return week <= 14
        ? 'At ${gestationalPhrase(context)} this is right on schedule and it '
            'usually settles by week 14.'
        : 'At ${gestationalPhrase(context)} sickness has usually passed, so if '
            'it is still strong, mention it at your next visit.';
  }

  if (mentions(['delivery', 'labour', 'labor', 'hospital bag', 'birth', 'contraction'])) {
    if (week < 28) {
      return 'You have time yet at ${gestationalPhrase(context)} — good to '
          'know early, no need to act on it now.';
    }
    if (week >= 36) {
      return 'At ${gestationalPhrase(context)} this is immediate — please have '
          'your bag and transport sorted.';
    }
    return 'At ${gestationalPhrase(context)} it is a good time to start '
        'planning this properly.';
  }

  if (mentions(['scan', 'ultrasound', 'test', 'blood test', 'anomaly'])) {
    final anc = context.nextAncVisit;
    if (anc != null) {
      return 'Your ANC-${anc.visitNumber} visit on '
          '${formatShortDate(anc.scheduledDate)} is the natural place to ask '
          'about this.';
    }
    return null;
  }

  if (mentions(['iron', 'calcium', 'folic', 'supplement', 'anaemia', 'anemia'])) {
    if (week <= 12) {
      return 'Folic acid matters most in these early weeks at '
          '${gestationalPhrase(context)}.';
    }
    if (week >= 28) {
      return 'Iron demand peaks in the third trimester, so at '
          '${gestationalPhrase(context)} this is worth being strict about.';
    }
    return null;
  }

  if (mentions(['eat', 'food', 'diet', 'fruit', 'vegetable', 'nutrition', 'drink'])) {
    return 'At ${gestationalPhrase(context)} you are in your '
        '${context.trimesterLabel}, so ${_nutritionNote(context.trimesterNumber)}';
  }

  return null;
}

String _nutritionNote(int trimester) => switch (trimester) {
      1 => 'small frequent meals sit best, and folic acid is the priority.',
      2 => 'iron and calcium are what your baby is drawing on most now.',
      _ => 'protein and iron matter most, in smaller meals as space gets tight.',
    };

/// Builds the answer for a confident retrieval hit.
AlloBotReply composeKnowledgeReply(
  RetrievedEntry retrieved,
  AlloBotContext context, {
  String language = primarySeedLanguage,
  bool isRepeat = false,
}) {
  final entry = retrieved.entry;
  final locale = entry.localeFor(language);
  final lines = <String>[];

  if (isRepeat) {
    lines.add(
      'This is the same answer I gave a moment ago — it is the best I have on '
      'this:',
    );
  }

  final qualifier = stageQualifier(entry, context);
  if (qualifier != null) lines.add(qualifier);

  lines.add(locale.answer);

  // A softer hedge when retrieval was only moderately confident, so the mother
  // can tell a close match from an exact one.
  if (retrieved.confidence < strongConfidenceThreshold) {
    lines.add(
      'That is the closest thing I know on this — if it is not quite what you '
      'meant, say it another way and I will try again.',
    );
  }

  if (entry.isSafetyTopic) {
    lines.add('If it feels worse than this describes, please get checked today.');
  }

  return AlloBotReply(
    text: lines.join('\n\n'),
    kind: AlloBotReplyKind.knowledge,
    followUp: locale.followUp.isEmpty ? null : locale.followUp,
    sourceLabel: entry.topicLabel,
    entryId: entry.id,
    grounding: groundingFor(context),
    showKickCounterCard: _isKickTopic(entry) && context.gestationalWeek >= 16,
  );
}

bool _isKickTopic(KnowledgeEntry entry) {
  final haystack = '${entry.slug} ${entry.question}'.toLowerCase();
  return haystack.contains('kick') || haystack.contains('movement');
}

// ─────────────────────────────────────────────────────────────────────────────
// Questions AlloBot asks her, from the clock and her data
// ─────────────────────────────────────────────────────────────────────────────

/// The kinds of question AlloBot asks off her own data, which decides how a
/// "yes" or "no" to it is answered.
enum ContextPromptKind {
  water,
  supplement,
  activity,
  rest,
  kickCount,
  vaccination,
  labReport,
  vitalReading,
  checkIn,
}

/// A question AlloBot puts to her, and what it is about.
class ContextPrompt {
  const ContextPrompt(this.kind, this.question);

  final ContextPromptKind kind;
  final String question;
}

/// Picks something to ask her, from the time of day and what her data shows.
///
/// This is what AlloBot uses instead of ending a turn on a dead end or on a
/// reminder it has already given. Today's Care is already scoped to the current
/// day part, so walking her outstanding items is timing-aware for free: the
/// iron tablet only comes up while it is still morning, the movement count only
/// in the evening. Behind those come the things her records show are missing —
/// a dose or a test past due, a vital nobody has recorded in weeks.
///
/// [asked] holds the kinds already put to her this conversation, so a second
/// question moves on to a different subject rather than repeating the first.
/// Returns null once there is nothing new worth asking — better to end a turn
/// without a question than to manufacture one.
ContextPrompt? contextualPrompt(
  AlloBotContext context, {
  Set<ContextPromptKind> asked = const {},
}) {
  final candidates = <ContextPrompt>[
    ..._careItemPrompts(context),
    ..._recordPrompts(context),
    ..._vitalPrompts(context),
    if (context.hasGestationalAge)
      ContextPrompt(
        ContextPromptKind.checkIn,
        'How have you been feeling at ${gestationalPhrase(context)}?',
      )
    else
      const ContextPrompt(
        ContextPromptKind.checkIn,
        'How have you been feeling lately?',
      ),
  ];

  for (final candidate in candidates) {
    if (!asked.contains(candidate.kind)) return candidate;
  }
  return null;
}

/// Questions drawn from what is still open on Today's Care.
List<ContextPrompt> _careItemPrompts(AlloBotContext context) {
  final part = context.dayPartLabel.toLowerCase();
  final prompts = <ContextPrompt>[];

  for (final item in context.outstandingCare) {
    final id = item.id.toLowerCase();
    final title = item.title.toLowerCase();

    if (id.contains('water')) {
      final logged = context.totalToday('water');
      final target = item.target;
      final progress = logged == null
          ? 'I have not seen any logged yet today'
          : 'you are at ${formatCount(logged)}'
              '${target == null ? '' : ' of $target'} so far';
      prompts.add(
        ContextPrompt(
          ContextPromptKind.water,
          'Have you had any water this $part? By my count $progress.',
        ),
      );
    } else if (id.contains('tablet') ||
        id.contains('folic') ||
        id.contains('iron') ||
        id.contains('calcium')) {
      prompts.add(
        ContextPrompt(
          ContextPromptKind.supplement,
          'Did you take your $title this $part?',
        ),
      );
    } else if (id.contains('kick')) {
      // Only worth asking once counting is the advice for her stage.
      if (context.gestationalWeek >= 16) {
        prompts.add(
          ContextPrompt(
            ContextPromptKind.kickCount,
            'Have you felt your baby move this $part?',
          ),
        );
      }
    } else if (id.contains('rest') || id.contains('sleep')) {
      prompts.add(
        ContextPrompt(
          ContextPromptKind.rest,
          'Have you managed to rest this $part?',
        ),
      );
    } else if (id.contains('walk') ||
        id.contains('movement') ||
        id.contains('stretch')) {
      prompts.add(
        ContextPrompt(
          ContextPromptKind.activity,
          'Did you get your $title in this $part?',
        ),
      );
    } else {
      prompts.add(
        ContextPrompt(
          ContextPromptKind.checkIn,
          'Have you had a chance to $title this $part?',
        ),
      );
    }
  }

  return prompts;
}

/// Questions drawn from her vaccination and lab-test records.
///
/// Only asked about when something is actually due or past due — a dose three
/// months out is not a question, it is trivia.
List<ContextPrompt> _recordPrompts(AlloBotContext context) {
  final prompts = <ContextPrompt>[];

  final dose = context.nextVaccine;
  if (dose != null) {
    final days = dose.daysFrom(context.now);
    if (days <= 7) {
      prompts.add(
        ContextPrompt(
          ContextPromptKind.vaccination,
          days < 0
              ? 'Your ${dose.name} dose was due ${describeDayOffset(days)} — '
                  'have you had it?'
              : 'Your ${dose.name} dose is due ${describeDayOffset(days)} — '
                  'have you had it yet?',
        ),
      );
    }
  }

  final report = context.nextLabReport;
  if (report != null) {
    final days = report.daysFrom(context.now);
    if (days == null || days <= 7) {
      prompts.add(
        ContextPrompt(
          ContextPromptKind.labReport,
          days != null && days < 0
              ? 'Your ${report.name} test was due ${describeDayOffset(days)} — '
                  'has it been done?'
              : 'Your ${report.name} test is coming up — has it been done yet?',
        ),
      );
    }
  }

  return prompts;
}

/// Questions drawn from gaps in the vitals stream.
///
/// A blood pressure last taken five weeks ago is not a current reading, and
/// asking about it is more use than quoting it as though it were.
List<ContextPrompt> _vitalPrompts(AlloBotContext context) {
  if (!context.isPregnant) return const [];

  // One measure, several key spellings — see [AlloBotContext.daysSinceAnyVital].
  const measures = <String, List<String>>{
    'blood pressure': ['blood_pressure', 'bp'],
    'weight': ['weight', 'weight_kg'],
  };

  final prompts = <ContextPrompt>[];
  measures.forEach((label, keys) {
    if (!context.isVitalStale(keys)) return;
    final since = context.daysSinceAnyVital(keys);
    prompts.add(
      ContextPrompt(
        ContextPromptKind.vitalReading,
        since == null
            ? 'I do not have a $label reading for you at all — has it been '
                'checked?'
            : 'Your last $label reading here is ${describeDayOffset(-since)} — '
                'has it been checked since?',
      ),
    );
  });

  return prompts;
}

/// Answers a yes or no to the question AlloBot asked.
///
/// Each kind gets something she can act on rather than a bare
/// acknowledgement — a "no" is where the useful advice belongs.
AlloBotReply resolveContextPrompt(
  ContextPrompt prompt,
  bool affirmed,
  AlloBotContext context,
) {
  final name = motherAddress(context);
  var showKickCard = false;
  final String text;

  switch (prompt.kind) {
    case ContextPromptKind.water:
      text = affirmed
          ? 'Good, $name. Keep it steady through the day rather than all at '
              'once — it is what keeps swelling and constipation down.'
          : 'Have a glass now if you can, $name. Little and often beats a lot '
              'in one go, and it helps with swelling, constipation and those '
              'practice tightenings.';
    case ContextPromptKind.supplement:
      text = affirmed
          ? 'Well done. One thing worth knowing: iron works best with '
              'something citrus, and never with milk or tea — they block it.'
          : 'Take it after a meal today if you can, $name. If it upsets your '
              'stomach, say so at your next visit rather than stopping it — '
              'that is your doctor\'s call, not mine.';
    case ContextPromptKind.kickCount:
      showKickCard = context.gestationalWeek >= 16;
      text = affirmed
          ? 'That is what I like to hear, $name. At '
              '${gestationalPhrase(context)} the guide is 10 movements in two '
              'hours — you can log them here if you want to keep track.'
          : 'Lie on your left side after something to eat and give it two '
              'hours, $name — that is when babies are liveliest. If you count '
              'fewer than 10 movements, please get checked today rather than '
              'waiting.';
    case ContextPromptKind.rest:
      text = affirmed
          ? 'Good. Rest is doing real work at ${gestationalPhrase(context)}, '
              'even when it feels like doing nothing.'
          : 'Try to take twenty minutes off your feet when you can, $name — '
              'on your left side is best for the blood flow to your baby.';
    case ContextPromptKind.activity:
      text = affirmed
          ? 'Lovely. A short daily walk does more for your back and your sleep '
              'than almost anything else I could suggest.'
          : 'No pressure, $name. Even ten minutes on the flat counts — and if '
              'you feel dizzy or tight anywhere, stop and rest instead.';
    case ContextPromptKind.vaccination:
      text = affirmed
          ? 'Good. Make sure it is written on your ANC card, $name — that card '
              'is the record everyone else works from.'
          : 'Please get it booked this week, $name. These doses protect your '
              'baby in the first weeks after birth, when they cannot be '
              'vaccinated themselves.';
    case ContextPromptKind.labReport:
      text = affirmed
          ? 'Good. Carry the report to your next visit even if the clinic has '
              'a copy — it saves the test being repeated.'
          : 'Try to get it done before your next visit, $name, so your doctor '
              'has the result in front of her rather than ordering it again.';
    case ContextPromptKind.vitalReading:
      text = affirmed
          ? 'Good — log the reading here if you have it, $name. One number '
              'says little; the trend across weeks is what your doctor reads.'
          : 'It is checked at every antenatal visit, so it will be taken then. '
              'If you have a machine at home, logging it here lets me keep the '
              'trend for you.';
    case ContextPromptKind.checkIn:
      text = affirmed
          ? 'I am glad, $name. Tell me if anything changes — I would rather '
              'hear about something small early than late.'
          : 'I am sorry to hear that, $name. Tell me what you are feeling and '
              'I will help you work out whether it needs a doctor today.';
  }

  return AlloBotReply(
    text: text,
    kind: AlloBotReplyKind.contextual,
    chips: suggestionChips(context),
    grounding: groundingFor(context),
    showKickCounterCard: showKickCard,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// The "thinking" turn — rule 4
// ─────────────────────────────────────────────────────────────────────────────

/// The reply for a question the corpus does not cover.
///
/// Named "thinking" because that is what it says: AlloBot is explicit that it
/// is turning the question over and does not have a grounded answer, rather
/// than improvising one. It then does two useful things — points at what it
/// *can* answer, and hands her a real route to a person.
AlloBotReply composeThinkingReply(
  String query,
  AlloBotContext context, {
  List<RetrievedEntry> nearMisses = const [],
}) {
  final name = motherAddress(context);
  final trimmed = query.trim();
  final quoted = trimmed.length > 90 ? '${trimmed.substring(0, 90)}…' : trimmed;

  final lines = <String>[
    'Hmm, let me think about that one, $name… 🤔',
    'I don\'t have anything I trust on "$quoted", and this is not a subject '
        'I want to guess at. So I would rather say I don\'t know than tell you '
        'something wrong.',
  ];

  if (nearMisses.isNotEmpty) {
    final suggestions = nearMisses
        .take(3)
        .map((candidate) => '• ${candidate.entry.question}')
        .join('\n');
    lines.add('These are the nearest things I do know about:\n\n$suggestions');
  }

  // No ANC pointer here on purpose. The visit is said once, in the opening
  // turn; repeating it on every question the corpus cannot answer turns a
  // reminder into nagging — and when the visit is already past, "ask it at
  // your visit on 9 Aug (29 days ago)" is simply wrong.
  lines.add('Worth writing down and asking your nurse or doctor directly.');

  if (context.hasGestationalAge) {
    lines.add(
      'And if it is something you are feeling right now at '
      '${gestationalPhrase(context)}, tell me the symptom instead and I will '
      'help you work out whether it needs a doctor today.',
    );
  }

  // The closing question is attached by the engine, not here: only it knows
  // what has already been asked this conversation, and repeating the opening's
  // question two turns later is exactly the nagging this replaced.
  return AlloBotReply(
    text: lines.join('\n\n'),
    kind: AlloBotReplyKind.thinking,
    chips: nearMisses.isEmpty
        ? suggestionChips(context)
        : nearMisses.take(3).map((candidate) => candidate.entry.question).toList(),
    grounding: groundingFor(context),
  );
}

/// The reply for a follow-up AlloBot cannot actually take further.
///
/// The seed sheets end most rows with an inviting question — "want to know how
/// much mango you can eat in a day?" — but frequently have no second row that
/// answers it. Putting the follow-up back through retrieval then lands on the
/// very row that asked it, and answering "yes" returns the same paragraph she
/// just read, which reads as if the bot were not listening.
///
/// So a dead end is named as one. She asked a reasonable question and deserves
/// to know the answer exists elsewhere rather than being handed a loop.
AlloBotReply composeFollowUpDeadEnd(
  String followUp,
  KnowledgeEntry offeredBy,
  AlloBotContext context,
) {
  final name = motherAddress(context);
  final lines = <String>[
    'I asked you that hoping I had more for you, $name — but the detail behind '
        'it is past what I can say for certain. 🤔',
  ];

  lines.add(
    'Worth asking your nurse — she can give you amounts and timings for your '
    'body, which I should not guess at.',
  );

  // The engine adds the closing question, so it can pick one she has not been
  // asked yet.
  return AlloBotReply(
    text: lines.join('\n\n'),
    kind: AlloBotReplyKind.thinking,
    sourceLabel: offeredBy.topicLabel,
    grounding: groundingFor(context),
    chips: suggestionChips(context),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// The engine
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the corpus, the current context and the conversation's short memory,
/// and turns a typed question into a reply.
class AlloBotEngine {
  AlloBotEngine({
    AlloBotKnowledgeBase? knowledgeBase,
    AlloBotContext? context,
    this.language = primarySeedLanguage,
  })  : _knowledgeBase = knowledgeBase ?? AlloBotKnowledgeBase.empty(),
        _context = context ?? AlloBotContext.placeholder() {
    _retriever = AlloBotRetriever(_knowledgeBase);
  }

  /// Language the seed answers are served in.
  ///
  /// Only the retrieved answers translate. The context lines AlloBot composes
  /// itself — the ANC date, the week, the day's care — stay in English, because
  /// there is nothing to translate them from; the sheets carry answers, not UI
  /// copy. So a non-English chat is bilingual rather than fully translated.
  final String language;

  AlloBotKnowledgeBase _knowledgeBase;
  late AlloBotRetriever _retriever;
  AlloBotContext _context;

  /// The entry AlloBot last answered from, so an "yes, tell me more" can be
  /// resolved against it.
  KnowledgeEntry? _lastEntry;

  /// The follow-up question AlloBot last offered, if the mother has not yet
  /// answered it.
  String? _pendingFollowUp;

  /// Seed rows already served, so the same answer is not repeated verbatim.
  final Set<String> _servedEntryIds = <String>{};

  /// The question AlloBot last asked off her data, if she has not answered it.
  ContextPrompt? _pendingPrompt;

  /// Subjects already put to her this conversation, so a second question moves
  /// on rather than repeating the first.
  final Set<ContextPromptKind> _askedPromptKinds = <ContextPromptKind>{};

  AlloBotContext get context => _context;
  AlloBotKnowledgeBase get knowledgeBase => _knowledgeBase;
  bool get isReady => !_knowledgeBase.isEmpty;

  /// Replaces the corpus once the seeds finish loading.
  void attachKnowledgeBase(AlloBotKnowledgeBase knowledgeBase) {
    _knowledgeBase = knowledgeBase;
    _retriever = AlloBotRetriever(knowledgeBase);
  }

  /// Refreshes the grounding data — call after vitals or ANC rows change.
  void updateContext(AlloBotContext context) => _context = context;

  /// Clears the conversation memory, keeping the corpus and context.
  void reset() {
    _lastEntry = null;
    _pendingFollowUp = null;
    _pendingPrompt = null;
    _servedEntryIds.clear();
    _askedPromptKinds.clear();
  }

  /// Rule 1: the turn AlloBot speaks before being asked anything.
  AlloBotReply opening() {
    final reply = composeOpening(_context);
    _pendingFollowUp = null;
    _pendingPrompt = null;

    // The opening is the one turn that states the ANC visit unprompted, and it
    // ends by asking her something rather than trailing off.
    final prompt = contextualPrompt(_context, asked: _askedPromptKinds);
    if (prompt != null) _askedPromptKinds.add(prompt.kind);
    _pendingPrompt = prompt;

    return AlloBotReply(
      text: reply.text,
      kind: reply.kind,
      followUp: prompt?.question ?? reply.followUp,
      contextPrompt: prompt,
      chips: suggestionChips(_context, knowledgeBase: _knowledgeBase),
      sourceLabel: reply.sourceLabel,
      showKickCounterCard: reply.showKickCounterCard,
      grounding: reply.grounding,
    );
  }

  /// Answers [query].
  AlloBotReply ask(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return composeThinkingReply('', _context);
    }

    final match = classifyIntent(trimmed);

    // Red flags bypass everything, including a pending follow-up.
    if (match.isEmergency && match.redFlag != null) {
      _pendingFollowUp = null;
      _pendingPrompt = null;
      return composeEmergencyReply(match.redFlag!, _context);
    }

    switch (match.intent) {
      case AlloBotIntent.affirmation:
        // A question AlloBot asked off her data takes precedence over a seed
        // follow-up: it is the more recent thing on the table, and it is about
        // her rather than about the corpus.
        final prompt = _pendingPrompt;
        if (prompt != null) {
          _pendingPrompt = null;
          return _remember(
            _withContextPrompt(resolveContextPrompt(prompt, true, _context)),
          );
        }
        final reply = _resolveAffirmation();
        if (reply != null) return _remember(_withContextPrompt(reply));
      case AlloBotIntent.negation:
        final declined = _pendingPrompt;
        _pendingFollowUp = null;
        _pendingPrompt = null;
        if (declined != null) {
          return _remember(
            _withContextPrompt(resolveContextPrompt(declined, false, _context)),
          );
        }
        return _remember(
          _withContextPrompt(
            AlloBotReply(
              text: 'Of course, ${motherAddress(_context)}. I am here whenever '
                  'you want to pick it back up. 🌸',
              kind: AlloBotReplyKind.smallTalk,
              chips: suggestionChips(_context, knowledgeBase: _knowledgeBase),
            ),
          ),
        );
      case AlloBotIntent.greeting:
        return _remember(_withContextPrompt(_greetingReply()));
      case AlloBotIntent.gratitude:
        return _remember(
          _withContextPrompt(
            AlloBotReply(
              text: 'Any time, ${motherAddress(_context)}. That is what I am '
                  'here for. ❤️',
              kind: AlloBotReplyKind.smallTalk,
              chips: suggestionChips(_context, knowledgeBase: _knowledgeBase),
            ),
          ),
        );
      default:
        break;
    }

    if (match.needsContext) {
      final reply = composeContextualReply(match.intent, _context);
      if (reply != null) return _remember(_withContextPrompt(reply));
    }

    return _remember(_withContextPrompt(_retrieveReply(trimmed)));
  }

  /// Retrieval plus the confidence gate that decides between an answer and the
  /// "thinking" turn.
  AlloBotReply _retrieveReply(String query) {
    if (_knowledgeBase.isEmpty) {
      return composeThinkingReply(query, _context);
    }

    final result = _retriever.search(query, limit: 5);
    final best = result.best;

    if (best == null || !result.isAnswerable) {
      // Near misses are only worth showing when they at least share a term.
      final nearMisses = result.candidates
          .where((candidate) => candidate.coverage >= 0.25)
          .toList();
      _pendingFollowUp = null;
      return composeThinkingReply(query, _context, nearMisses: nearMisses);
    }

    // Prefer an equally-good row that has not been served yet, so asking twice
    // in different words does not return the identical paragraph.
    //
    // "Equally good" is the important part: for a question with one clearly
    // correct row ("can I eat mangoes") the runners-up are much weaker, and
    // serving one of those to avoid repeating itself would trade a right
    // answer for a wrong one. So the fallback is to repeat, and say so.
    var chosen = best;
    var isRepeat = false;
    if (_servedEntryIds.contains(best.entry.id)) {
      chosen = result.candidates.firstWhere(
        (candidate) =>
            !_servedEntryIds.contains(candidate.entry.id) &&
            candidate.confidence >= answerConfidenceThreshold &&
            candidate.score >= best.score * 0.7,
        orElse: () => best,
      );
      isRepeat = chosen.entry.id == best.entry.id;
    }

    final reply = composeKnowledgeReply(
      chosen,
      _context,
      language: language,
      isRepeat: isRepeat,
    );
    _lastEntry = chosen.entry;
    _servedEntryIds.add(chosen.entry.id);
    _pendingFollowUp = reply.followUp;
    return reply;
  }

  /// "Yes" / "tell me more" — answers the follow-up AlloBot itself offered.
  ///
  /// The seed sheets chain naturally here: the follow-up text is a real
  /// question, so putting it back through retrieval walks the mother one step
  /// deeper into the topic she is already in.
  AlloBotReply? _resolveAffirmation() {
    final pending = _pendingFollowUp;
    if (pending == null || pending.isEmpty) {
      // Nothing offered, so "yes" on its own is not answerable.
      return AlloBotReply(
        text: 'Tell me a little more, ${motherAddress(_context)} — what would '
            'you like to know?',
        kind: AlloBotReplyKind.smallTalk,
        chips: suggestionChips(_context, knowledgeBase: _knowledgeBase),
      );
    }

    // The row that offered the follow-up, captured before retrieval overwrites
    // it, so a loop back to the same row can be recognised.
    final offeredBy = _lastEntry;
    _pendingFollowUp = null;

    final reply = _retrieveReply(pending);

    final loopedBack = offeredBy != null && reply.entryId == offeredBy.id;
    final wentNowhere = reply.kind == AlloBotReplyKind.thinking;
    if (offeredBy != null && (loopedBack || wentNowhere)) {
      return composeFollowUpDeadEnd(pending, offeredBy, _context);
    }
    return reply;
  }

  AlloBotReply _greetingReply() {
    final lines = <String>[
      '${_context.greetingWord}, ${motherAddress(_context)} 🌸',
    ];
    if (_context.hasGestationalAge) {
      lines.add(
        'You are at ${gestationalPhrase(_context)} — ${stageHeadline(_context)}',
      );
    }
    lines.add('How are you feeling today?');
    return AlloBotReply(
      text: lines.join('\n\n'),
      kind: AlloBotReplyKind.smallTalk,
      chips: suggestionChips(_context, knowledgeBase: _knowledgeBase),
      grounding: groundingFor(_context),
    );
  }

  /// Attaches a question drawn from her timing and data, when the reply has no
  /// follow-up of its own.
  ///
  /// This is what fills the space the ANC nudge used to occupy. The visit is
  /// stated once, in the opening turn; after that a turn ends by asking about
  /// something in front of her instead of restating a date she has been told.
  AlloBotReply _withContextPrompt(AlloBotReply reply) {
    if (reply.isEmergency) return reply;
    if (reply.followUp != null && reply.followUp!.isNotEmpty) return reply;

    final prompt = contextualPrompt(_context, asked: _askedPromptKinds);
    if (prompt == null) return reply;

    return AlloBotReply(
      text: reply.text,
      kind: reply.kind,
      followUp: prompt.question,
      contextPrompt: prompt,
      chips: reply.chips,
      sourceLabel: reply.sourceLabel,
      showKickCounterCard: reply.showKickCounterCard,
      grounding: reply.grounding,
      entryId: reply.entryId,
    );
  }

  /// Records what a reply left hanging, so a bare yes or no can be resolved
  /// against the right thing.
  AlloBotReply _remember(AlloBotReply reply) {
    _pendingPrompt = reply.contextPrompt;
    _pendingFollowUp =
        reply.contextPrompt == null ? reply.followUp : null;
    final kind = reply.contextPrompt?.kind;
    if (kind != null) _askedPromptKinds.add(kind);
    return reply;
  }

}
