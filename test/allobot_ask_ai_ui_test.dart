import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/allobot/allobot_feature_previews.dart';
import 'package:allomom/features/allobot/tabs/allobot_ask_ai_tab.dart';
import 'package:allomom/features/allobot/widgets/allobot_mic_button.dart';

void main() {
  group('feature previews', () {
    test('every feature the assistant can open has a preview', () {
      // The featureType strings the voice assistant routes on. Adding a
      // feature there without a preview here would show a bare button.
      const routedTypes = [
        'kick', 'cry', 'report', 'health', 'prescription', 'anc',
        'vaccine', 'journey', 'family', 'settings', 'feed',
      ];
      for (final type in routedTypes) {
        final preview = featurePreviewFor(type);
        expect(preview, isNotNull, reason: 'no preview for "$type"');
        expect(preview!.name, isNotEmpty);
        expect(preview.description, isNotEmpty);
        expect(preview.uses, isNotEmpty, reason: '"$type" lists no uses');
      }
    });

    test('previews stay short enough to sit above the button', () {
      for (final entry in alloBotFeaturePreviews.entries) {
        expect(
          entry.value.uses.length,
          lessThanOrEqualTo(4),
          reason: '${entry.key} has too many lines to fit',
        );
      }
    });

    test('an unknown feature type has no preview rather than a blank one', () {
      expect(featurePreviewFor('not_a_feature'), isNull);
    });
  });

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

  group('the voice card lays out without overflowing', () {
    /// Pumps the Ask Allo tab at a given logical screen size.
    ///
    /// A feature preview plus its Open button is the tallest thing this screen
    /// shows, and on a short phone it used to overflow the fixed middle area by
    /// 73px — spilling over the controls row and under the docked mic.
    Future<GlobalKey<AlloBotAskAiTabState>> pumpTab(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = GlobalKey<AlloBotAskAiTabState>();
      await tester.pumpWidget(
        MaterialApp(
          home: AlloBotAskAiTab(key: key, onOpenChat: () {}),
        ),
      );
      await tester.pump();
      return key;
    }

    testWidgets('fits a tall screen', (tester) async {
      await pumpTab(tester, const Size(412, 915));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a short screen', (tester) async {
      // The size the overflow showed up at.
      await pumpTab(tester, const Size(360, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the middle area scrolls rather than overflowing',
        (tester) async {
      await pumpTab(tester, const Size(360, 640));
      // A scroll view is what absorbs content taller than the area, so the
      // preview and its button can never spill into the controls row again.
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits the feature preview and its button on a short screen',
        (tester) async {
      // The exact case in the bug: Medical Reports has the longest preview
      // lines, and this is the screen size it overflowed by 73px on.
      final key = await pumpTab(tester, const Size(360, 640));
      key.currentState!.showOpenButtonForTesting('Medical Reports', 'report');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Open Medical Reports'), findsOneWidget);
      expect(find.text('WHAT YOU CAN DO HERE'), findsOneWidget);
    });

    testWidgets('fits every feature preview, on the shortest screen',
        (tester) async {
      for (final type in alloBotFeaturePreviews.keys) {
        final key = await pumpTab(tester, const Size(320, 568));
        key.currentState!
            .showOpenButtonForTesting(alloBotFeaturePreviews[type]!.name, type);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'overflowed for "$type"');
      }
    });

    testWidgets('the preview is not wrapped in its own card', (tester) async {
      final key = await pumpTab(tester, const Size(412, 915));
      key.currentState!.showOpenButtonForTesting('Medical Reports', 'report');
      await tester.pump();

      // It already sits inside the white voice card; a second panel around it
      // was a box inside a box.
      final boxed = tester.widgetList<Container>(find.byType(Container)).where(
            (container) =>
                container.decoration is BoxDecoration &&
                (container.decoration as BoxDecoration).color ==
                    const Color(0xFFFFF7F9),
          );
      expect(boxed, isEmpty);
    });
  });
}
