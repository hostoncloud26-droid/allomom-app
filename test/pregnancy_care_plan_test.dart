import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/pregnancy_care_scheduler.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';

void main() {
  group('addMonthsClamped', () {
    test('keeps the day of month when the target month is long enough', () {
      expect(addMonthsClamped(DateTime(2026, 1, 15), 2), DateTime(2026, 3, 15));
      expect(addMonthsClamped(DateTime(2026, 5, 1), 4), DateTime(2026, 9, 1));
    });

    test('clamps instead of rolling over into the next month', () {
      // The bug this guards: DateTime(2026, 2, 31) is silently 3 March.
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonthsClamped(DateTime(2026, 3, 31), 1), DateTime(2026, 4, 30));
      expect(addMonthsClamped(DateTime(2026, 8, 31), 1), DateTime(2026, 9, 30));
    });

    test('handles leap years', () {
      expect(addMonthsClamped(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    });

    test('crosses year boundaries', () {
      expect(
        addMonthsClamped(DateTime(2026, 11, 20), 3),
        DateTime(2027, 2, 20),
      );
      expect(
        addMonthsClamped(DateTime(2026, 12, 5), 10),
        DateTime(2027, 10, 5),
      );
    });

    test('a full 10-month plan stays strictly increasing', () {
      for (final lmp in [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 5, 30),
        DateTime(2024, 1, 29),
      ]) {
        DateTime? previous;
        for (final month in pregnancyMonths) {
          final date = addMonthsClamped(lmp, month);
          if (previous != null) {
            expect(
              date.isAfter(previous),
              isTrue,
              reason: 'month $month not after previous for lmp $lmp',
            );
          }
          previous = date;
        }
      }
    });
  });

  group('trimesterForMonth', () {
    test('splits 1-3 / 4-6 / 7-10', () {
      expect([1, 2, 3].map(trimesterForMonth), everyElement(1));
      expect([4, 5, 6].map(trimesterForMonth), everyElement(2));
      expect([7, 8, 9, 10].map(trimesterForMonth), everyElement(3));
    });
  });

  group('monthLabel', () {
    test('uses the right ordinal suffix', () {
      expect(monthLabel(1), '1st Month');
      expect(monthLabel(2), '2nd Month');
      expect(monthLabel(3), '3rd Month');
      expect(monthLabel(4), '4th Month');
      expect(monthLabel(10), '10th Month');
    });
  });

  group('vaccineSchedule', () {
    test('matches the four doses and months specified', () {
      expect(vaccineSchedule.map((v) => (v.name, v.month, v.doseNumber)), [
        ('TT-1 (Tetanus Toxoid, 1st dose)', 2, 1),
        ('TT-2 (Tetanus Toxoid, 2nd dose)', 4, 2),
        ('Influenza Vaccine (Flu Shot)', 6, 1),
        ('Tdap (Tetanus, Diphtheria, Pertussis)', 8, 1),
      ]);
    });

    test('every dose has a purpose and a valid month', () {
      for (final v in vaccineSchedule) {
        expect(v.purpose, isNotEmpty, reason: v.name);
        expect(pregnancyMonths, contains(v.month), reason: v.name);
      }
    });
  });

  group('reportSchedule', () {
    test('has 20 tests, 18 required and 2 optional', () {
      expect(reportSchedule, hasLength(20));
      expect(reportSchedule.where((r) => r.isRequired), hasLength(18));
      expect(reportSchedule.where((r) => !r.isRequired), hasLength(2));
    });

    test('only TB screening and NST are optional', () {
      expect(
        reportSchedule.where((r) => !r.isRequired).map((r) => r.name),
        containsAll(['Tuberculosis (TB) Screening', 'Non-Stress Test (NST)']),
      );
    });

    test('the month 2 booking panel holds all eight tests', () {
      final month2 = reportSchedule.where((r) => r.month == 2).toList();
      expect(month2, hasLength(8));
      expect(
        month2.map((r) => r.name),
        containsAll([
          'Complete Blood Count (CBC)',
          'Blood Group and Rh Factor',
          'HIV Test',
          'Tuberculosis (TB) Screening',
          'Thyroid Function Test (TFT)',
          'VDRL (Syphilis Test)',
          'Hepatitis B (HBsAg)',
          'Urine Routine Examination',
        ]),
      );
    });

    test('Hb and urine repeat every month from 3 to 7', () {
      for (final month in [3, 4, 5, 6, 7]) {
        final names = reportSchedule
            .where((r) => r.month == month)
            .map((r) => r.name);
        expect(names, contains('Hemoglobin (Hb)'), reason: 'month $month');
        expect(
          names,
          contains('Urine Routine Examination'),
          reason: 'month $month',
        );
      }
    });

    test('OGTT is month 6 and NST is month 8', () {
      expect(
        reportSchedule
            .firstWhere((r) => r.name.startsWith('Oral Glucose'))
            .month,
        6,
      );
      final nst = reportSchedule.firstWhere(
        (r) => r.name.startsWith('Non-Stress'),
      );
      expect(nst.month, 8);
      expect(nst.isRequired, isFalse);
    });

    test('every test carries a purpose and a known category', () {
      for (final r in reportSchedule) {
        expect(r.purpose, isNotEmpty, reason: r.name);
        expect(pregnancyMonths, contains(r.month), reason: r.name);
        expect(
          ['blood', 'urine', 'screening', 'monitoring'],
          contains(r.category),
          reason: r.name,
        );
      }
    });
  });

  group('PregnancyCareScheduler.preview', () {
    test('dates the ANC visits off the LMP, one per chosen month', () {
      final lmp = DateTime(2026, 1, 10);
      final preview = PregnancyCareScheduler.preview(
        lmpDate: lmp,
        ancMonths: const [3, 2, 6, 2], // unsorted, with a duplicate
      );

      expect(preview.ancDates.keys, [2, 3, 6]);
      expect(preview.ancDates[2], DateTime(2026, 3, 10));
      expect(preview.ancDates[3], DateTime(2026, 4, 10));
      expect(preview.ancDates[6], DateTime(2026, 7, 10));
      expect(preview.ancCount, 3);
    });

    test('vaccine dates follow the fixed schedule, not the ANC choice', () {
      final preview = PregnancyCareScheduler.preview(
        lmpDate: DateTime(2026, 1, 10),
        ancMonths: const [2],
      );

      expect(preview.vaccineCount, 4);
      expect(
        preview.vaccineDates['TT-1 (Tetanus Toxoid, 1st dose)'],
        DateTime(2026, 3, 10),
      );
      expect(
        preview.vaccineDates['Tdap (Tetanus, Diphtheria, Pertussis)'],
        DateTime(2026, 9, 10),
      );
    });

    test('dropping optional tests reduces the report count', () {
      final all = PregnancyCareScheduler.preview(
        lmpDate: DateTime(2026, 1, 10),
        ancMonths: defaultAncMonths,
      );
      final requiredOnly = PregnancyCareScheduler.preview(
        lmpDate: DateTime(2026, 1, 10),
        ancMonths: defaultAncMonths,
        includeOptional: false,
      );

      expect(all.reportCount, 20);
      expect(requiredOnly.reportCount, 18);
      expect(all.optionalReportCount, 2);
      expect(all.total, 8 + 4 + 20);
    });
  });
  // `PregnancyCareScheduler.scheduleFor` no longer generates the plan —
  // allomom-api-new seeds ANC visits, vaccinations and lab reports when a
  // pregnancy is created, and the scheduler only counts what came back. The
  // group that asserted on locally-written rows was removed with it; the
  // clinical plan above is still the source those server schedules follow.
}
