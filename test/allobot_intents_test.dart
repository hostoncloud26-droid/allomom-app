import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/allobot/allobot_intents.dart';

void main() {
  group('containsPhrase', () {
    test('matches on whole words only', () {
      expect(containsPhrase('my bp is high', 'bp'), isTrue);
      // Substring matching here would be actively harmful: it fires "no" inside
      // "nose" and turns a question into a refusal.
      expect(containsPhrase('my nose is blocked', 'no'), isFalse);
      expect(containsPhrase('abpm reading', 'bp'), isFalse);
    });

    test('matches inside a longer sentence', () {
      expect(
        containsPhrase('so when is my next anc visit please', 'next anc'),
        isTrue,
      );
    });
  });

  group('detectRedFlag', () {
    test('catches the danger signs from the warning-signs sheet', () {
      expect(detectRedFlag('I am bleeding')?.id, 'bleeding');
      expect(detectRedFlag('my baby is not moving since morning')?.id,
          'reduced_movement');
      expect(detectRedFlag('I have severe pain in my stomach')?.id,
          'severe_pain');
      expect(detectRedFlag('my vision is blurred and I have a severe headache')
          ?.id, 'preeclampsia');
      expect(detectRedFlag('I think my water broke')?.id, 'fluid_leak');
      expect(detectRedFlag('I cant breathe properly')?.id, 'breathing');
      expect(detectRedFlag('I have a high fever')?.id, 'fever');
    });

    test('does not fire on a question *about* a symptom', () {
      // Escalating these would train mothers to ignore the escalation.
      expect(detectRedFlag('is spotting normal in early pregnancy'), isNull);
      expect(detectRedFlag('what causes bleeding in pregnancy'), isNull);
      expect(detectRedFlag('what are the signs of severe pain'), isNull);
    });

    test('still fires when she says it is happening to her now', () {
      // "I have" outranks the hypothetical framing.
      expect(detectRedFlag('is this normal, I have bleeding right now'),
          isNotNull);
      expect(detectRedFlag('I am having severe pain, is it normal'), isNotNull);
    });

    test('is not confused by ordinary words', () {
      expect(detectRedFlag('what is my blood group'), isNull);
      expect(detectRedFlag('can I eat a banana'), isNull);
      expect(detectRedFlag('mild swelling in my feet'), isNull);
    });
  });

  group('classifyIntent', () {
    test('an emergency outranks every other reading', () {
      final match = classifyIntent('I am bleeding, when is my next anc visit');
      expect(match.intent, AlloBotIntent.emergency);
      expect(match.redFlag, isNotNull);
    });

    test('routes questions about her own data to context intents', () {
      expect(classifyIntent('when is my next anc visit').intent,
          AlloBotIntent.ancSchedule);
      expect(classifyIntent('what is my due date').intent,
          AlloBotIntent.dueDate);
      expect(classifyIntent('how many weeks am I').intent,
          AlloBotIntent.gestationalStatus);
      expect(classifyIntent('how much water have I had').intent,
          AlloBotIntent.waterIntake);
      expect(classifyIntent('what is left on my care today').intent,
          AlloBotIntent.todayCare);
      expect(classifyIntent('is my vaccine due').intent,
          AlloBotIntent.vaccination);
      expect(classifyIntent('which tests are due').intent,
          AlloBotIntent.labReport);
      expect(classifyIntent('what are my test results').intent,
          AlloBotIntent.labReport);
      expect(classifyIntent('is my anomaly scan pending').intent,
          AlloBotIntent.labReport);
      expect(classifyIntent('when should I take my medicines').intent,
          AlloBotIntent.medication);
    });

    test('every context intent is marked as needing context', () {
      expect(classifyIntent('when is my next anc visit').needsContext, isTrue);
      expect(classifyIntent('can I eat mangoes').needsContext, isFalse);
    });

    test('prefers the more specific phrase when two match', () {
      // "kick count" is longer and more specific than "count".
      expect(classifyIntent('let me do a kick count').intent,
          AlloBotIntent.kickCount);
    });

    test('sends anything else to retrieval', () {
      expect(classifyIntent('can I eat mangoes').intent,
          AlloBotIntent.knowledge);
      expect(classifyIntent('why do I feel so tired').intent,
          AlloBotIntent.knowledge);
    });

    group('short conversational turns', () {
      test('a bare yes accepts the follow-up', () {
        expect(classifyIntent('yes').intent, AlloBotIntent.affirmation);
        expect(classifyIntent('yes please').intent, AlloBotIntent.affirmation);
        expect(classifyIntent('tell me more').intent, AlloBotIntent.affirmation);
      });

      test('a bare no declines it', () {
        expect(classifyIntent('no').intent, AlloBotIntent.negation);
        expect(classifyIntent('not now').intent, AlloBotIntent.negation);
      });

      test('a long answer starting with yes is a real question', () {
        // The guard against reading "yes I have swelling in week 24" as a bare
        // acknowledgement and losing the question entirely.
        expect(
          classifyIntent('yes I have mild swelling in my feet at week 24').intent,
          isNot(AlloBotIntent.affirmation),
        );
      });

      test('recognises greetings and thanks', () {
        expect(classifyIntent('hello').intent, AlloBotIntent.greeting);
        expect(classifyIntent('vanakkam').intent, AlloBotIntent.greeting);
        expect(classifyIntent('thank you so much').intent,
            AlloBotIntent.gratitude);
      });
    });

    test('an empty query is not an error', () {
      expect(classifyIntent('   ').intent, AlloBotIntent.knowledge);
    });
  });
}
