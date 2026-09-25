import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/components/baby_bottom_avatar.dart';

void main() {
  testWidgets('a sheet over a baby keeps the popup away; a new page does not', (
    t,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [BabyOnScreen.observer],
        home: const Scaffold(body: BabyOnScreen(child: Text('baby'))),
      ),
    );
    expect(BabyOnScreen.anyVisible, isTrue);

    showModalBottomSheet<void>(
      context: nav.currentContext!,
      builder: (_) => const SizedBox(height: 100, child: Text('sheet')),
    );
    await t.pumpAndSettle();
    expect(BabyOnScreen.anyVisible, isTrue, reason: 'under a sheet');

    nav.currentState!.pop();
    await t.pumpAndSettle();
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('page')),
      ),
    );
    await t.pumpAndSettle();
    expect(BabyOnScreen.anyVisible, isFalse, reason: 'under another page');
  });

  testWidgets('a whole-screen marker holds on a hidden tab', (t) async {
    await t.pumpWidget(
      MaterialApp(
        navigatorObservers: [BabyOnScreen.observer],
        home: const Scaffold(
          body: BabyOnScreen(
            wholeScreen: true,
            child: IndexedStack(
              index: 1,
              children: [
                BabyOnScreen(child: Text('baby')),
                Text('chat'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(BabyOnScreen.anyVisible, isTrue);
  });
}
