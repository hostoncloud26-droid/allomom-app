import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/cycle_predictor.dart';

/// Pre-pregnancy and new-mom users get a next-period prediction instead of a
/// due date, so the arithmetic is pinned down here.
void main() {
  group('predictCycle', () {
    test('next period is one cycle after the LMP', () {
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 10),
      );
      expect(p.nextPeriodStart, DateTime(2026, 5, 29));
      expect(p.cycleLength, 28);
      expect(p.daysUntilNextPeriod, 19);
    });

    test('honours a custom cycle length', () {
      final short = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        cycleLength: 21,
        today: DateTime(2026, 5, 2),
      );
      expect(short.nextPeriodStart, DateTime(2026, 5, 22));

      final long = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        cycleLength: 35,
        today: DateTime(2026, 5, 2),
      );
      expect(long.nextPeriodStart, DateTime(2026, 6, 5));
    });

    test('clamps an out-of-range cycle length', () {
      expect(
        predictCycle(
          lastPeriodStart: DateTime(2026, 5, 1),
          cycleLength: 5,
          today: DateTime(2026, 5, 2),
        ).cycleLength,
        minCycleLength,
      );
      expect(
        predictCycle(
          lastPeriodStart: DateTime(2026, 5, 1),
          cycleLength: 99,
          today: DateTime(2026, 5, 2),
        ).cycleLength,
        maxCycleLength,
      );
    });

    test('a stale LMP rolls forward to a future date, never a past one', () {
      // LMP six months ago — the naive lmp + 28 days would be long gone.
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 1, 5),
        today: DateTime(2026, 7, 1),
      );
      expect(p.nextPeriodStart.isAfter(DateTime(2026, 6, 30)), isTrue);
      expect(p.daysUntilNextPeriod, greaterThanOrEqualTo(0));

      // And it still lands on a whole number of cycles from the LMP.
      final offset = p.nextPeriodStart.difference(DateTime(2026, 1, 5)).inDays;
      expect(offset % 28, 0);
    });

    test('a period due today reads as 0 days away, not negative', () {
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 29),
      );
      expect(p.nextPeriodStart, DateTime(2026, 5, 29));
      expect(p.daysUntilNextPeriod, 0);
    });

    test('ovulation is a luteal phase before the next period', () {
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 2),
      );
      expect(
        p.nextPeriodStart.difference(p.ovulationDate).inDays,
        lutealPhaseDays,
      );
      expect(p.ovulationDate, DateTime(2026, 5, 15));
    });

    test('the fertile window spans 5 days before ovulation to 1 day after', () {
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 2),
      );
      expect(p.fertileWindowStart, DateTime(2026, 5, 10));
      expect(p.fertileWindowEnd, DateTime(2026, 5, 16));
      expect(p.fertileWindowEnd.difference(p.fertileWindowStart).inDays, 6);
    });

    test('isFertile covers the window inclusively', () {
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 2),
      );
      expect(p.isFertile(DateTime(2026, 5, 9)), isFalse);
      expect(p.isFertile(DateTime(2026, 5, 10)), isTrue);
      expect(p.isFertile(DateTime(2026, 5, 15)), isTrue);
      expect(p.isFertile(DateTime(2026, 5, 16)), isTrue);
      expect(p.isFertile(DateTime(2026, 5, 17)), isFalse);
      // Time of day must not matter.
      expect(p.isFertile(DateTime(2026, 5, 16, 23, 59)), isTrue);
    });

    test('cycle day counts from the current cycle start and is 1-based', () {
      expect(
        predictCycle(
          lastPeriodStart: DateTime(2026, 5, 1),
          today: DateTime(2026, 5, 1),
        ).cycleDay,
        1,
      );
      expect(
        predictCycle(
          lastPeriodStart: DateTime(2026, 5, 1),
          today: DateTime(2026, 5, 10),
        ).cycleDay,
        10,
      );
      // Two cycles on, day 3 of the third cycle.
      expect(
        predictCycle(
          lastPeriodStart: DateTime(2026, 5, 1),
          today: DateTime(2026, 6, 28),
        ).cycleDay,
        3,
      );
    });

    test('cycle day never drops below 1 for a future LMP', () {
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 6, 1),
        today: DateTime(2026, 5, 1),
      );
      expect(p.cycleDay, greaterThanOrEqualTo(1));
    });

    test('the time component of the inputs is ignored', () {
      final a = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1, 23, 59),
        today: DateTime(2026, 5, 10, 0, 1),
      );
      final b = predictCycle(
        lastPeriodStart: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 10),
      );
      expect(a.nextPeriodStart, b.nextPeriodStart);
      expect(a.cycleDay, b.cycleDay);
    });

    test('predictions cross month and year boundaries correctly', () {
      final p = predictCycle(
        lastPeriodStart: DateTime(2026, 12, 20),
        today: DateTime(2026, 12, 21),
      );
      expect(p.nextPeriodStart, DateTime(2027, 1, 17));
    });
  });

  group('upcomingPeriodDates', () {
    test('returns consecutive cycles starting with the soonest', () {
      final dates = upcomingPeriodDates(
        lastPeriodStart: DateTime(2026, 5, 1),
        today: DateTime(2026, 5, 2),
        count: 3,
      );
      expect(dates, [
        DateTime(2026, 5, 29),
        DateTime(2026, 6, 26),
        DateTime(2026, 7, 24),
      ]);
    });

    test('respects the cycle length and count', () {
      final dates = upcomingPeriodDates(
        lastPeriodStart: DateTime(2026, 5, 1),
        cycleLength: 30,
        today: DateTime(2026, 5, 2),
        count: 2,
      );
      expect(dates, [DateTime(2026, 5, 31), DateTime(2026, 6, 30)]);
    });
  });
}
