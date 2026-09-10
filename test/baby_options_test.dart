import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/baby/baby_options.dart';

void main() {
  group('babyAgeLabel', () {
    final now = DateTime(2026, 9, 9);

    test('a baby born today reads as a newborn', () {
      expect(babyAgeLabel(DateTime(2026, 9, 9), now: now), 'Newborn');
    });

    test('counts days below one month', () {
      expect(babyAgeLabel(DateTime(2026, 9, 8), now: now), '1 day');
      expect(babyAgeLabel(DateTime(2026, 8, 25), now: now), '15 days');
    });

    test('counts months up to two years', () {
      expect(babyAgeLabel(DateTime(2026, 8, 9), now: now), '1 month');
      expect(babyAgeLabel(DateTime(2026, 3, 9), now: now), '6 months');
      expect(babyAgeLabel(DateTime(2024, 10, 9), now: now), '23 months');
    });

    test('switches to years at two', () {
      expect(babyAgeLabel(DateTime(2024, 9, 9), now: now), '2 yrs');
      expect(babyAgeLabel(DateTime(2019, 9, 9), now: now), '7 yrs');
    });

    test('does not round a month up before the day of the month lands', () {
      // Born on the 20th, so on the 9th they are still 5 months, not 6.
      expect(babyAgeLabel(DateTime(2026, 3, 20), now: now), '5 months');
    });

    test('a null date of birth renders as empty, not a crash', () {
      expect(babyAgeLabel(null), '');
    });

    test('a future date of birth is treated as not yet born', () {
      expect(babyAgeLabel(DateTime(2026, 12, 1), now: now), 'Due soon');
    });
  });

  group('stored value labels', () {
    test('known values map to their display label', () {
      expect(labelForGender('male'), 'Boy');
      expect(labelForGender('female'), 'Girl');
      expect(labelForDeliveryType('c-section'), 'C-Section');
      expect(labelForDeliveryType('normal'), 'Normal');
    });

    test('missing values render as a dash', () {
      expect(labelForGender(null), '—');
      expect(labelForGender(''), '—');
      expect(labelForDeliveryType(null), '—');
    });

    test('an unrecognised value is shown as-is rather than hidden', () {
      expect(labelForGender('intersex'), 'intersex');
    });
  });
}
