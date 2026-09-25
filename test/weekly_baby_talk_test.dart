/// The weekly Baby Talk line: which of the 142 weeks, and which intent.
///
/// The words come from running the week's AlloBot intent, stubbed here.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pregnancy weeks stay within 1–40', () {
    expect(WeeklyBabyTalk.pregnancyWeek(0), 1);
    expect(WeeklyBabyTalk.pregnancyWeek(6), 6);
    expect(WeeklyBabyTalk.pregnancyWeek(43), 40);
  });

  test('a baby counts on from the birth week to the last week', () {
    final now = DateTime(2026, 9, 25);
    expect(WeeklyBabyTalk.babyWeek(now, now: now), 41);
    expect(
      WeeklyBabyTalk.babyWeek(now.subtract(const Duration(days: 7)), now: now),
      42,
    );
    expect(
      WeeklyBabyTalk.babyWeek(now.subtract(const Duration(days: 2000)), now: now),
      142,
    );
  });

  test('each week is its own AlloBot intent', () {
    expect(WeeklyBabyTalk.intentKey(6), 'pregnancy_week_6_info');
    expect(WeeklyBabyTalk.intentKey(142), 'pregnancy_week_142_info');
  });

  test('the card text is the flow\'s steps in order', () async {
    WeeklyBabyTalk.runIntent = (key) async => key == 'pregnancy_week_6_info'
        ? [
            (text: 'Amma, my heart is flickering!', audioUrl: 'a.mp3'),
            (text: 'Drink buttermilk.', audioUrl: null),
          ]
        : const [];
    addTearDown(() => WeeklyBabyTalk.runIntent = (_) async => const []);

    expect(
      await WeeklyBabyTalk.message(6),
      'Amma, my heart is flickering!\n\nDrink buttermilk.',
    );
    expect(await WeeklyBabyTalk.message(7), isNull);
  });
}
