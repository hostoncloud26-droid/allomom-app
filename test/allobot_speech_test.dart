import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/features/allobot/widgets/allobot_mic_button.dart';
import 'package:allomom/features/offline_chatbot/speech/allobot_speech_controller.dart';

void main() {
  group('AlloBotSpeechController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    tearDown(Get.reset);

    test('offers the three Whisper sizes, each with what it costs to fetch', () {
      final controller = AlloBotSpeechController.instance;
      expect(
        controller.models.map((m) => m.id),
        ['whisper-tiny', 'whisper-base', 'whisper-small'],
      );
      for (final model in controller.models) {
        expect(model.downloadSize, isNotEmpty);
        expect(model.intelligence, isNotEmpty);
      }
    });

    test('a model is offered only where it runs', () {
      // The list is filtered on the running platform, so the picker never shows
      // a download that cannot work. Tests run on neither phone OS, so this
      // asserts the filter rather than its result here.
      final controller = AlloBotSpeechController.instance;
      expect(
        controller.supportedModels,
        controller.models.where((m) => m.isSupported).toList(),
      );

      const desktopOnly = AlloBotSpeechModelOption(
        id: 'whisper-nope',
        name: 'Unsupported',
        intelligence: 'n/a',
        downloadSize: '0 MB',
        platform: ['windows'],
      );
      expect(desktopOnly.isSupported, isFalse);
    });

    test('starts on the smallest model, so a first run is not a 480MB bill',
        () async {
      final controller = AlloBotSpeechController.instance;
      // onInit restores state asynchronously.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        controller.activeModelId.value,
        AlloBotSpeechController.defaultModelId,
      );
      expect(controller.models.first.id, 'whisper-tiny');
    });

    test('cannot listen until a model is actually on the phone', () async {
      final controller = AlloBotSpeechController.instance;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Nothing downloaded in a test binding.
      expect(controller.hasDownloadedActiveModel, isFalse);
      expect(controller.canListen, isFalse);

      // Nor while one is on its way.
      controller.localPath.value = '/tmp/pretend-model.bin';
      expect(controller.canListen, isTrue);
      controller.isDownloading.value = true;
      expect(controller.canListen, isFalse);
    });

    test('a path that no longer resolves is forgotten, not trusted', () async {
      SharedPreferences.setMockInitialValues({
        'allomom_speech_active_model_id': 'whisper-tiny',
        'allomom_speech_local_path': '/nowhere/ggml-tiny.bin',
      });
      final controller = AlloBotSpeechController.instance;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.localPath.value, isEmpty);
      expect(controller.canListen, isFalse);
    });
  });

  group('the docked mic', () {
    Widget wrap({
      required bool enabled,
      double? progress,
      VoidCallback? onTap,
    }) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: AlloBotMicButton(
            isListening: false,
            enabled: enabled,
            progress: progress,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );

    testWidgets('is greyed out and inert while the voice model downloads',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(enabled: false, progress: 0.4, onTap: () => taps++),
      );
      await tester.pump();

      expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsNothing);

      await tester.tap(find.byType(AlloBotMicButton));
      expect(taps, 0, reason: 'a mic that cannot listen must not accept taps');
    });

    testWidgets('shows how far the download has got', (tester) async {
      await tester.pumpWidget(wrap(enabled: false, progress: 0.4));
      await tester.pump();

      final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(ring.value, 0.4);
    });

    testWidgets('takes taps again once the model is here', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(enabled: true, onTap: () => taps++));
      await tester.pump();

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(AlloBotMicButton));
      expect(taps, 1);
    });
  });
}
