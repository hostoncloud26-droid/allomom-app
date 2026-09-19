import 'package:flutter_test/flutter_test.dart';
import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/features/offline_chatbot/engine/offline_matching.dart';
import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';

BotBundle _bundle() => BotBundle.fromJson({
      'version': 1,
      'lang_code': 'en',
      'intents': [
        {
          'key': 'hello_intro',
          'name': 'Hello Intro',
          'examples': ['hi', 'hello', 'how are you'],
          'type': 'flow',
          'lang_code': 'en',
          'flow': {
            'name': 'Hello Intro',
            'completion_message': 'Flow completed successfully.',
            'steps': [
              {'ref': 's1', 'type': 'text', 'question': 'Hi , I am Allobot'},
              {'ref': 's2', 'type': 'delay', 'question': '2'},
              {
                'ref': 's3',
                'type': 'question',
                'question': 'What can i do for you',
                'save_key': 'ask',
                'options': ['Good', 'Not Good'],
              },
            ],
            'connectors': [
              {'ref': 'c1', 'from_ref': 's1', 'to_ref': 's2', 'logic': {}},
              {'ref': 'c2', 'from_ref': 's2', 'to_ref': 's3', 'logic': {}},
            ],
          },
        },
        {
          'key': 'eat',
          'name': 'Can I eat',
          'examples': ['can i eat {food}'],
          'type': 'response',
          'lang_code': 'en',
          'response': {
            'message': 'Yes, {food} is fine — due {profile.due_date}.',
          },
        },
        {
          'key': 'open_health',
          'name': 'Open My Health',
          'examples': ['show my health vitals', 'my vitals'],
          'type': 'flow',
          'lang_code': 'en',
          'flow': {
            'name': 'Open My Health',
            'completion_message': 'Flow completed successfully.',
            'steps': [
              {
                'ref': 's1',
                'type': 'action',
                'question': '',
                'action_name': 'open_my_health',
                'action_data': {'tab': 'vitals'},
              },
              {
                'ref': 's2',
                'type': 'text',
                'question': 'Opening your health vitals, Amma',
              },
            ],
            'connectors': [
              {'ref': 'c1', 'from_ref': null, 'to_ref': 's1', 'logic': {}},
              {'ref': 'c2', 'from_ref': 's1', 'to_ref': 's2', 'logic': {}},
            ],
          },
        },
        {
          'key': 'ask_ai',
          'name': 'FallBack to AI',
          'examples': ['ask ai {question}'],
          'type': 'flow',
          'lang_code': 'en',
          'flow': {
            'name': 'FallBack to AI',
            'completion_message': 'Flow completed successfully.',
            'steps': [
              {
                'ref': 's1',
                'type': 'ai',
                'question': '',
                'save_key': 'ai_message',
                'ai_prompt': 'Question :- {trigger_message}',
                'ai_system': 'Be brief.',
                'ai_model': 'gemini-2.5-flash',
              },
              {'ref': 's2', 'type': 'text', 'question': '{ai_message}'},
            ],
            'connectors': [
              {'ref': 'c1', 'from_ref': 's1', 'to_ref': 's2', 'logic': {}},
            ],
          },
        },
        {
          'key': 'ask_ai_history',
          'name': 'FallBack to AI with history',
          'examples': ['remember {question}'],
          'type': 'flow',
          'lang_code': 'en',
          'flow': {
            'name': 'FallBack to AI with history',
            'completion_message': 'Flow completed successfully.',
            'steps': [
              {
                'ref': 's1',
                'type': 'ai',
                'question': '',
                'save_key': 'ai_message',
                'ai_prompt': 'Question :- {trigger_message}',
                // The flag rides in options; it must not make the step wait.
                'options': ['use_entire_history'],
              },
              {'ref': 's2', 'type': 'text', 'question': '{ai_message}'},
            ],
            'connectors': [
              {'ref': 'c1', 'from_ref': 's1', 'to_ref': 's2', 'logic': {}},
            ],
          },
        },
        {
          'key': 'ask_ai_no_history',
          'name': 'FallBack to AI without history',
          'examples': ['classify {question}'],
          'type': 'flow',
          'lang_code': 'en',
          'flow': {
            'name': 'FallBack to AI without history',
            'completion_message': 'Flow completed successfully.',
            'steps': [
              {
                'ref': 's1',
                'type': 'ai',
                'question': '',
                'save_key': 'ai_message',
                'ai_prompt': 'Question :- {trigger_message}',
                // The opt-out, for a step where an earlier exchange is noise.
                'options': ['no_history'],
              },
              {'ref': 's2', 'type': 'text', 'question': '{ai_message}'},
            ],
            'connectors': [
              {'ref': 'c1', 'from_ref': 's1', 'to_ref': 's2', 'logic': {}},
            ],
          },
        },
        {
          'key': 'fallback',
          'name': 'Fallback',
          'examples': [],
          'type': 'response',
          'lang_code': 'en',
          'is_fallback': true,
          'response': {'message': 'I did not get that.'},
        },
      ],
    });

