import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/services/allobot/allobot_context.dart';
import 'package:allomom/services/allobot/home_voice_flow.dart';

/// A pregnant mother at [week], at [hour] o'clock, with the given logs.
AlloBotContext contextAt({
  int hour = 8,
  int week = 24,
  bool isPregnant = true,
  bool isNewMom = false,
  Map<String, double> todayTotals = const {},
  List<AncVisitContext> ancVisits = const [],
  List<VaccineContext> vaccines = const [],
  List<TodayCareContext> todayCare = const [],
}) {
  final now = DateTime(2026, 9, 7, hour, 30);
  final day = (week - 1) * 7;

  // Derived from the hour, exactly as AlloBotContextLoader does it. Hardcoding
  // a headline would make the timing assertions below test the fixture rather
  // than the flow.
  final part = CareDayPart.at(now);

  return AlloBotContext(
    motherName: 'Ananya',
    isPregnant: isPregnant,
    isNewMom: isNewMom,
    pregnancyDay: isPregnant ? day : 0,
    gestationalWeek: isPregnant ? week : 0,
    daysLeftUntilEdd: isPregnant ? 280 - day : 0,
    now: now,
    dayPartLabel: part.label,
    greetingWord: part.greeting,
    dayPartHeadline: part.headline,
    formattedEdd: '28 Feb',
    todayTotals: todayTotals,
    ancVisits: ancVisits,
    vaccines: vaccines,
    todayCare: todayCare,
  );
}

HomeVoiceFlow flowAt({
  int hour = 8,
  int week = 24,
  bool isPregnant = true,
  Map<String, double> todayTotals = const {},
  List<AncVisitContext> ancVisits = const [],
  List<VaccineContext> vaccines = const [],
}) =>
    HomeVoiceFlow(
      context: contextAt(
        hour: hour,
        week: week,
        isPregnant: isPregnant,
        todayTotals: todayTotals,
        ancVisits: ancVisits,
        vaccines: vaccines,
      ),
    );

