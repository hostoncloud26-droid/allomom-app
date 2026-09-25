import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/config/app_theme.dart';

void main() {
  sheetPeekTests();
  // The vitals and nutrition screens keep the card short (170) above their
  // data; the detail pages use 230–250. The baby must show at every size.
  for (final height in [150.0, 170.0, 230.0, 250.0, 270.0]) {
    for (final speaker in [false, true]) {
      testWidgets('the baby shows in a $height card (speaker: $speaker)', (
        t,
      ) async {
        t.view.physicalSize = const Size(360, 800);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: BabyHeroBanner(
                  height: height,
                  speechText:
                      'Small snacks in between are good for us, Mommy. '
                      'Add them here too.',
                  onSpeakerTap: speaker ? () {} : null,
                ),
              ),
            ),
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull);
        expect(find.byKey(BabyHeroBanner.babyKey), findsOneWidget);
        expect(find.byKey(BabyHeroBanner.bubbleKey), findsOneWidget);
        final baby = t.getRect(find.byKey(BabyHeroBanner.babyKey));
        final bubble = t.getRect(find.byKey(BabyHeroBanner.bubbleKey));
        expect(baby.overlaps(bubble), isFalse, reason: '$baby vs $bubble');
        // The test font sets text far wider than the real one, so the bubble
        // wraps more here than on a phone; 60 still means a baby, not a sliver.
        expect(baby.height, greaterThan(60));
      });
    }
  }
}

void sheetPeekTests() {
  testWidgets('the baby peeks over the sheet edge, prompt inside', (t) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final nav = GlobalKey<NavigatorState>();
    const sheetKey = Key('sheet');
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: AppTheme.light,
        home: const Scaffold(),
      ),
    );
    showModalBottomSheet<void>(
      context: nav.currentContext!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BabySheetPeek(
        child: Container(
          key: sheetKey,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BabySheetPrompt(
                text:
                    'Every time you drink water, tap here, Mommy. '
                    "I'll keep the count for you.",
              ),
              SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);

    final sheet = t.getRect(find.byKey(sheetKey));
    final baby = t.getRect(find.byKey(BabySheetPeek.babyKey));
    // Head above the rim, hands just over it.
    expect(baby.top, lessThan(sheet.top));
    expect(baby.bottom, greaterThan(sheet.top));
    expect(baby.bottom - sheet.top, lessThan(20));
    expect(find.byKey(BabySheetPrompt.promptKey), findsOneWidget);
  });
}