void main() {
  group('trigger matching', () {
    test('captures a {slot} from a templated trigger', () {
      final match = findBestIntent(_bundle().intents, 'can i eat mango');
      expect(match, isNotNull);
      expect(match!.intent.key, 'eat');
      expect(match.variables['food'], 'mango');
    });

    test('an exact literal beats a substring hit', () {
      final match = findBestIntent(_bundle().intents, 'hi');
      expect(match!.intent.key, 'hello_intro');
    });

    test('a trigger matches inside a longer sentence', () {
      final match = findBestIntent(_bundle().intents, 'hey, hello there');
      expect(match!.intent.key, 'hello_intro');
    });

    test('a trigger is not found buried inside a word', () {
      // "hi" must not fire on "thing" — containment is measured in whole words.
      final match = findBestIntent(
        [const BotIntent(key: 'k', name: 'k', examples: ['hi'])],
        'that thing over there',
      );
      expect(match, isNull);
    });

    test('nothing matches an unrelated message', () {
      expect(findBestIntent(_bundle().intents, 'zzzz qqqq'), isNull);
    });
  });

  group('option matching', () {
    const options = ['Good', 'Not Good'];

    test('an exact tap wins', () => expect(matchOption(options, 'Good'), 'Good'));

    test('a spoken sentence resolves to the longest contained option', () {
      expect(matchOption(options, 'i am not good'), 'Not Good');
    });

    test('a positional pick works', () {
      expect(matchOption(options, '2'), 'Not Good');
      expect(matchOption(options, 'the second one'), 'Not Good');
    });

    test('a transcription slip still lands', () {
      expect(matchOption(options, 'nat good'), 'Not Good');
    });

    test('an unrelated utterance matches nothing', () {
      expect(matchOption(options, 'book an appointment'), isNull);
    });
  });

  group('templating', () {
    test('renders single and double brace forms, and dotted paths', () {
      final data = {
        'food': 'mango',
        'profile': {'due_date': '2026-11-02'},
      };
      expect(renderTemplate('Yes, {food} on {{profile.due_date}}', data),
          'Yes, mango on 2026-11-02');
    });

    test('leaves unknown keys and JSON braces untouched', () {
      expect(renderTemplate('{"mode": "dark"} {unknown}', {'food': 'x'}),
          '{"mode": "dark"} {unknown}');
    });
  });

  group('flow traversal', () {
    test('a delay splits the turn into two segments', () async {
      final engine = OfflineChatbotEngine(bundle: _bundle(), langCode: 'en');
      final reply = await engine.respond(message: 'hi', session: BotSession());

      expect(reply.segments.length, 2);
      expect(reply.segments[0].text, 'Hi , I am Allobot');
      expect(reply.segments[0].delay, 0);
      expect(reply.segments[1].text, 'What can i do for you');
      expect(reply.segments[1].delay, 2);
      expect(reply.segments[1].options, ['Good', 'Not Good']);
    });

    test('answering an option advances and ends the flow', () async {
      final engine = OfflineChatbotEngine(bundle: _bundle(), langCode: 'en');
      final session = BotSession();
      await engine.respond(message: 'hi', session: session);
      expect(session.isActive, isTrue);

      // The seeded completion placeholder is never shown.
      final reply = await engine.respond(message: 'i am not good', session: session);
      expect(reply.text, isEmpty);
      expect(session.isActive, isFalse);
      expect(session.data['ask'], isNull, reason: 'session cleared on completion');
    });

    test('an unrecognised answer re-asks instead of storing it', () async {
      final engine = OfflineChatbotEngine(bundle: _bundle(), langCode: 'en');
      final session = BotSession();
      await engine.respond(message: 'hi', session: session);

      final reply = await engine.respond(message: 'purple monkey', session: session);
      expect(reply.text, contains(optionMismatchMessage));
      expect(reply.options, ['Good', 'Not Good']);
      expect(session.isActive, isTrue);
    });

    test('a response intent interpolates trigger vars and the profile', () async {
      final engine = OfflineChatbotEngine(bundle: _bundle(), langCode: 'en');
      final reply = await engine.respond(
        message: 'can i eat mango',
        session: BotSession(),
        profile: {'due_date': '2026-11-02'},
      );
      expect(reply.text, 'Yes, mango is fine — due 2026-11-02.');
    });

    test('an unmatched message falls back', () async {
      final engine = OfflineChatbotEngine(bundle: _bundle(), langCode: 'en');
      final reply = await engine.respond(message: 'zzzz qqqq', session: BotSession());
      expect(reply.text, 'I did not get that.');
    });

    test('an action runs before the text announcing it', () async {
      final engine = OfflineChatbotEngine(bundle: _bundle(), langCode: 'en');
      final reply = await engine.respond(message: 'my vitals', session: BotSession());

      expect(reply.segments.length, 1);
      final segment = reply.segments.single;
      expect(segment.actions.single['name'], 'open_my_health');
      expect(segment.actions.single['data'], {'tab': 'vitals'});
      expect(segment.text, 'Opening your health vitals, Amma');
    });
  });


  group('ai step', () {
    test('runs inference and feeds the answer to the next step', () async {
      late AiStepRequest seen;
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (request) async {
          seen = request;
          return 'Ice cream is fine in moderation.';
        },
      );

      final reply =
          await engine.respond(message: 'ask ai i want ice cream', session: BotSession());

      // The prompt reached the resolver already rendered.
      expect(seen.prompt, 'Question :- ask ai i want ice cream');
      expect(seen.system, 'Be brief.');
      expect(seen.model, 'gemini-2.5-flash');

      // …and its answer is what {ai_message} renders as.
      expect(reply.text, 'Ice cream is fine in moderation.');
    });


    test('the history flag reaches the resolver', () async {
      late AiStepRequest seen;
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (request) async {
          seen = request;
          return 'Sure.';
        },
      );

      await engine.respond(
          message: 'remember what i said', session: BotSession());
      expect(seen.useEntireHistory, isTrue);
    });

    test('the catalogue language reaches the resolver', () async {
      late AiStepRequest seen;
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'ta',
        aiResolver: (request) async {
          seen = request;
          return 'Sure.';
        },
      );

      // An authored prompt is written once in English and shared by every
      // language's catalogue, so the step has to carry the language itself.
      await engine.respond(message: 'ask ai anything', session: BotSession());
      expect(seen.langCode, 'ta');
    });

    test('the profile reaches the resolver, unasked', () async {
      late AiStepRequest seen;
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (request) async {
          seen = request;
          return 'Sure.';
        },
      );

      await engine.respond(
        message: 'ask ai how am i doing',
        session: BotSession(),
        profile: {
          'user': {'name': 'Asha'},
          'vitals': {'steps': 4200},
        },
      );

      // No flag, no placeholder in the authored prompt — the facts travel with
      // every ai step so a plain question still gets a personal answer.
      expect(seen.profile['user'], {'name': 'Asha'});
      expect(seen.profile['vitals'], {'steps': 4200});
    });

    test('a step with no profile to send gets an empty one', () async {
      late AiStepRequest seen;
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (request) async {
          seen = request;
          return 'Sure.';
        },
      );

      await engine.respond(message: 'ask ai anything', session: BotSession());
      expect(seen.profile, isEmpty);
    });

    test('a step with no flag at all still asks for history', () async {
      late AiStepRequest seen;
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (request) async {
          seen = request;
          return 'Sure.';
        },
      );

      // Context is the default: "I ate it, what do I do?" is unanswerable
      // without the line before it, and most authored steps never said so.
      await engine.respond(message: 'ask ai anything', session: BotSession());
      expect(seen.useEntireHistory, isTrue);
    });

    test('a step that opted out does not ask for history', () async {
      late AiStepRequest seen;
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (request) async {
          seen = request;
          return 'Sure.';
        },
      );

      await engine.respond(
          message: 'classify this line', session: BotSession());
      expect(seen.useEntireHistory, isFalse);
    });

    test('the opt-out in options never makes the step wait for a selection',
        () async {
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (_) async => 'Answered.',
      );

      final reply = await engine.respond(
          message: 'classify this line', session: BotSession());
      expect(reply.text, 'Answered.');
      expect(reply.options, isEmpty);
    });

    test('the flag in options never makes the step wait for a selection',
        () async {
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (_) async => 'Answered.',
      );

      // It must run straight through to the text step, not stop offering
      // "use_entire_history" as a quick reply.
      final reply = await engine.respond(
          message: 'remember what i said', session: BotSession());
      expect(reply.text, 'Answered.');
      expect(reply.options, isEmpty);
    });

    test('says so when the model cannot be reached', () async {
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (_) async => null,
      );

      final reply =
          await engine.respond(message: 'ask ai anything', session: BotSession());
      expect(reply.text, aiUnavailableMessage);
    });

    test('a thrown resolver does not derail the turn', () async {
      final engine = OfflineChatbotEngine(
        bundle: _bundle(),
        langCode: 'en',
        aiResolver: (_) async => throw Exception('offline'),
      );

      final reply =
          await engine.respond(message: 'ask ai anything', session: BotSession());
      expect(reply.text, aiUnavailableMessage);
    });

    test('with no resolver at all it still answers rather than printing JSON',
        () async {
      final engine = OfflineChatbotEngine(bundle: _bundle(), langCode: 'en');
      final reply =
          await engine.respond(message: 'ask ai anything', session: BotSession());
      expect(reply.text, aiUnavailableMessage);
      expect(reply.text, isNot(contains('status_code')));
    });
  });
  group('delay duration', () {
    test('parses, templates and clamps', () {
      expect(delaySeconds(const BotStep(ref: 's', question: '2'), null), 2);
      expect(
          delaySeconds(const BotStep(ref: 's', question: '{wait}'),
              {'wait': '3'}),
          3);
      expect(delaySeconds(const BotStep(ref: 's', question: 'abc'), null), 0);
      expect(delaySeconds(const BotStep(ref: 's', question: '-5'), null), 0);
      expect(delaySeconds(const BotStep(ref: 's', question: '9999'), null),
          maxDelaySeconds);
    });
  });
}
