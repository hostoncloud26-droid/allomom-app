import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/allobot/tabs/allobot_ask_ai_tab.dart';
import 'package:allomom/features/allobot/widgets/allobot_mic_button.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/widgets/allobot_voice_popup.dart';
import 'package:allomom/features/offline_chatbot/widgets/offline_chat_widgets.dart';

void main() {
  group('AlloBotMicButton', () {
    Widget wrap({required bool isListening, VoidCallback? onTap, double size = 64}) =>
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AlloBotMicButton(
                isListening: isListening,
                onTap: onTap ?? () {},
                size: size,
              ),
            ),
          ),
        );

    /// Winds the pulse down and settles.
    ///
    /// A repeating controller is still ticking when the test ends, which
    /// `testWidgets` fails on, so every test that leaves it listening has to
    /// stop it — the same path the real screen takes when speech recognition
    /// finishes.
    Future<void> stopListening(WidgetTester tester) async {
      await tester.pumpWidget(wrap(isListening: false));
      await tester.pumpAndSettle();
    }

    testWidgets('shows a mic at rest and a pause while listening',
        (tester) async {
      await tester.pumpWidget(wrap(isListening: false));
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);

      await tester.pumpWidget(wrap(isListening: true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await stopListening(tester);
    });

    testWidgets('animates only while listening', (tester) async {
      await tester.pumpWidget(wrap(isListening: false));
      // Settles to a stop: a controller left repeating with nothing to show
      // would keep the whole app rebuilding every frame.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(wrap(isListening: true));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isTrue);

      await stopListening(tester);
    });

    testWidgets('takes only the button-sized slot despite the wider rings',
        (tester) async {
      // It sits in a Scaffold's docked FAB slot: reporting the ring extent as
      // its size would widen the notch and shove the nav labels around.
      await tester.pumpWidget(wrap(isListening: true, size: 64));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(find.byType(AlloBotMicButton)), const Size(64, 64));

      await stopListening(tester);
    });

    testWidgets('taps on the button fire, taps outside it do not',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(isListening: true, onTap: () => taps++, size: 64),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.pause_rounded));
      expect(taps, 1);

      // Well inside the ring area but outside the 64px button — this must fall
      // through to whatever is behind rather than count as a mic tap.
      final centre = tester.getCenter(find.byType(AlloBotMicButton));
      await tester.tapAt(centre + const Offset(52, 0));
      expect(taps, 1);

      await stopListening(tester);
    });

    testWidgets('stops animating when listening ends', (tester) async {
      await tester.pumpWidget(wrap(isListening: true));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.binding.hasScheduledFrame, isTrue);

      // pumpAndSettle would time out here if the pulse kept repeating.
      await stopListening(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('Ask Allo lays out without overflowing', () {
    setUp(() {
      // The controller reads its cached catalogue and transcript from prefs on
      // start; with none, it falls through to a download that fails offline,
      // which is exactly the state a first run is in.
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(Get.reset);

    /// Pumps the Ask Allo tab at a given logical screen size.
    Future<GlobalKey<AlloBotAskAiTabState>> pumpTab(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = GlobalKey<AlloBotAskAiTabState>();
      await tester.pumpWidget(
        MaterialApp(home: AlloBotAskAiTab(key: key, onOpenChat: () {})),
      );
      await tester.pump();
      return key;
    }

    testWidgets('fits a tall screen', (tester) async {
      await pumpTab(tester, const Size(412, 915));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits the shortest screen', (tester) async {
      await pumpTab(tester, const Size(320, 568));
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens on the voice view, with the baby and a reply card',
        (tester) async {
      await pumpTab(tester, const Size(412, 915));

      // The baby stands in for AlloKonnect's round bot avatar.
      expect(find.byType(BabyHeroBanner), findsOneWidget);
      // The transcript is the other view, reached from the app bar.
      expect(find.byType(OfflineChatMessageBubble), findsNothing);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
    });

    testWidgets('the transcript view shows the status bar and composer',
        (tester) async {
      await pumpTab(tester, const Size(412, 915));

      await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
      await tester.pump();

      expect(find.byType(OfflineChatbotStatusBar), findsOneWidget);
      expect(find.byType(OfflineChatbotComposer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard mode swaps in the composer, voice mode leaves room',
        (tester) async {
      // AlloKonnect's conditional: the composer is on screen only in keyboard
      // mode, because voice lives in the popup over the docked mic.
      final key = await pumpTab(tester, const Size(412, 915));
      expect(find.byType(OfflineChatbotComposer), findsNothing);

      key.currentState!.controller.isKeyboardMode.value = true;
      await tester.pump();
      expect(find.byType(OfflineChatbotComposer), findsOneWidget);

      key.currentState!.controller.isKeyboardMode.value = false;
      await tester.pump();
      expect(find.byType(OfflineChatbotComposer), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a suggestion chip sends its prompt', (tester) async {
      final key = await pumpTab(tester, const Size(412, 915));
      final controller = key.currentState!.controller;
      final before = controller.messages.length;

      // With nothing downloaded there is no catalogue to answer from, so the
      // turn ends in a system note — what matters here is that the tap reaches
      // the controller at all.
      final chip = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.tap(chip);
      // The turn starts behind an await, so one frame is not enough to see it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.messages.length, greaterThan(before));
      expect(tester.takeException(), isNull);
    });
  });

  group('AlloBotVoicePopup', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    tearDown(Get.reset);

    /// Opens the popup over a bare page, without starting the recogniser —
    /// there is no speech engine under a widget test.
    Future<OfflineChatbotController> pumpPopup(WidgetTester tester) async {
      final controller = OfflineChatbotController.instance;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlloBotVoicePopup.show(
                  context,
                  controller: controller,
                  autoStartListening: false,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('carries the three controls of the capsule', (tester) async {
      await pumpPopup(tester);

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_alt_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the `+` becomes a stop while a turn is running',
        (tester) async {
      final controller = await pumpPopup(tester);

      controller.isTyping.value = true;
      await tester.pump();

      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNothing);

      controller.isTyping.value = false;
      await tester.pump();
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('the keyboard control closes it and asks for the composer',
        (tester) async {
      final controller = await pumpPopup(tester);
      expect(controller.isKeyboardMode.value, isFalse);

      await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
      await tester.pumpAndSettle();

      expect(controller.isKeyboardMode.value, isTrue);
      expect(find.byType(AlloBotVoicePopup), findsNothing);
    });

    testWidgets('the drag pill closes it without sending', (tester) async {
      final controller = await pumpPopup(tester);
      final before = controller.messages.length;

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AlloBotVoicePopup), findsNothing);
      expect(controller.messages.length, before);
      expect(controller.isKeyboardMode.value, isFalse);
    });
  });
}