void main() {
  group('the greeting', () {
    test('opens with "Hi mommy" and where she is', () {
      final greeting = composeHomeGreeting(contextAt(week: 24));
      expect(greeting, startsWith('Hi mommy'));
      expect(greeting, contains('week 24'));
      expect(greeting, contains('2nd trimester'));
    });

    test('frames the day by the time of day', () {
      expect(composeHomeGreeting(contextAt(hour: 8)), contains('Breakfast time'));
      expect(composeHomeGreeting(contextAt(hour: 13)), contains('Lunch time'));
      expect(composeHomeGreeting(contextAt(hour: 20)), contains('Dinner time'));
    });

    test('mentions what is still outstanding on her care list', () {
      final greeting = composeHomeGreeting(
        contextAt(
          todayCare: const [
            TodayCareContext(
              id: 'water',
              title: 'Drink water',
              subtitle: '',
              dayPartLabel: 'Morning',
              target: 10,
              loggedToday: 2,
            ),
          ],
        ),
      );
      expect(greeting, contains('drink water'));
    });

    test('does not invent a week when there are no dates', () {
      final greeting = composeHomeGreeting(contextAt(isPregnant: false));
      expect(greeting, startsWith('Hi mommy'));
      expect(greeting, isNot(contains('week')));
    });
  });

  group('meals, by the clock', () {
    test('asks about breakfast in the morning', () {
      final prompt = flowAt(hour: 8).nextPrompt();
      expect(prompt!.kind, HomePromptKind.breakfast);
      expect(prompt.question, contains('breakfast'));
    });

    test('asks about lunch at lunchtime', () {
      final prompt = flowAt(hour: 13).nextPrompt();
      expect(prompt!.kind, HomePromptKind.lunch);
    });

    test('asks about dinner in the evening', () {
      final prompt = flowAt(hour: 20).nextPrompt();
      expect(prompt!.kind, HomePromptKind.dinner);
    });

    test('does not ask about a meal already logged', () {
      final prompt = flowAt(hour: 8, todayTotals: {'breakfast': 380}).nextPrompt();
      expect(prompt!.kind, isNot(HomePromptKind.breakfast));
    });

    test('recognises the legacy breakfast key', () {
      // Earlier builds wrote breakfast as `break_fast`; missing that would ask
      // about a meal she has already logged.
      final prompt =
          flowAt(hour: 8, todayTotals: {'break_fast': 380}).nextPrompt();
      expect(prompt!.kind, isNot(HomePromptKind.breakfast));
    });

    test('chases a missed breakfast later, in the past tense', () {
      // The case from the request: she never logged breakfast, so after the
      // window closes it is asked about as something already gone.
      final flow = flowAt(hour: 13);
      final lunch = flow.nextPrompt()!;
      expect(lunch.kind, HomePromptKind.lunch);
      flow.answer(lunch, affirmed: true);

      final prompts = <HomePromptKind>[];
      for (var i = 0; i < 4; i++) {
        final next = flow.nextPrompt();
        if (next == null) break;
        prompts.add(next.kind);
        flow.answer(next, affirmed: true);
      }
      expect(prompts, contains(HomePromptKind.breakfast));
    });

    test('a missed breakfast is not chased while its window is still open', () {
      final flow = flowAt(hour: 8);
      final first = flow.nextPrompt()!;
      expect(first.question, contains('Have you had'));
      expect(first.question, isNot(contains('earlier')));
    });

    test('a yes logs the meal', () {
      final flow = flowAt(hour: 8);
      final response = flow.answer(flow.nextPrompt()!, affirmed: true);
      expect(response.action, HomeFlowAction.logMeal);
      expect(response.mealKey, 'breakfast');
      expect(response.reply, contains('logged your breakfast'));
    });

    test('a no gives her a reason not to skip it', () {
      final flow = flowAt(hour: 8);
      final response = flow.answer(flow.nextPrompt()!, affirmed: false);
      expect(response.action, HomeFlowAction.none);
      expect(response.reply, contains('do not skip breakfast'));
    });
  });

  group('water', () {
    test('asks when nothing is logged', () {
      final flow = flowAt(hour: 10, todayTotals: {'breakfast': 380});
      final prompt = flow.nextPrompt()!;
      expect(prompt.kind, HomePromptKind.water);
      expect(prompt.question, contains('any water yet'));
    });

    test('counts up from what she already has', () {
      final flow = flowAt(
        hour: 10,
        todayTotals: {'breakfast': 380, 'water': 6},
      );
      expect(flow.nextPrompt()!.question, contains('6 glasses'));
    });

    test('a yes logs a glass and reports the new total', () {
      final flow = flowAt(hour: 10, todayTotals: {'breakfast': 380, 'water': 6});
      final response = flow.answer(flow.nextPrompt()!, affirmed: true);
      expect(response.action, HomeFlowAction.logWater);
      expect(response.reply, contains('7 glasses'));
    });

    test('a no tells her plainly to drink more', () {
      final flow = flowAt(hour: 10, todayTotals: {'breakfast': 380});
      final response = flow.answer(flow.nextPrompt()!, affirmed: false);
      expect(response.reply, contains('you need to drink more water'));
    });

    test('nudges when she is still short after logging one', () {
      final flow = flowAt(hour: 10, todayTotals: {'breakfast': 380, 'water': 1});
      final response = flow.answer(flow.nextPrompt()!, affirmed: true);
      expect(response.reply, contains('a fair way to go'));
    });

    test('stops asking once she has hit ten', () {
      final flow = flowAt(hour: 10, todayTotals: {'breakfast': 380, 'water': 10});
      var prompt = flow.nextPrompt();
      while (prompt != null && prompt.kind != HomePromptKind.water) {
        flow.answer(prompt, affirmed: true);
        prompt = flow.nextPrompt();
      }
      expect(prompt, isNull);
    });
  });

  group('movements', () {
    test('are not asked about before week 18', () {
      // Asking "do you feel any kicks?" at week 12 invites a worried no to a
      // question that has no business being asked yet.
      final flow = flowAt(hour: 15, week: 12, todayTotals: {'lunch': 600});
      var prompt = flow.nextPrompt();
      final kinds = <HomePromptKind>[];
      while (prompt != null) {
        kinds.add(prompt.kind);
        flow.answer(prompt, affirmed: true);
        prompt = flow.nextPrompt();
      }
      expect(kinds, isNot(contains(HomePromptKind.kicks)));
    });

    test('are asked about from week 18', () {
      final flow = flowAt(hour: 15, week: 18, todayTotals: {'lunch': 600});
      var prompt = flow.nextPrompt();
      final kinds = <HomePromptKind>[];
      while (prompt != null) {
        kinds.add(prompt.kind);
        flow.answer(prompt, affirmed: true);
        prompt = flow.nextPrompt();
      }
      expect(kinds, contains(HomePromptKind.kicks));
    });

    test('a yes opens the kick counter', () {
      final flow = flowAt(hour: 15, week: 24);
      final response = flow.answer(
        const HomePrompt(
          kind: HomePromptKind.kicks,
          question: 'Do you feel any kicks today?',
          answerKind: HomeAnswerKind.yesNo,
        ),
        affirmed: true,
      );
      expect(response.action, HomeFlowAction.openKickCounter);
    });

    test('a no says when to get checked', () {
      final flow = flowAt(hour: 15, week: 30);
      final response = flow.answer(
        const HomePrompt(
          kind: HomePromptKind.kicks,
          question: 'Do you feel any kicks today?',
          answerKind: HomeAnswerKind.yesNo,
        ),
        affirmed: false,
      );
      expect(response.reply, contains('fewer than ten'));
      expect(response.reply, contains('left side'));
    });
  });

  group('sleep and symptoms', () {
    test('sleep is asked about in the morning and at night, not midday', () {
      Set<HomePromptKind> kindsAt(int hour) {
        final flow = flowAt(
          hour: hour,
          todayTotals: {'breakfast': 380, 'lunch': 600, 'water': 10},
        );
        final kinds = <HomePromptKind>{};
        var prompt = flow.nextPrompt();
        while (prompt != null) {
          kinds.add(prompt.kind);
          flow.answer(prompt, affirmed: true);
          prompt = flow.nextPrompt();
        }
        return kinds;
      }

      expect(kindsAt(8), contains(HomePromptKind.sleep));
      expect(kindsAt(22), contains(HomePromptKind.sleep));
      expect(kindsAt(14), isNot(contains(HomePromptKind.sleep)));
    });

    test('poor sleep gets advice and opens the log', () {
      final flow = flowAt(hour: 8);
      final response = flow.answer(
        const HomePrompt(
          kind: HomePromptKind.sleep,
          question: 'Did you sleep well last night?',
          answerKind: HomeAnswerKind.yesNo,
        ),
        affirmed: false,
      );
      expect(response.reply, contains('you need more rest'));
      expect(response.action, HomeFlowAction.openSleepLog);
    });

    test('a symptom sends her to record it', () {
      final flow = flowAt(hour: 14);
      final response = flow.answer(
        const HomePrompt(
          kind: HomePromptKind.symptoms,
          question: 'Is anything bothering you today?',
          answerKind: HomeAnswerKind.yesNo,
        ),
        affirmed: true,
      );
      expect(response.action, HomeFlowAction.openSymptomLog);
    });
  });

  group('the same question is never asked twice', () {
    test('answering removes it from the queue', () {
      final flow = flowAt(hour: 8);
      final first = flow.nextPrompt()!;
      flow.answer(first, affirmed: true);
      expect(flow.nextPrompt()!.kind, isNot(first.kind));
      expect(flow.asked, contains(first.kind));
    });

    test('the queue eventually runs out', () {
      final flow = flowAt(hour: 8);
      var guard = 0;
      var prompt = flow.nextPrompt();
      while (prompt != null && guard++ < 20) {
        flow.answer(prompt, affirmed: true);
        prompt = flow.nextPrompt();
      }
      expect(prompt, isNull);
      expect(guard, lessThan(20));
    });
  });

  group('the post-visit questions', () {
    AncVisitContext visitToday() => AncVisitContext(
          id: 'anc-today',
          visitNumber: 3,
          scheduledDate: DateTime(2026, 9, 7, 9),
          status: 'pending',
        );

    test('start on their own when a visit is scheduled for today', () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      expect(flow.hasAncToday, isTrue);
    });

    test('do not start when the visit is another day', () {
      final flow = flowAt(
        hour: 8,
        ancVisits: [
          AncVisitContext(
            id: 'anc-later',
            visitNumber: 3,
            scheduledDate: DateTime(2026, 9, 20),
            status: 'pending',
          ),
        ],
      );
      expect(flow.hasAncToday, isFalse);
    });

    test('run in order and take priority over the daily questions', () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      flow.startAncFollowUp();

      final order = <HomePromptKind>[];
      while (flow.isInAncFlow) {
        final prompt = flow.nextPrompt()!;
        order.add(prompt.kind);
        flow.answer(
          prompt,
          affirmed: true,
          date: DateTime(2026, 10, 5),
          text: 'BP normal, continue iron',
        );
      }

      expect(order, [
        HomePromptKind.ancNextDate,
        HomePromptKind.ancSummary,
        HomePromptKind.ancVaccination,
        HomePromptKind.ancReport,
      ]);
    });

    test('a date updates the next check-up', () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      flow.startAncFollowUp();

      final response =
          flow.answer(flow.nextPrompt()!, date: DateTime(2026, 10, 5));
      expect(response.action, HomeFlowAction.updateNextAncDate);
      expect(response.date, DateTime(2026, 10, 5));
      expect(response.reply, contains('5 Oct'));
    });

    test('no date given leaves the schedule alone', () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      flow.startAncFollowUp();
      final response = flow.answer(flow.nextPrompt()!);
      expect(response.action, HomeFlowAction.none);
    });

    test("the doctor's words are stored against the visit", () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      flow.startAncFollowUp();
      flow.answer(flow.nextPrompt()!, date: DateTime(2026, 10, 5));

      final response = flow.answer(
        flow.nextPrompt()!,
        text: '  BP normal, continue iron  ',
      );
      expect(response.action, HomeFlowAction.saveAncSummary);
      expect(response.text, 'BP normal, continue iron');
    });

    test('blank notes are not stored', () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      flow.startAncFollowUp();
      flow.answer(flow.nextPrompt()!, date: DateTime(2026, 10, 5));
      final response = flow.answer(flow.nextPrompt()!, text: '   ');
      expect(response.action, HomeFlowAction.none);
    });

    test('a vaccination yes marks the dose given, a no leaves it pending', () {
      HomeFlowResponse vaccineAnswer(bool affirmed) {
        final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
        flow.startAncFollowUp();
        flow.answer(flow.nextPrompt()!, date: DateTime(2026, 10, 5));
        flow.answer(flow.nextPrompt()!, text: 'notes');
        return flow.answer(flow.nextPrompt()!, affirmed: affirmed);
      }

      expect(vaccineAnswer(true).action, HomeFlowAction.markVaccineDone);
      expect(vaccineAnswer(false).action, HomeFlowAction.none);
      expect(vaccineAnswer(false).reply, contains('left it pending'));
    });

    test('a report yes opens the upload screen', () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      flow.startAncFollowUp();
      flow.answer(flow.nextPrompt()!, date: DateTime(2026, 10, 5));
      flow.answer(flow.nextPrompt()!, text: 'notes');
      flow.answer(flow.nextPrompt()!, affirmed: true);

      final response = flow.answer(flow.nextPrompt()!, affirmed: true);
      expect(response.action, HomeFlowAction.openReportUpload);
    });

    test('the daily questions resume once the visit is recorded', () {
      final flow = flowAt(hour: 8, ancVisits: [visitToday()]);
      flow.startAncFollowUp();
      while (flow.isInAncFlow) {
        flow.answer(
          flow.nextPrompt()!,
          affirmed: true,
          date: DateTime(2026, 10, 5),
          text: 'notes',
        );
      }
      expect(flow.isInAncFlow, isFalse);
      expect(flow.nextPrompt()!.kind, HomePromptKind.breakfast);
    });
  });

  group('AlloBotContext.ancVisitToday', () {
    test("finds today's visit whatever its status", () {
      final context = contextAt(
        ancVisits: [
          AncVisitContext(
            id: 'a',
            visitNumber: 1,
            scheduledDate: DateTime(2026, 9, 1),
            status: 'done',
          ),
          AncVisitContext(
            id: 'b',
            visitNumber: 2,
            scheduledDate: DateTime(2026, 9, 7, 9),
            status: 'pending',
          ),
        ],
      );
      expect(context.ancVisitToday?.id, 'b');
    });

    test('is null when nothing is scheduled today', () {
      expect(contextAt().ancVisitToday, isNull);
    });
  });
}
