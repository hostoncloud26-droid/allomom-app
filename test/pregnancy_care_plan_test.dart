import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/pregnancy_care_scheduler.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

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

  group('PregnancyCareScheduler.scheduleFor', () {
    late AppDriftDatabase db;
    const pregnancyId = 'preg-1';
    const userId = 'usr-1';
    final lmp = DateTime(2026, 1, 10);

    setUp(() {
      db = AppDriftDatabase.forTesting(NativeDatabase.memory());
      SqLiteService.overrideDatabaseForTesting(db);
    });

    tearDown(() async {
      SqLiteService.overrideDatabaseForTesting(null);
      await db.close();
    });

    Future<PregnancyCarePlanResult> run({
      List<int>? ancMonths,
      bool includeOptional = true,
    }) {
      return PregnancyCareScheduler.instance.scheduleFor(
        pregnancyId: pregnancyId,
        userId: userId,
        lmpDate: lmp,
        ancMonths: ancMonths ?? defaultAncMonths,
        includeOptional: includeOptional,
      );
    }

    test('writes the whole plan and reports what it created', () async {
      final result = await run();

      expect(result.ancVisits, 8);
      expect(result.vaccinations, 4);
      expect(result.reports, 20);
      expect(result.total, 32);

      expect(
        await PregnancyCareDbService.instance.getAncVisits(pregnancyId),
        hasLength(8),
      );
      expect(
        await PregnancyCareDbService.instance.getVaccinations(
          userId,
          pregnancyId: pregnancyId,
        ),
        hasLength(4),
      );
      expect(
        await PregnancyCareDbService.instance.getReportChecklists(
          userId,
          pregnancyId: pregnancyId,
        ),
        hasLength(20),
      );
    });

    test('every row lands unsynced and pending', () async {
      await run();

      final anc = await PregnancyCareDbService.instance.unsyncedAncVisits();
      final vaccines = await PregnancyCareDbService.instance
          .unsyncedVaccinations();
      final reports = await PregnancyCareDbService.instance
          .unsyncedReportChecklists();

      expect(anc, hasLength(8));
      expect(vaccines, hasLength(4));
      expect(reports, hasLength(20));

      expect(anc.every((v) => v.status == 'pending'), isTrue);
      expect(vaccines.every((v) => v.status == 'pending'), isTrue);
      expect(reports.every((r) => r.status == 'pending'), isTrue);
    });

    test(
      'ANC visits are numbered in month order with the right trimester',
      () async {
        await run(ancMonths: const [9, 2, 5]);

        final visits = await PregnancyCareDbService.instance.getAncVisits(
          pregnancyId,
        );
        expect(visits.map((v) => v.pregnancyMonth), [2, 5, 9]);
        expect(visits.map((v) => v.visitNumber), [1, 2, 3]);
        expect(visits.map((v) => v.trimester), [1, 2, 3]);
        expect(visits.map((v) => v.scheduledDate), [
          DateTime(2026, 3, 10),
          DateTime(2026, 6, 10),
          DateTime(2026, 10, 10),
        ]);
      },
    );

    test('vaccinations carry their month, dose and due date', () async {
      await run();

      final vaccines = await PregnancyCareDbService.instance.getVaccinations(
        userId,
        pregnancyId: pregnancyId,
      );

      final tt1 = vaccines.firstWhere((v) => v.vaccineName.startsWith('TT-1'));
      expect(tt1.pregnancyMonth, 2);
      expect(tt1.doseNumber, 1);
      expect(tt1.scheduledDate, DateTime(2026, 3, 10));
      expect(tt1.notes, isNotNull);

      final tt2 = vaccines.firstWhere((v) => v.vaccineName.startsWith('TT-2'));
      expect(tt2.pregnancyMonth, 4);
      expect(tt2.doseNumber, 2);
      expect(tt2.scheduledDate, DateTime(2026, 5, 10));
    });

    test(
      'lab reports carry month, category, purpose and required flag',
      () async {
        await run();

        final reports = await PregnancyCareDbService.instance
            .getReportChecklists(userId, pregnancyId: pregnancyId);

        final cbc = reports.firstWhere(
          (r) => r.reportName.startsWith('Complete'),
        );
        expect(cbc.pregnancyMonth, 2);
        expect(cbc.category, 'blood');
        expect(cbc.notes, 'Detect anemia');
        expect(cbc.isRequired, isTrue);
        expect(cbc.dueDate, DateTime(2026, 3, 10));

        final tb = reports.firstWhere(
          (r) => r.reportName.startsWith('Tubercul'),
        );
        expect(tb.isRequired, isFalse);

        // Five separate Hb rows, one per month from 3 to 7.
        final hb = reports.where((r) => r.reportName == 'Hemoglobin (Hb)');
        expect(hb.map((r) => r.pregnancyMonth).toList()..sort(), [
          3,
          4,
          5,
          6,
          7,
        ]);
      },
    );

    test('skipping optional tests leaves only the required ones', () async {
      final result = await run(includeOptional: false);

      expect(result.reports, 18);
      final reports = await PregnancyCareDbService.instance.getReportChecklists(
        userId,
        pregnancyId: pregnancyId,
      );
      expect(reports.every((r) => r.isRequired), isTrue);
      expect(
        reports.any((r) => r.reportName.startsWith('Non-Stress')),
        isFalse,
      );
    });

    test(
      're-registering replaces the plan instead of duplicating it',
      () async {
        await run(ancMonths: const [2, 3, 4]);
        final second = await run(ancMonths: const [5, 6]);

        expect(second.ancVisits, 2);
        final visits = await PregnancyCareDbService.instance.getAncVisits(
          pregnancyId,
        );
        expect(visits.map((v) => v.pregnancyMonth), [5, 6]);

        // Vaccines and reports are rewritten, not appended.
        expect(
          await PregnancyCareDbService.instance.getVaccinations(
            userId,
            pregnancyId: pregnancyId,
          ),
          hasLength(4),
        );
        expect(
          await PregnancyCareDbService.instance.getReportChecklists(
            userId,
            pregnancyId: pregnancyId,
          ),
          hasLength(20),
        );
      },
    );

    test('an end-of-month LMP still schedules valid, ordered dates', () async {
      await PregnancyCareScheduler.instance.scheduleFor(
        pregnancyId: pregnancyId,
        userId: userId,
        lmpDate: DateTime(2026, 1, 31),
        ancMonths: pregnancyMonths,
      );

      final visits = await PregnancyCareDbService.instance.getAncVisits(
        pregnancyId,
      );
      expect(visits, hasLength(10));
      expect(visits.first.scheduledDate, DateTime(2026, 2, 28));

      DateTime? previous;
      for (final v in visits) {
        if (previous != null) {
          expect(v.scheduledDate.isAfter(previous), isTrue);
        }
        previous = v.scheduledDate;
      }
    });

    test(
      'no ANC months selected still schedules vaccines and reports',
      () async {
        final result = await run(ancMonths: const []);
        expect(result.ancVisits, 0);
        expect(result.vaccinations, 4);
        expect(result.reports, 20);
      },
    );
  });
}
