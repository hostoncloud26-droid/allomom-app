import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';

void main() {
  test('OfflineChatbotEngine.runIntent executes intent flow and populates options and question', () async {
    final step1 = BotStep(
      ref: 'step_1',
      type: 'question',
      question: 'Which language would you prefer?',
      options: ['English', 'Tamil', 'Hindi'],
    );
    final flow = BotFlow(
      name: 'Initial Flow',
      steps: [step1],
    );
    final initialIntent = BotIntent(
      key: 'inital',
      name: 'Initial Welcome',
      langCode: 'en',
      type: 'flow',
      flow: flow,
    );

    final bundle = BotBundle(
      langCode: 'en',
      intents: [initialIntent],
    );

    final engine = OfflineChatbotEngine(
      bundle: bundle,
      langCode: 'en',
    );

    final session = BotSession();
    final reply = await engine.runIntent(
      initialIntent,
      session: session,
    );

    expect(reply.text, contains('Which language would you prefer?'));
    expect(reply.options, containsAll(['English', 'Tamil', 'Hindi']));
    expect(session.isActive, isTrue);
    expect(session.currentStepRef, 'step_1');
    expect(session.intentKey, 'inital');
  });

  test('OfflineChatbotEngine.runIntent executes simple response intent', () async {
    final welcomeIntent = BotIntent(
      key: 'inital',
      name: 'Welcome',
      langCode: 'en',
      type: 'response',
      response: const BotResponse(message: 'Welcome to AlloBaby!'),
    );

    final bundle = BotBundle(
      langCode: 'en',
      intents: [welcomeIntent],
    );

    final engine = OfflineChatbotEngine(
      bundle: bundle,
      langCode: 'en',
    );

    final session = BotSession();
    final reply = await engine.runIntent(
      welcomeIntent,
      session: session,
    );

    expect(reply.text, 'Welcome to AlloBaby!');
    expect(session.isActive, isFalse);
  });
}
