import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/allobot/allobot_context.dart';
import 'package:allomom/services/allobot/allobot_engine.dart';
import 'package:allomom/services/allobot/allobot_knowledge_base.dart';

import 'allobot_knowledge_base_test.dart' show buildFromRealSeeds;

final DateTime _now = DateTime(2026, 9, 7, 9, 30);

/// A context for a pregnancy at [week], with ANC visits at the given day
/// offsets from [_now].
AlloBotContext contextAt({
  int week = 24,
  bool isPregnant = true,
  bool isNewMom = false,
  List<int> pendingAncOffsets = const [14],
  List<AncVisitContext> extraVisits = const [],
  Map<String, double> todayTotals = const {},
  Map<String, VitalContext> latestVitals = const {},
  List<TodayCareContext> todayCare = const [],
  List<VaccineContext> vaccines = const [],
  List<LabReportContext> labReports = const [],
  String riskStatus = 'Low',
  DateTime? now,
}) {
  final at = now ?? _now;
  final day = (week - 1) * 7;
  var visitNumber = extraVisits.length + 1;

  return AlloBotContext(
    motherName: 'Ananya',
    isPregnant: isPregnant,
    isNewMom: isNewMom,
    pregnancyDay: isPregnant ? day : 0,
    gestationalWeek: isPregnant ? week : 0,
    daysLeftUntilEdd: isPregnant ? 280 - day : 0,
    now: at,
    dayPartLabel: 'Morning',
    greetingWord: 'Good morning',
    dayPartHeadline: 'Breakfast time',
    lmpDate: at.subtract(Duration(days: day)),
    eddDate: at.add(Duration(days: 280 - day)),
    formattedEdd: '28 Feb',
    riskStatus: riskStatus,
    ancVisits: [
      ...extraVisits,
      ...pendingAncOffsets.map(
        (offset) => AncVisitContext(
          visitNumber: visitNumber++,
          scheduledDate: at.add(Duration(days: offset)),
          status: 'pending',
        ),
      ),
    ],
    todayTotals: todayTotals,
    latestVitals: latestVitals,
    todayCare: todayCare,
    vaccines: vaccines,
    labReports: labReports,
  );
}

