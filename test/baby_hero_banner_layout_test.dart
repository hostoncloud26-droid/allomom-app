import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/components/baby_hero_banner.dart';

/// Geometry guard for the banner.
///
/// The bug this pins: the bubble and the baby used to be two independent
/// `Positioned` widgets with the baby fixed at 160px tall. At the 150px height
/// every form drops to when the keyboard opens, the baby overflowed the top of
/// the card and the bubble sat on its face. These assertions measure the real
/// painted rectangles rather than trusting the widget tree to look right.
void main() {
  /// Full-layout heights used across the app: the keyboard-closed size, the
  /// default, and the tall home-page variant. The 150px keyboard-open size is
  /// below [BabyHeroBanner.compactHeight] and is asserted separately.
  const heights = <double>[200, 260, 270, 340];

  Future<Rect> rectOf(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'expected $key to be laid out');
    return tester.getRect(finder);
  }

  Future<void> pumpBanner(
    WidgetTester tester, {
    required double height,
    String text = 'What\'s your mobile number\nso I can stay close? 📱',
    VoidCallback? onSpeakerTap,
    String greeting = '',
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: BabyHeroBanner(
              speechText: text,
              greetingText: greeting,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              onSpeakerTap: onSpeakerTap,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final height in heights) {
    group('at ${height.toInt()}px', () {
      testWidgets('the bubble never covers the baby', (tester) async {
        await pumpBanner(tester, height: height);

        final bubble = await rectOf(tester, BabyHeroBanner.bubbleKey);
        final baby = await rectOf(tester, BabyHeroBanner.babyKey);

        expect(
          bubble.overlaps(baby),
          isFalse,
          reason:
              'bubble $bubble overlaps baby $baby — the bubble is sitting on '
              'the baby\'s face again',
        );
        // The bubble is the thing on top; the baby sits under it.
        expect(bubble.bottom, lessThanOrEqualTo(baby.top + 0.5));
      });

      testWidgets('the baby stays inside the card', (tester) async {
        await pumpBanner(tester, height: height);

        final card = tester.getRect(find.byType(BabyHeroBanner));
        final baby = await rectOf(tester, BabyHeroBanner.babyKey);

        expect(
          baby.top,
          greaterThanOrEqualTo(card.top - 0.5),
          reason: 'the baby is clipped off the top of the card',
        );
        expect(
          baby.bottom,
          lessThanOrEqualTo(card.bottom + 0.5),
          reason: 'the baby is clipped off the bottom of the card',
        );
        expect(baby.height, greaterThan(0));
      });

      testWidgets('nothing overflows', (tester) async {
        await pumpBanner(tester, height: height);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('the card honours the height it is given', (tester) async {
    for (final height in [150.0, ...heights]) {
      await pumpBanner(tester, height: height);
      expect(tester.getRect(find.byType(BabyHeroBanner)).height, height);
    }
  });

  testWidgets('a speaker button does not push the baby out', (tester) async {
    await pumpBanner(tester, height: 260, onSpeakerTap: () {});

    final bubble = await rectOf(tester, BabyHeroBanner.bubbleKey);
    final baby = await rectOf(tester, BabyHeroBanner.babyKey);

    expect(bubble.overlaps(baby), isFalse);
    expect(baby.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long prompt still leaves the baby room', (tester) async {
    await pumpBanner(
      tester,
      height: 260,
      text: 'This is a deliberately long prompt that wraps onto several '
          'lines so the bubble grows as tall as it possibly can.',
    );

    final bubble = await rectOf(tester, BabyHeroBanner.bubbleKey);
    final baby = await rectOf(tester, BabyHeroBanner.babyKey);

    expect(bubble.overlaps(baby), isFalse);
    expect(baby.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  group('compact (the size forms drop to when the keyboard opens)', () {
    testWidgets('shows the prompt alone rather than a squashed baby',
        (tester) async {
      await pumpBanner(tester, height: 150);

      expect(find.byKey(BabyHeroBanner.bubbleKey), findsOneWidget);
      expect(
        find.byKey(BabyHeroBanner.babyKey),
        findsNothing,
        reason: 'there is no room for the baby at this height',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the prompt stays inside the card', (tester) async {
      await pumpBanner(tester, height: 150, onSpeakerTap: () {});

      final card = tester.getRect(find.byType(BabyHeroBanner));
      final bubble = await rectOf(tester, BabyHeroBanner.bubbleKey);

      expect(bubble.top, greaterThanOrEqualTo(card.top - 0.5));
      expect(bubble.bottom, lessThanOrEqualTo(card.bottom + 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long prompt still does not overflow', (tester) async {
      await pumpBanner(
        tester,
        height: 150,
        text: 'This is a deliberately long prompt that wraps onto several '
            'lines so the bubble grows as tall as it possibly can.',
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a bottom greeting sits below the baby, not on it',
      (tester) async {
    await pumpBanner(tester, height: 270, greeting: 'Welcome back!');

    final baby = await rectOf(tester, BabyHeroBanner.babyKey);
    final greeting = tester.getRect(find.text('Welcome back!'));

    expect(greeting.top, greaterThanOrEqualTo(baby.bottom - 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('with no bubble the baby gets the whole card', (tester) async {
    await pumpBanner(tester, height: 270, text: '');

    expect(find.byKey(BabyHeroBanner.bubbleKey), findsNothing);
    final baby = await rectOf(tester, BabyHeroBanner.babyKey);
    // Card height, less the 18/8 vertical padding and the 1.2px border the
    // card draws on each edge.
    expect(baby.height, closeTo(270 - 18 - 8 - (1.2 * 2), 1));
  });
}
