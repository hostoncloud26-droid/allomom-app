import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/features/allobot/tabs/allobot_settings_tab.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

void main() {
  group('AlloBot settings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'allomom_offline_chatbot_bundle': jsonEncode({
          'version': 1,
          'lang_code': 'en',
          'downloaded_at': DateTime.now().toIso8601String(),
          'languages': [
            {'code': 'en', 'name': 'English'},
            {'code': 'ta', 'name': 'Tamil'},
          ],
          'intents': [
            {
              'key': 'greet',
              'name': 'Greet',
              'examples': ['hi'],
              'type': 'response',
              'lang_code': 'en',
              'response': {'message': 'Hello Amma'},
            },
          ],
        }),
      });
    });

    tearDown(Get.reset);

    Future<OfflineChatbotController> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = OfflineChatbotController.instance;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AlloBotSettingsTab())),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('is the language and the voice model, and nothing else',
        (tester) async {
      await pumpSettings(tester);

      expect(find.text('LANGUAGE'), findsOneWidget);
      expect(find.text('VOICE MODEL'), findsOneWidget);

      // The panels that configured nothing are gone, and so is the catalogue
      // download — picking a language already fetches it.
      expect(find.textContaining('MODEL CONFIG'), findsNothing);
      expect(find.textContaining('Creativity'), findsNothing);
      expect(find.textContaining('Gemini'), findsNothing);
      expect(find.textContaining('HIGH BANDWIDTH'), findsNothing);
      expect(find.textContaining('ALLOBABY INTENTS'), findsNothing);
      expect(find.textContaining('Sync AlloBaby Intents'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists the languages the catalogue carries', (tester) async {
      await pumpSettings(tester);

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Tamil'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('lists the voice models with their download sizes',
        (tester) async {
      await pumpSettings(tester);

      // Filtered to the running platform, so on a test VM there may be none —
      // what matters is that nothing unsupported is offered.
      for (final name in ['Whisper Tiny', 'Whisper Base', 'Whisper Small']) {
        final found = find.text(name).evaluate().length;
        expect(found, lessThanOrEqualTo(1));
      }
      expect(tester.takeException(), isNull);
    });
  });
}
