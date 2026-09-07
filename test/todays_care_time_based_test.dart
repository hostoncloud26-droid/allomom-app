import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';

/// The whole point of the section is that it follows the clock, so the slot
/// boundaries and the per-slot catalogue are pinned down here.
void main() {
  CareDayPart partAt(int hour, [int minute = 0]) =>
      CareDayPart.at(DateTime(2026, 5, 12, hour, minute));

  group('CareDayPart.at', () {
    test('morning covers 05:00 up to but not including 11:00', () {
      expect(partAt(5), CareDayPart.morning);
      expect(partAt(7, 30), CareDayPart.morning);
      expect(partAt(10, 59), CareDayPart.morning);
      expect(partAt(11), isNot(CareDayPart.morning));
    });

    test('mid-morning covers 11:00 up to 12:30', () {
      expect(partAt(11), CareDayPart.midMorning);
      expect(partAt(12, 29), CareDayPart.midMorning);
      expect(partAt(12, 30), isNot(CareDayPart.midMorning));
    });

    test('afternoon covers 12:30 up to 16:30', () {
      expect(partAt(12, 30), CareDayPart.afternoon);
      expect(partAt(13), CareDayPart.afternoon);
      expect(partAt(16, 29), CareDayPart.afternoon);
      expect(partAt(16, 30), isNot(CareDayPart.afternoon));
    });

    test('evening covers 16:30 up to 19:00', () {
      expect(partAt(16, 30), CareDayPart.evening);
      expect(partAt(18, 59), CareDayPart.evening);
      expect(partAt(19), isNot(CareDayPart.evening));
    });

    test('night covers 19:00 up to 22:00', () {
      expect(partAt(19), CareDayPart.night);
      expect(partAt(21, 59), CareDayPart.night);
      expect(partAt(22), isNot(CareDayPart.night));
    });

    test('late night wraps midnight through to 05:00', () {
      expect(partAt(22), CareDayPart.lateNight);
      expect(partAt(23, 59), CareDayPart.lateNight);
      expect(partAt(0), CareDayPart.lateNight);
      expect(partAt(4, 59), CareDayPart.lateNight);
      expect(partAt(5), CareDayPart.morning);
    });

    test('every minute of the day resolves to exactly one part', () {
      for (var minutes = 0; minutes < 24 * 60; minutes++) {
        final part = partAt(minutes ~/ 60, minutes % 60);
        expect(
          part,
          isA<CareDayPart>(),
          reason: 'no part for ${minutes ~/ 60}:${minutes % 60}',
        );
      }
    });
  });

  group('day part meals', () {
    test('the three main meals land in the windows the user asked for', () {
      expect(partAt(9).meal, CareMeal.breakfast, reason: 'morning before 11');
      expect(partAt(14).meal, CareMeal.lunch, reason: 'afternoon');
      expect(partAt(20).meal, CareMeal.dinner, reason: 'night');
    });

    test('snack and wind-down windows log no main meal', () {
      expect(partAt(11, 30).meal, isNull);
      expect(partAt(17).meal, isNull);
      expect(partAt(23).meal, isNull);
    });

    test('meal vital keys match the ones the rest of the app reads', () {
      expect(CareMeal.breakfast.vitalKey, 'breakfast');
      expect(CareMeal.breakfast.legacyVitalKey, 'break_fast');
      expect(CareMeal.lunch.vitalKey, 'lunch');
      expect(CareMeal.lunch.legacyVitalKey, isNull);
      expect(CareMeal.dinner.vitalKey, 'dinner');
    });
  });

  group('careItemsFor', () {
    List<CareItem> items(
      CareDayPart part, {
      bool isPregnant = true,
      int pregnancyDay = 200,
    }) => careItemsFor(
      part: part,
      isPregnant: isPregnant,
      pregnancyDay: pregnancyDay,
    );

    test('every window offers at least one item, with unique ids', () {
      for (final part in CareDayPart.values) {
        for (final pregnant in [true, false]) {
          final list = items(part, isPregnant: pregnant);
          expect(list, isNotEmpty, reason: '${part.name}/$pregnant is empty');
          final ids = list.map((i) => i.id).toList();
          expect(
            ids.toSet(),
            hasLength(ids.length),
            reason: 'duplicate id in ${part.name}/$pregnant: $ids',
          );
        }
      }
    });

    test('each window surfaces its own meal and nothing else', () {
      for (final part in CareDayPart.values) {
        final meals = items(part)
            .where((i) => i.kind == CareActionKind.meal)
            .map((i) => i.meal)
            .toList();
        expect(
          meals,
          part.meal == null ? isEmpty : [part.meal],
          reason: 'wrong meals for ${part.name}',
        );
      }
    });

    test('water is offered in every window with a trimester-aware goal', () {
      for (final part in CareDayPart.values) {
        final water = items(part).firstWhere((i) => i.id == 'water');
        expect(water.countVitalKey, 'water');
        expect(water.unitPlural, 'glasses');
        expect(
          water.caloriesPerUnit,
          isNull,
          reason: 'water stores glasses, not calories',
        );
        expect(water.dailyTarget, isNotNull);
      }

      int goal(bool pregnant, int day) => careItemsFor(
        part: CareDayPart.morning,
        isPregnant: pregnant,
        pregnancyDay: day,
      ).firstWhere((i) => i.id == 'water').dailyTarget!;

      expect(goal(false, 0), 8);
      expect(goal(true, 30), 10);
      expect(goal(true, 150), 11);
      expect(goal(true, 250), 12);
    });

    test('snack and coffee are calorie-backed counts', () {
      final snack = items(
        CareDayPart.midMorning,
      ).firstWhere((i) => i.id == 'snack');
      expect(snack.kind, CareActionKind.count);
      expect(snack.countVitalKey, 'snacks');
      expect(snack.unitPlural, 'portions');
      expect(
        snack.caloriesPerUnit,
        isNotNull,
        reason: 'snacks is a kcal series the calorie tracker sums',
      );

      final coffee = items(
        CareDayPart.evening,
      ).firstWhere((i) => i.id == 'coffee');
      expect(coffee.kind, CareActionKind.count);
      expect(coffee.countVitalKey, 'drinks');
      expect(coffee.unitPlural, 'cups');
      expect(coffee.caloriesPerUnit, isNotNull);
    });

    test('coffee warns about caffeine only while pregnant', () {
      String subtitle(bool pregnant) => careItemsFor(
        part: CareDayPart.evening,
        isPregnant: pregnant,
        pregnancyDay: 200,
      ).firstWhere((i) => i.id == 'coffee').subtitle;

      expect(subtitle(true).toLowerCase(), contains('caffeine'));
      expect(subtitle(false).toLowerCase(), isNot(contains('caffeine')));
    });

    test('supplements sit in the window they should be taken in', () {
      expect(
        items(CareDayPart.morning).map((i) => i.id),
        contains('folic_acid'),
      );
      expect(
        items(CareDayPart.afternoon).map((i) => i.id),
        contains('iron_tablet'),
      );
      expect(
        items(CareDayPart.night).map((i) => i.id),
        contains('calcium_tablet'),
      );

      // Iron and calcium must never be offered in the same window.
      for (final part in CareDayPart.values) {
        final ids = items(part).map((i) => i.id).toSet();
        expect(
          ids.containsAll({'iron_tablet', 'calcium_tablet'}),
          isFalse,
          reason: '${part.name} offers iron and calcium together',
        );
      }
    });

    test('no pregnancy items leak into a non-pregnant day', () {
      const pregnancyOnly = {
        'folic_acid',
        'iron_tablet',
        'calcium_tablet',
        'kick_count',
        'afternoon_rest',
        'left_side_sleep',
      };

      for (final part in CareDayPart.values) {
        final ids = items(part, isPregnant: false).map((i) => i.id).toSet();
        expect(
          ids.intersection(pregnancyOnly),
          isEmpty,
          reason: '${part.name} leaked pregnancy items: $ids',
        );
      }
    });

    test('kick counting only appears in the evening from week ~26', () {
      bool hasKicks(CareDayPart part, int day) => careItemsFor(
        part: part,
        isPregnant: true,
        pregnancyDay: day,
      ).any((i) => i.id == 'kick_count');

      expect(hasKicks(CareDayPart.evening, 179), isFalse);
      expect(hasKicks(CareDayPart.evening, 180), isTrue);
      expect(hasKicks(CareDayPart.evening, 250), isTrue);

      for (final part in CareDayPart.values) {
        if (part == CareDayPart.evening) continue;
        expect(
          hasKicks(part, 250),
          isFalse,
          reason: 'kick counting should be evening-only, saw ${part.name}',
        );
      }
    });

    test('kick counting navigates instead of logging inline', () {
      final kicks = items(
        CareDayPart.evening,
        pregnancyDay: 250,
      ).firstWhere((i) => i.id == 'kick_count');
      expect(kicks.kind, CareActionKind.navigate);
      expect(kicks.destination, CareDestination.kickCounter);
      // Counting kicks on the kick-counter screen must tick this off, so the
      // key has to match what `addKickCountEntry` writes.
      expect(kicks.doneVitalKey, 'kick_count');
    });

    test('feet-up rest starts in the second trimester', () {
      bool hasRest(int day) => careItemsFor(
        part: CareDayPart.afternoon,
        isPregnant: true,
        pregnancyDay: day,
      ).any((i) => i.id == 'afternoon_rest');

      expect(hasRest(60), isFalse);
      expect(hasRest(120), isTrue);
      expect(hasRest(250), isTrue);
    });

    test(
      'late night offers left-side sleep when pregnant, plain sleep if not',
      () {
        final pregnant = items(CareDayPart.lateNight).map((i) => i.id).toSet();
        expect(pregnant, contains('left_side_sleep'));
        expect(pregnant, isNot(contains('sleep')));

        final notPregnant = items(
          CareDayPart.lateNight,
          isPregnant: false,
        ).map((i) => i.id).toSet();
        expect(notPregnant, contains('sleep'));
        expect(notPregnant, isNot(contains('left_side_sleep')));
      },
    );

    test('breakfast advice changes with the trimester', () {
      String subtitle(int day) => careItemsFor(
        part: CareDayPart.morning,
        isPregnant: true,
        pregnancyDay: day,
      ).firstWhere((i) => i.kind == CareActionKind.meal).subtitle;

      final first = subtitle(30);
      final second = subtitle(150);
      final third = subtitle(250);
      expect({first, second, third}, hasLength(3));
      expect(first.toLowerCase(), contains('nausea'));
    });

    test('a missing LMP (day 0) still produces a usable list', () {
      for (final part in CareDayPart.values) {
        final list = items(part, pregnancyDay: 0);
        expect(list, isNotEmpty);
        expect(list.any((i) => i.id == 'kick_count'), isFalse);
      }
    });

    test('every item carries what its action needs', () {
      for (final part in CareDayPart.values) {
        for (final pregnant in [true, false]) {
          for (final item in items(part, isPregnant: pregnant)) {
            final where = '${part.name}/${item.id}';
            switch (item.kind) {
              case CareActionKind.meal:
                expect(item.meal, isNotNull, reason: where);
              case CareActionKind.count:
                expect(item.countVitalKey, isNotNull, reason: where);
                expect(item.unitPlural, isNotEmpty, reason: where);
                expect(item.unitSingular, isNotEmpty, reason: where);
                expect(item.presets, isNotEmpty, reason: where);
              case CareActionKind.checkoff:
                expect(item.actionValue, isNotNull, reason: where);
                expect(item.actionValue, isNotEmpty, reason: where);
              case CareActionKind.navigate:
                expect(item.destination, isNotNull, reason: where);
                expect(item.doneVitalKey, isNotNull, reason: where);
            }
            expect(item.title, isNotEmpty, reason: where);
            expect(item.subtitle, isNotEmpty, reason: where);
          }
        }
      }
    });
  });
}