void main() {
  late AlloBotKnowledgeBase knowledgeBase;

  setUpAll(() => knowledgeBase = buildFromRealSeeds());

  AlloBotEngine engineWith(AlloBotContext context) =>
      AlloBotEngine(knowledgeBase: knowledgeBase, context: context);

  group('rule 1 — AlloBot speaks first', () {
    test('opens the conversation unprompted', () {
      final reply = engineWith(contextAt()).opening();
      expect(reply.kind, AlloBotReplyKind.greeting);
      expect(reply.text, contains('Good morning'));
      expect(reply.text, contains('Ananya'));
      expect(reply.chips, isNotEmpty);
    });

    test('grounds the greeting in her week and day', () {
      final reply = engineWith(contextAt(week: 24)).opening();
      expect(reply.text, contains('week 24'));
      expect(reply.grounding, contains('2nd trimester'));
      expect(reply.grounding.any((chip) => chip.startsWith('Week 24')), isTrue);
    });

    test('greets a mother with no pregnancy dates without inventing a week', () {
      final reply = engineWith(contextAt(isPregnant: false)).opening();
      expect(reply.text, isNot(contains('week')));
      expect(reply.kind, AlloBotReplyKind.greeting);
    });

    test('speaks a postpartum mother differently', () {
      final reply =
          engineWith(contextAt(isPregnant: false, isNewMom: true)).opening();
      expect(reply.text.toLowerCase(), contains('little one'));
    });
  });

  group('rule 2 — the ANC visit leads', () {
    test('leads with a visit due today', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [0])).opening();
      // Said before the gestational-age line, not after it.
      expect(reply.text.indexOf('today'), lessThan(reply.text.indexOf('week 24')));
      expect(reply.text, contains('ANC-1'));
    });

    test('leads with a visit due tomorrow', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [1])).opening();
      expect(reply.text, contains('tomorrow'));
    });

    test('leads with an overdue visit and says how late it is', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [-5])).opening();
      expect(reply.text, contains('overdue'));
      expect(reply.text, contains('5 days'));
    });

    test('mentions a distant visit without leading on it', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [40])).opening();
      expect(reply.text, contains('week 24'));
      expect(reply.text.indexOf('week 24'),
          lessThan(reply.text.indexOf('next check-up')));
    });

    test('an overdue visit outranks a later pending one', () {
      final context = contextAt(pendingAncOffsets: [-3, 20]);
      expect(context.daysUntilNextAnc, -3);
      expect(context.shouldLeadWithAnc, isTrue);
    });

    test('answers a direct ANC question from her schedule', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [2]))
          .ask('when is my next anc visit');
      expect(reply.kind, AlloBotReplyKind.contextual);
      expect(reply.text, contains('ANC-1'));
      expect(reply.text, contains('in 2 days'));
    });

    test('reports readings from the last completed visit', () {
      final reply = engineWith(
        contextAt(
          extraVisits: [
            AncVisitContext(
              visitNumber: 1,
              scheduledDate: _now.subtract(const Duration(days: 30)),
              actualDate: _now.subtract(const Duration(days: 30)),
              status: 'done',
              bp: '118/76',
              weightKg: 58.4,
              fetalHeartRate: 148,
            ),
          ],
        ),
      ).ask('when is my next check-up');
      expect(reply.text, contains('118/76'));
      expect(reply.text, contains('148 bpm'));
    });

    test('says so plainly when nothing is scheduled', () {
      final reply = engineWith(contextAt(pendingAncOffsets: []))
          .ask('when is my next anc visit');
      expect(reply.text.toLowerCase(), contains("don't have any antenatal"));
    });

    test('states the visit unprompted only in the opening turn', () {
      // Repeating the date on every answer turns a reminder into nagging.
      final engine = engineWith(contextAt(pendingAncOffsets: [1]));
      expect(engine.opening().text, contains('ANC-1'));

      expect(engine.ask('can I eat mangoes').text, isNot(contains('ANC-')));
      expect(engine.ask('can I eat spinach').text, isNot(contains('ANC-')));
      expect(engine.ask('why do I feel tired').text, isNot(contains('ANC-')));
    });

    test('still gives the date whenever she asks for it', () {
      final engine = engineWith(contextAt(pendingAncOffsets: [1]));
      engine.opening();
      engine.ask('can I eat mangoes');

      final reply = engine.ask('when is my next anc visit');
      expect(reply.text, contains('ANC-1'));
      expect(reply.text, contains('tomorrow'));
    });

    test('never points her at a visit that has already passed', () {
      // The bug in the screenshot: "ask it at your ANC-1 visit on 9 Aug
      // (29 days ago)" sent her to an appointment a month gone.
      final engine = engineWith(contextAt(pendingAncOffsets: [-29]));
      engine.opening();

      final thinking = engine.ask('how do I fix my car engine');
      expect(thinking.kind, AlloBotReplyKind.thinking);
      expect(thinking.text, isNot(contains('days ago')));
      expect(thinking.text, isNot(contains('ANC-')));
    });
  });

  group('rule 3 — answers are staged by day', () {
    test('the same kick question gets a different answer by week', () {
      final early = engineWith(contextAt(week: 12)).ask('kick count');
      final mid = engineWith(contextAt(week: 20)).ask('kick count');
      final late = engineWith(contextAt(week: 32)).ask('kick count');

      expect(early.text, contains('still early'));
      expect(early.showKickCounterCard, isFalse);

      expect(mid.text, contains('come and go'));
      expect(mid.showKickCounterCard, isTrue);

      expect(late.text, contains('10 movements in'));
      expect(late.showKickCounterCard, isTrue);
    });

    test('reports counted movements from today', () {
      final reply = engineWith(
        contextAt(week: 30, todayTotals: {'kick_count': 8}),
      ).ask('how many kicks today');
      expect(reply.text, contains('8 movements'));
    });

    test('stages a retrieved delivery answer by how close she is', () {
      final early = engineWith(contextAt(week: 20))
          .ask('what should I pack for the hospital');
      final late = engineWith(contextAt(week: 38))
          .ask('what should I pack for the hospital');

      expect(early.text, contains('You have time yet'));
      expect(late.text, contains('immediate'));
      // Both still serve the seed answer itself.
      expect(early.sourceLabel, isNotNull);
      expect(late.sourceLabel, isNotNull);
    });

    test('stages a nausea answer as on-schedule or worth mentioning', () {
      final early = engineWith(contextAt(week: 8)).ask('why do I have nausea');
      final late = engineWith(contextAt(week: 30)).ask('why do I have nausea');
      expect(early.text, contains('right on schedule'));
      expect(late.text, contains('usually passed'));
    });

    test('frames a nutrition answer by trimester', () {
      final reply = engineWith(contextAt(week: 30)).ask('can I eat mangoes');
      expect(reply.text, contains('3rd trimester'));
    });

    test('adds no stage note when the dates are unknown', () {
      final reply =
          engineWith(contextAt(isPregnant: false)).ask('can I eat mangoes');
      expect(reply.text, isNot(contains('week')));
    });

    test('reports gestational age with the day within the week', () {
      final reply = engineWith(contextAt(week: 24)).ask('how many weeks am I');
      expect(reply.text, contains('week 24'));
      expect(reply.text, contains('day 161'));
    });
  });

  group('rule 4 — off-corpus questions are not guessed at', () {
    test('says it is thinking rather than answering', () {
      final reply = engineWith(contextAt()).ask('how do I fix my car engine');
      expect(reply.kind, AlloBotReplyKind.thinking);
      expect(reply.text, contains('let me think'));
      expect(reply.text, contains('car engine'));
    });

    test('sends her to her nurse and turns to something in front of her', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [10]))
          .ask('what is the capital of france');
      expect(reply.kind, AlloBotReplyKind.thinking);
      expect(reply.text, contains('asking your nurse'));
      // Ends on a question about her day, not on a date.
      expect(reply.followUp, isNotNull);
      expect(reply.contextPrompt, isNotNull);
    });

    test('does not invent an answer for an uncovered fruit', () {
      final reply =
          engineWith(contextAt()).ask('is jackfruit safe during pregnancy');
      expect(reply.kind, AlloBotReplyKind.thinking);
    });

    test('offers near misses when it has any', () {
      final reply = engineWith(contextAt()).ask('do I need to take iron tablets');
      expect(reply.kind, AlloBotReplyKind.thinking);
      expect(reply.chips, isNotEmpty);
    });

    test('is honest when the corpus failed to load at all', () {
      final reply = AlloBotEngine(context: contextAt()).ask('can I eat mangoes');
      expect(reply.kind, AlloBotReplyKind.thinking);
    });
  });

  group('emergencies', () {
    test('escalates a danger sign instead of retrieving', () {
      final reply = engineWith(contextAt()).ask('I am bleeding a lot');
      expect(reply.kind, AlloBotReplyKind.emergency);
      expect(reply.isEmergency, isTrue);
      expect(reply.text, contains('same day'));
      expect(reply.followUp, isNull);
    });

    test('tells her not to wait for a scheduled visit', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [5]))
          .ask('my baby is not moving since morning');
      expect(reply.text, contains('Do not wait'));
      expect(reply.text, contains('left side'));
    });

    test('says more when her file is flagged high risk', () {
      final reply = engineWith(contextAt(riskStatus: 'High'))
          .ask('I have severe pain in my stomach');
      expect(reply.text, contains('extra care'));
    });

    test('an emergency is never softened by the ANC nudge', () {
      final reply =
          engineWith(contextAt(pendingAncOffsets: [1])).ask('I am bleeding');
      expect(reply.text, isNot(contains('One thing before you go')));
    });
  });

  group('answers from her own data', () {
    test('reports water against the day target', () {
      final reply = engineWith(contextAt(todayTotals: {'water': 6}))
          .ask('how much water have I had');
      expect(reply.text, contains('6 of 10 glasses'));
      expect(reply.text, contains('4 more'));
    });

    test('celebrates a met target without asking for more water', () {
      final reply = engineWith(contextAt(todayTotals: {'water': 10}))
          .ask('how much water have I had');
      expect(reply.text, contains('target met'));
      // It may still ask her something else, but not for more water.
      expect(reply.contextPrompt?.kind, isNot(ContextPromptKind.water));
    });

    test('does not read yesterday as today', () {
      // Only today's rows are summed into todayTotals, so an empty map means
      // nothing today, whatever last night's glasses said.
      final reply = engineWith(contextAt()).ask('how much water have I had');
      expect(reply.text, contains("haven't seen any water logged today"));
    });

    test('counts down to the due date', () {
      final reply = engineWith(contextAt(week: 24)).ask('what is my due date');
      expect(reply.text, contains('28 Feb'));
      expect(reply.text, contains('days away'));
    });

    test('lists what is still open on the care plan', () {
      final reply = engineWith(
        contextAt(
          todayCare: const [
            TodayCareContext(
              id: 'water',
              title: 'Drink water',
              subtitle: '',
              dayPartLabel: 'Morning',
              target: 10,
              loggedToday: 4,
              unit: 'glasses',
            ),
            TodayCareContext(
              id: 'walk',
              title: 'Short walk',
              subtitle: '',
              dayPartLabel: 'Morning',
            ),
          ],
        ),
      ).ask('what is pending today');
      expect(reply.text, contains('Drink water'));
      expect(reply.text, contains('6 glasses to go'));
      expect(reply.text, contains('Short walk'));
    });

    test('will not tell her to change a dose', () {
      final reply = engineWith(contextAt()).ask('when should I take my medicines');
      expect(reply.text, contains('will not tell you to start'));
    });
  });

  group('vaccination and lab reports on demand', () {
    test('names the vaccine and its date', () {
      final reply = engineWith(
        contextAt(
          vaccines: [
            VaccineContext(
              name: 'TT-2 (Tetanus Toxoid, 2nd dose)',
              doseNumber: 2,
              scheduledDate: _now.add(const Duration(days: 6)),
              status: 'pending',
            ),
          ],
        ),
      ).ask('when is my vaccine due');

      expect(reply.kind, AlloBotReplyKind.contextual);
      expect(reply.text, contains('TT-2'));
      expect(reply.text, contains('13 Sep'));
      expect(reply.text, contains('in 6 days'));
    });

    test('chases an overdue dose', () {
      final reply = engineWith(
        contextAt(
          vaccines: [
            VaccineContext(
              name: 'TT-1',
              doseNumber: 1,
              scheduledDate: _now.subtract(const Duration(days: 9)),
              status: 'pending',
            ),
          ],
        ),
      ).ask('is my injection due');
      expect(reply.text, contains('past due'));
    });

    test('says when every dose is done', () {
      final reply = engineWith(
        contextAt(
          vaccines: [
            VaccineContext(
              name: 'TT-1',
              doseNumber: 1,
              scheduledDate: _now.subtract(const Duration(days: 40)),
              status: 'done',
            ),
          ],
        ),
      ).ask('is my vaccination pending');
      expect(reply.text, contains('done'));
      expect(reply.text, contains('TT-1'));
    });

    test('names the lab test and its date', () {
      final reply = engineWith(
        contextAt(
          labReports: [
            LabReportContext(
              name: 'CBC',
              status: 'pending',
              dueDate: _now.add(const Duration(days: 3)),
            ),
            LabReportContext(
              name: 'USG Level II',
              status: 'pending',
              dueDate: _now.add(const Duration(days: 20)),
            ),
          ],
        ),
      ).ask('which tests are due');

      expect(reply.text, contains('CBC'));
      expect(reply.text, contains('10 Sep'));
      expect(reply.text, contains('2 tests are pending'));
    });

    test('ignores tests a doctor only orders when indicated', () {
      final reply = engineWith(
        contextAt(
          labReports: [
            LabReportContext(
              name: 'NST',
              status: 'pending',
              isRequired: false,
              dueDate: _now.add(const Duration(days: 2)),
            ),
          ],
        ),
      ).ask('which tests are due');
      // Nothing routine outstanding, so it must not chase the optional one.
      expect(reply.text, isNot(contains('NST')));
    });

    test('reports a result on file but defers reading it', () {
      final reply = engineWith(
        contextAt(
          labReports: [
            LabReportContext(
              name: 'Hemoglobin',
              status: 'done',
              completedDate: _now.subtract(const Duration(days: 5)),
              resultSummary: '10.2 g/dL',
            ),
            LabReportContext(
              name: 'CBC',
              status: 'pending',
              dueDate: _now.add(const Duration(days: 3)),
            ),
          ],
        ),
      ).ask('what are my test results');
      expect(reply.text, contains('10.2 g/dL'));
      expect(reply.text, contains('Your doctor reads these, not me'));
    });
  });

  group('questions AlloBot asks from timing and data', () {
    AlloBotContext withCare() => contextAt(
          todayTotals: const {'water': 3},
          todayCare: const [
            TodayCareContext(
              id: 'water',
              title: 'Drink water',
              subtitle: '',
              dayPartLabel: 'Morning',
              target: 10,
              loggedToday: 3,
              unit: 'glasses',
            ),
            TodayCareContext(
              id: 'iron_tablet',
              title: 'Iron tablet',
              subtitle: '',
              dayPartLabel: 'Morning',
            ),
          ],
        );

    test('asks about an outstanding care item, using the day part', () {
      final prompt = contextualPrompt(withCare());
      expect(prompt, isNotNull);
      expect(prompt!.kind, ContextPromptKind.water);
      expect(prompt.question, contains('this morning'));
      expect(prompt.question, contains('3 of 10'));
    });

    test('moves to a different subject the second time', () {
      final context = withCare();
      final first = contextualPrompt(context)!;
      final second = contextualPrompt(context, asked: {first.kind})!;
      expect(second.kind, isNot(first.kind));
      expect(second.kind, ContextPromptKind.supplement);
      expect(second.question, contains('iron tablet'));
    });

    test('asks about a dose or test that is due, not one months away', () {
      final soon = contextualPrompt(
        contextAt(
          vaccines: [
            VaccineContext(
              name: 'TT-2',
              doseNumber: 2,
              scheduledDate: _now.add(const Duration(days: 3)),
              status: 'pending',
            ),
          ],
        ),
      );
      expect(soon!.kind, ContextPromptKind.vaccination);

      final distant = contextualPrompt(
        contextAt(
          vaccines: [
            VaccineContext(
              name: 'TT-2',
              doseNumber: 2,
              scheduledDate: _now.add(const Duration(days: 60)),
              status: 'pending',
            ),
          ],
        ),
      );
      expect(distant!.kind, isNot(ContextPromptKind.vaccination));
    });

    test('asks about a vital the stream has no recent reading for', () {
      final prompt = contextualPrompt(
        contextAt(
          latestVitals: {
            'blood_pressure': VitalContext(
              key: 'blood_pressure',
              value: 118,
              unit: 'mmHg',
              recordedAt: _now.subtract(const Duration(days: 40)),
            ),
          },
        ),
        asked: const {ContextPromptKind.checkIn},
      );
      expect(prompt!.kind, ContextPromptKind.vitalReading);
      expect(prompt.question, contains('blood pressure'));
      expect(prompt.question, contains('40 days ago'));
    });

    test('does not ask about a vital recorded this week', () {
      final prompt = contextualPrompt(
        contextAt(
          latestVitals: {
            // Recorded under one of each measure's two key spellings, which
            // must be enough — the other spelling being absent is not staleness.
            'bp': VitalContext(
              key: 'bp',
              value: 118,
              unit: 'mmHg',
              recordedAt: _now.subtract(const Duration(days: 3)),
            ),
            'weight_kg': VitalContext(
              key: 'weight_kg',
              value: 58,
              unit: 'kg',
              recordedAt: _now.subtract(const Duration(days: 3)),
            ),
          },
        ),
        asked: const {ContextPromptKind.checkIn},
      );
      expect(prompt, isNull);
    });

    test('runs out of questions rather than repeating itself', () {
      final prompt = contextualPrompt(
        contextAt(),
        asked: ContextPromptKind.values.toSet(),
      );
      expect(prompt, isNull);
    });

    test('a yes to a care question gives her something to act on', () {
      final engine = engineWith(withCare());
      final opening = engine.opening();
      expect(opening.contextPrompt!.kind, ContextPromptKind.water);

      final reply = engine.ask('yes');
      expect(reply.kind, AlloBotReplyKind.contextual);
      expect(reply.text, contains('Keep it steady'));
    });

    test('a no is where the useful advice goes', () {
      final engine = engineWith(withCare());
      engine.opening();
      final reply = engine.ask('no');
      expect(reply.text, contains('Have a glass now'));
    });

    test('a no to a movement question says when to get checked', () {
      final engine = engineWith(
        contextAt(
          week: 30,
          todayCare: const [
            TodayCareContext(
              id: 'kick_count',
              title: 'Count kicks',
              subtitle: '',
              dayPartLabel: 'Evening',
            ),
          ],
        ),
      );
      engine.opening();
      final reply = engine.ask('no');
      expect(reply.text, contains('fewer than 10'));
      expect(reply.showKickCounterCard, isTrue);
    });

    test('answering one question leads to another on a new subject', () {
      final engine = engineWith(withCare());
      final opening = engine.opening();
      final answer = engine.ask('yes');
      expect(answer.contextPrompt, isNotNull);
      expect(answer.contextPrompt!.kind, isNot(opening.contextPrompt!.kind));
    });

    test('a seed follow-up is not overwritten by a data question', () {
      // The sheet's own question is more relevant right after its answer.
      final reply = engineWith(withCare()).ask('can I eat mangoes');
      expect(reply.contextPrompt, isNull);
      expect(reply.followUp, contains('mango'));
    });
  });

  group('conversation', () {
    test('a bare yes answers the follow-up it just offered', () {
      final engine = engineWith(contextAt(pendingAncOffsets: [40]));
      final first = engine.ask('can I eat mangoes');
      expect(first.followUp, isNotNull);

      final second = engine.ask('yes');
      // Not a request for clarification — it acted on the follow-up.
      expect(second.text, isNot(contains('Tell me a little more')));
    });

    test('names a dead-end follow-up instead of repeating itself', () {
      // The mango row asks "want to know how much you can eat in a day?" and
      // the sheets have no row that answers it, so retrieval loops back to the
      // same row. Serving that paragraph again reads as not listening.
      final engine = engineWith(contextAt(pendingAncOffsets: [2]));
      final first = engine.ask('can I eat mangoes');
      final second = engine.ask('yes');

      expect(second.text, isNot(contains(first.text)));
      expect(second.text, contains('past what I can say for certain'));
      expect(second.text, isNot(contains('ANC-')));
    });

    test('a yes with nothing pending asks what she means', () {
      final reply = engineWith(contextAt()).ask('yes');
      expect(reply.text, contains('Tell me a little more'));
    });

    test('a no closes the thread kindly', () {
      final engine = engineWith(contextAt());
      engine.ask('can I eat mangoes');
      final reply = engine.ask('no');
      expect(reply.kind, AlloBotReplyKind.smallTalk);
      expect(reply.text, contains('whenever'));
    });

    test('says so rather than pretending a repeat is new', () {
      // Mango has one clearly correct row and only weak runners-up, so the
      // right move is to repeat it and be honest, not to serve second best.
      final engine = engineWith(contextAt(pendingAncOffsets: [40]));
      final first = engine.ask('can I eat mangoes');
      final second = engine.ask('can I eat mangoes');
      expect(second.entryId, first.entryId);
      expect(second.text, contains('same answer I gave a moment ago'));
    });

    test('prefers an unserved row when one is just as good', () {
      // Two rows phrased almost identically, so their scores land within the
      // freshness window and the second ask should move on to the other.
      const csv = 'Key,Mother’s Question (English),Allobaby Response (English)\n'
          'a,"Is walking safe during pregnancy?","Yes, walking daily is good."\n'
          'b,"Is walking safe in pregnancy?","Walking is one of the best exercises."\n';
      final engine = AlloBotEngine(
        knowledgeBase:
            AlloBotKnowledgeBase.build(sheets: {'Lifestyle & Daily Activities': csv}),
        context: contextAt(pendingAncOffsets: [40]),
      );

      final first = engine.ask('is walking safe during pregnancy');
      final second = engine.ask('is walking safe during pregnancy');
      expect(second.entryId, isNot(first.entryId));
      expect(second.text, isNot(contains('same answer I gave a moment ago')));
    });

    test('a new chat forgets the conversation but keeps the corpus', () {
      final engine = engineWith(contextAt(pendingAncOffsets: [40]));
      final first = engine.ask('can I eat mangoes');
      engine.reset();
      final again = engine.ask('can I eat mangoes');
      expect(again.entryId, first.entryId);
    });

    test('thanks is answered warmly, not retrieved', () {
      final reply = engineWith(contextAt()).ask('thank you so much');
      expect(reply.kind, AlloBotReplyKind.smallTalk);
    });

    test('an empty message is not sent as a question', () {
      final reply = engineWith(contextAt()).ask('   ');
      expect(reply.kind, AlloBotReplyKind.thinking);
    });
  });

  group('spoken text', () {
    test('strips emoji so TTS does not read them aloud', () {
      final reply = engineWith(contextAt()).opening();
      expect(reply.text, contains('🌸'));
      expect(reply.spokenText, isNot(contains('🌸')));
    });

    test('keeps the words of every script', () {
      expect(stripForSpeech('அம்மா, நல்லா இருக்கீங்களா? 🌸'),
          contains('அம்மா'));
      expect(stripForSpeech('हाँ मां ❤️'), contains('हाँ'));
    });

    test('includes the follow-up question', () {
      final reply = engineWith(contextAt(pendingAncOffsets: [40]))
          .ask('can I eat mangoes');
      expect(reply.fullText, contains(reply.followUp!));
    });
  });

  group('describeDayOffset', () {
    test('reads the way a person would say it', () {
      expect(describeDayOffset(0), 'today');
      expect(describeDayOffset(1), 'tomorrow');
      expect(describeDayOffset(-1), 'yesterday');
      expect(describeDayOffset(-4), '4 days ago');
      expect(describeDayOffset(3), 'in 3 days');
      expect(describeDayOffset(9), 'in about a week');
      expect(describeDayOffset(21), 'in about 3 weeks');
      expect(describeDayOffset(90), 'in about 3 months');
    });
  });

  group('multilingual answers', () {
    test('serves the seed answer in Tamil when Tamil is chosen', () {
      final tamil = AlloBotEngine(
        knowledgeBase: knowledgeBase,
        context: contextAt(pendingAncOffsets: [40]),
        language: 'ta',
      ).ask('can I eat mangoes');
      final english = engineWith(contextAt(pendingAncOffsets: [40]))
          .ask('can I eat mangoes');

      expect(tamil.text, isNot(english.text));
      // Tamil script present.
      expect(RegExp(r'[஀-௿]').hasMatch(tamil.text), isTrue);
    });

    test('falls back to English for a language the sheets lack', () {
      final kannada = AlloBotEngine(
        knowledgeBase: knowledgeBase,
        context: contextAt(pendingAncOffsets: [40]),
        language: 'kn',
      ).ask('can I eat mangoes');
      expect(kannada.text, contains('mango'));
    });
  });
}
