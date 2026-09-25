import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';

void main() {
  final now = DateTime(2026, 9, 25);

  group('baby week', () {
    test('birth is week 41, one more each week', () {
      expect(WeeklyBabyTalk.babyWeekOf(now, now: now), 41);
      expect(
        WeeklyBabyTalk.babyWeekOf(
          now.subtract(const Duration(days: 12)),
          now: now,
        ),
        42,
      );
    });

    test('runs to week 142, then stops', () {
      final lastDay = now.subtract(const Duration(days: 101 * 7 + 6));
      expect(WeeklyBabyTalk.babyWeekOf(lastDay, now: now), 142);
      final past = now.subtract(const Duration(days: 102 * 7));
      expect(WeeklyBabyTalk.babyWeekOf(past, now: now), isNull);
      expect(WeeklyBabyTalk.babyWeekOf(null, now: now), isNull);
    });

    test('age reads naturally', () {
      expect(
        WeeklyBabyTalk.ageLabel(now.subtract(const Duration(days: 12)), now: now),
        '1 week old',
      );
      expect(WeeklyBabyTalk.ageLabel(DateTime(2026, 4, 10), now: now), '5 months old');
      expect(
        WeeklyBabyTalk.ageLabel(DateTime(2025, 7, 25), now: now),
        '1 year 2 months old',
      );
    });
  });

  group("baby items in Today's Care", () {
    List<String> ids(CareDayPart part, int? age) => [
      for (final item in careItemsFor(
        part: part,
        isPregnant: false,
        pregnancyDay: 0,
        babyAgeDays: age,
      ))
        item.id,
    ];

    test('no baby, no baby items', () {
      for (final part in CareDayPart.values) {
        expect(ids(part, null).where((id) => id.startsWith('baby_')), isEmpty);
      }
    });

    test('a feed in every daytime window, ticked per window', () {
      for (final part in [
        CareDayPart.morning,
        CareDayPart.afternoon,
        CareDayPart.evening,
        CareDayPart.night,
      ]) {
        expect(ids(part, 12), contains('baby_feed'));
      }
      final feed = careItemsFor(
        part: CareDayPart.morning,
        isPregnant: false,
        pregnancyDay: 0,
        babyAgeDays: 12,
      ).firstWhere((i) => i.id == 'baby_feed');
      expect(feed.destination, CareDestination.feedingTracker);
      expect(feed.donePerPart, isTrue);
    });

    test('items follow the age', () {
      // Newborn: sponge bath, night feeds, nappy count; no tummy time yet.
      expect(ids(CareDayPart.lateNight, 5), contains('baby_feed'));
      expect(ids(CareDayPart.night, 5), contains('baby_nappies'));
      expect(ids(CareDayPart.midMorning, 5), isNot(contains('tummy_time')));
      // Toddler: no night feed or vitamin D.
      expect(ids(CareDayPart.lateNight, 400), isNot(contains('baby_feed')));
      expect(ids(CareDayPart.morning, 400), isNot(contains('baby_vitamin_d')));
    });
  });
}
