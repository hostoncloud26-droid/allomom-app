/// What an `intent` step does when it hands the conversation to another intent.
///
/// The Flow Builder calls it "Intent Redirect (Change Intent)", and a flow
/// authored with one used to stop at the redirect and say nothing further: a
/// step's ref is only unique inside its own flow, so the target flow's `s1`
/// looked like a step the traversal had already walked.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';

/// What the turn reads out, one step at a time.
///
/// Steps with no delay between them share a bubble, so the segment's text is
/// not the unit here — the utterance is, and it is also what the app waits on
/// between steps.
List<String> spokenLines(BotReply reply) => [
      for (final segment in reply.segments)
        for (final utterance in segment.utterances)
          if (utterance.text.isNotEmpty) utterance.text,
    ];

void main() {
  BotFlow greeting({String completion = ''}) => BotFlow(
        name: 'Start of Chat Bot',
        completionMessage: completion,
        steps: const [
          BotStep(ref: 's1', type: 'text', question: 'Hi, Mom'),
          BotStep(
            ref: 's3',
            type: 'intent',
            nextIntentKey: 'check_breakfast',
            nextIntentLang: 'en',
          ),
        ],
        connectors: const [
          BotConnector(ref: 'c1', fromRef: 's1', toRef: 's3'),
        ],
      );

  /// The target flow numbers its own steps from s1, exactly as every flow does.
  BotIntent breakfast({List<BotStep>? steps, String completion = ''}) =>
      BotIntent(
        key: 'check_breakfast',
        name: 'Check Breakfast',
        type: 'flow',
        flow: BotFlow(
          name: 'Check Breakfast',
          completionMessage: completion,
          steps: steps ??
              const [
                BotStep(ref: 's1', type: 'text', question: 'Did you eat yet?'),
              ],
        ),
      );

  OfflineChatbotEngine engineFor(List<BotIntent> intents) =>
      OfflineChatbotEngine(
        bundle: BotBundle(langCode: 'en', intents: intents),
        langCode: 'en',
      );

  test('an intent step runs the flow it points at', () async {
    final start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: greeting(),
    );
    final session = BotSession();

    final reply = await engineFor([start, breakfast()])
        .runIntent(start, session: session);

    expect(
      spokenLines(reply),
      ['Hi, Mom', 'Did you eat yet?'],
    );
  });

  test('the redirected flow, not the one that redirected, is left waiting',
      () async {
    final start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: greeting(),
    );
    final target = breakfast(steps: const [
      BotStep(ref: 's1', type: 'text', question: 'Did you eat yet?'),
      BotStep(
        ref: 's2',
        type: 'question',
        question: 'What did you have?',
        saveKey: 'meal',
      ),
    ]);
    // s1 -> s2 inside the target flow.
    final wired = BotIntent(
      key: target.key,
      name: target.name,
      type: 'flow',
      flow: BotFlow(
        name: target.flow!.name,
        steps: target.flow!.steps,
        connectors: const [BotConnector(ref: 'c1', fromRef: 's1', toRef: 's2')],
      ),
    );

    final session = BotSession();
    final reply =
        await engineFor([start, wired]).runIntent(start, session: session);

    expect(
      spokenLines(reply),
      ['Hi, Mom', 'Did you eat yet?', 'What did you have?'],
    );
    expect(session.intentKey, 'check_breakfast');
    expect(session.currentStepRef, 's2');
  });

  test('a redirect to a response intent answers with it and ends', () async {
    final start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: greeting(completion: 'Bye from the greeting.'),
    );
    const target = BotIntent(
      key: 'check_breakfast',
      name: 'Check Breakfast',
      type: 'response',
      response: BotResponse(message: 'Hope you had a good breakfast!'),
    );

    final session = BotSession();
    final reply =
        await engineFor([start, target]).runIntent(start, session: session);

    expect(
      spokenLines(reply),
      ['Hi, Mom', 'Hope you had a good breakfast!'],
    );
    // The flow that was left behind does not get to say its closing line over
    // the answer the redirect produced.
    expect(reply.text, isNot(contains('Bye from the greeting.')));
  });

  test('the closing line comes from the flow that actually ran out', () async {
    final start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: greeting(completion: 'Bye from the greeting.'),
    );

    final session = BotSession();
    final reply = await engineFor([
      start,
      breakfast(completion: 'Bye from breakfast.'),
    ]).runIntent(start, session: session);

    expect(reply.text, contains('Bye from breakfast.'));
    expect(reply.text, isNot(contains('Bye from the greeting.')));
  });

  test('a question step before the redirect waits, and the redirect does not run',
      () async {
    // Not a bug — the trap that looked like one. A Question step asks and
    // waits for a reply, so nothing downstream of it runs this turn; only a
    // Text Message step hands straight over. Both are drawn the same way on
    // the canvas, and a question whose answer is text used to wear a badge
    // reading "TEXT" — see the Flow Builder's node badge.
    final start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: const BotFlow(
        name: 'Start of Chat Bot',
        steps: [
          BotStep(ref: 's1', type: 'question', question: 'Hi, Mom'),
          BotStep(
            ref: 's3',
            type: 'intent',
            nextIntentKey: 'check_breakfast',
            nextIntentLang: 'en',
          ),
        ],
        connectors: [BotConnector(ref: 'c1', fromRef: 's1', toRef: 's3')],
      ),
    );

    final session = BotSession();
    final reply =
        await engineFor([start, breakfast()]).runIntent(start, session: session);

    expect(spokenLines(reply), ['Hi, Mom']);
    expect(session.currentStepRef, 's1');
    expect(session.intentKey, 'initial');
  });

  test('the redirect follows the id the Builder stored, not the key', () async {
    // A key is unique only within one language, so a catalogue carrying the
    // same flow in two languages has two intents answering to
    // `check_breakfast`. The id says which one the arrow was drawn to.
    const start = BotIntent(
      id: 'intent-initial-en',
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: BotFlow(
        name: 'Start of Chat Bot',
        steps: [
          BotStep(ref: 's1', type: 'text', question: 'Hi, Mom'),
          BotStep(
            ref: 's2',
            type: 'intent',
            nextIntentId: 'intent-breakfast-ta',
            // The ref points at the English copy; the id does not.
            nextIntentKey: 'check_breakfast',
            nextIntentLang: 'en',
          ),
        ],
        connectors: [BotConnector(ref: 'c1', fromRef: 's1', toRef: 's2')],
      ),
    );
    const english = BotIntent(
      id: 'intent-breakfast-en',
      key: 'check_breakfast',
      name: 'Check Breakfast',
      type: 'response',
      response: BotResponse(message: 'Did you eat yet?'),
    );
    const tamil = BotIntent(
      id: 'intent-breakfast-ta',
      key: 'check_breakfast',
      name: 'Check Breakfast',
      type: 'response',
      langCode: 'ta',
      response: BotResponse(message: 'காலை உணவு சாப்பிட்டீர்களா?'),
    );

    final session = BotSession();
    final reply = await engineFor([start, english, tamil])
        .runIntent(start, session: session);

    expect(spokenLines(reply), ['Hi, Mom', 'காலை உணவு சாப்பிட்டீர்களா?']);
  });

  test('a redirect with no id still resolves by key', () async {
    // A bundle exported before ids travelled, or one imported into another
    // database where the ids belong to someone else's rows.
    final start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: greeting(),
    );

    final session = BotSession();
    final reply = await engineFor([start, breakfast()])
        .runIntent(start, session: session);

    expect(spokenLines(reply), ['Hi, Mom', 'Did you eat yet?']);
  });

  test('a redirect whose target is missing ends the flow quietly', () async {
    const start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: BotFlow(
        name: 'Start of Chat Bot',
        steps: [
          BotStep(ref: 's1', type: 'text', question: 'Hi, Mom'),
          BotStep(
            ref: 's2',
            type: 'intent',
            nextIntentId: 'intent-that-was-deleted',
            nextIntentKey: 'gone',
            nextIntentLang: 'en',
          ),
        ],
        connectors: [BotConnector(ref: 'c1', fromRef: 's1', toRef: 's2')],
      ),
    );

    final session = BotSession();
    final reply = await engineFor([start]).runIntent(start, session: session);

    expect(spokenLines(reply), ['Hi, Mom']);
    expect(session.isActive, isFalse);
  });

  test('a short answer does not divert the flow before the redirect', () async {
    // What this looked like in the app: the mother answers the greeting with
    // "good", that one word is found inside an unrelated trigger phrase, and
    // she gets a lecture on fruit instead of the flow the greeting redirects
    // to. Only a trigger she actually said may interrupt a waiting step.
    const start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: BotFlow(
        name: 'Start of Chat Bot',
        steps: [
          BotStep(
            ref: 's1',
            type: 'question',
            question: 'Hi, Mom, hope you are having a fantastic day',
            saveKey: 'step_caeq',
          ),
          BotStep(
            ref: 's2',
            type: 'intent',
            nextIntentKey: 'check_breakfast',
            nextIntentLang: 'en',
          ),
        ],
        connectors: [BotConnector(ref: 'c1', fromRef: 's1', toRef: 's2')],
      ),
    );
    const fruits = BotIntent(
      key: 'fruits',
      name: 'Fruits',
      type: 'response',
      examples: ['Which fruits are good to eat during pregnancy?'],
      response: BotResponse(message: 'Apples, bananas, oranges...'),
    );

    // The redirected flow reads the answer the greeting saved, so this also
    // pins down that the handover carries the session's data across.
    final target = breakfast(steps: const [
      BotStep(
        ref: 's1',
        type: 'text',
        question: 'You said {step_caeq}. Did you eat yet?',
      ),
    ]);

    final engine = engineFor([start, fruits, target]);
    final session = BotSession();
    await engine.runIntent(start, session: session);
    final reply = await engine.respond(message: 'good', session: session);

    expect(spokenLines(reply), ['You said good. Did you eat yet?']);
  });

  test('a real question still interrupts the step waiting on an answer',
      () async {
    const start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: BotFlow(
        name: 'Start of Chat Bot',
        steps: [
          BotStep(ref: 's1', type: 'question', question: 'How are you?'),
        ],
      ),
    );
    const fruits = BotIntent(
      key: 'fruits',
      name: 'Fruits',
      type: 'response',
      examples: ['Which fruits are good to eat during pregnancy?'],
      response: BotResponse(message: 'Apples, bananas, oranges...'),
    );

    final engine = engineFor([start, fruits]);
    final session = BotSession();
    await engine.runIntent(start, session: session);
    final reply = await engine.respond(
        message: 'Which fruits are good to eat during pregnancy?',
        session: session);

    expect(spokenLines(reply), ['Apples, bananas, oranges...']);
  });

  test('a flow that redirects back into itself still stops', () async {
    final loop = BotIntent(
      key: 'initial',
      name: 'Loop',
      type: 'flow',
      flow: const BotFlow(
        name: 'Loop',
        steps: [
          BotStep(ref: 's1', type: 'text', question: 'Round and round'),
          BotStep(
            ref: 's2',
            type: 'intent',
            nextIntentKey: 'initial',
            nextIntentLang: 'en',
          ),
        ],
        connectors: [BotConnector(ref: 'c1', fromRef: 's1', toRef: 's2')],
      ),
    );

    final session = BotSession();
    final reply = await engineFor([loop]).runIntent(loop, session: session);

    // Said once, not twice, and the flow is over rather than waiting on a step
    // that takes no answer.
    expect(spokenLines(reply), ['Round and round']);
    expect(session.isActive, isFalse);
  });

  test('a profile condition after an answer still reads the nested profile',
      () async {
    // "How are you?" -> any answer -> redirect into a flow that branches on
    // `profile.today_nutrition.had_breakfast`, as check_breakfast_test does.
    final start = BotIntent(
      key: 'initial',
      name: 'Start of Chat Bot',
      type: 'flow',
      flow: BotFlow(
        name: 'Start of Chat Bot',
        steps: const [
          BotStep(
            ref: 's1',
            type: 'question',
            question: 'How are you doing Mom?',
            options: ['Good', 'Bad'],
          ),
          BotStep(
            ref: 's2',
            type: 'intent',
            nextIntentKey: 'check_breakfast',
            nextIntentLang: 'en',
          ),
        ],
        connectors: const [BotConnector(ref: 'c1', fromRef: 's1', toRef: 's2')],
      ),
    );

    Map<String, dynamic> clause(String op) => {
          'match': 'all',
          'conditions': [
            {
              'variable': 'profile.today_nutrition.had_breakfast',
              'operator': op,
              'value': '',
            },
          ],
        };
    final check = BotIntent(
      key: 'check_breakfast',
      name: 'Check Breakfast',
      type: 'flow',
      flow: BotFlow(
        name: 'Check Breakfast',
        steps: const [
          BotStep(ref: 's1', type: 'text', question: 'Good Mom'),
          BotStep(ref: 's2', type: 'text', question: 'Why havent you eaten?'),
        ],
        connectors: [
          BotConnector(ref: 'c1', toRef: 's1', logic: clause('is_true')),
          BotConnector(ref: 'c2', toRef: 's2', logic: clause('is_false')),
        ],
      ),
    );

    // The profile carries its own `profile` key, the person block.
    final profile = <String, dynamic>{
      'profile': {'name': 'Deeksha'},
      'today_nutrition': {'had_breakfast': true},
    };
    final engine = engineFor([start, check]);
    final session = BotSession();
    await engine.runIntent(start, session: session, profile: profile);
    final reply = await engine.respond(
      message: 'Good',
      session: session,
      profile: profile,
    );

    expect(spokenLines(reply), contains('Good Mom'));
    expect(spokenLines(reply), isNot(contains('Why havent you eaten?')));
  });
}
