import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/baby_care_plan.dart';
import 'package:allomom/services/baby_care_scheduler.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDriftDatabase db;
  final babies = BabyDbService.instance;
  final repo = BabyRepository.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });

  group('schema', () {
    test('the three baby tables exist', () async {
      final names = db.allTables.map((t) => t.actualTableName).toList();
      expect(
        names,
        containsAll([
          'birth_records',
          'baby_immunization_records',
          'baby_milestones',
        ]),
      );
      await db.customSelect('SELECT COUNT(*) FROM birth_records').get();
      await db
          .customSelect('SELECT COUNT(*) FROM baby_immunization_records')
          .get();
      await db.customSelect('SELECT COUNT(*) FROM baby_milestones').get();
    });
  });

  group('BabyDbService', () {
    test('creating a birth record mints the baby its own health record',
        () async {
      final id = await babies.createBirthRecord(
        BirthRecordsCompanion(
          babyName: const Value('Aarav'),
          dob: Value(DateTime(2026, 3, 14)),
          gender: const Value('male'),
          bloodGroup: const Value('O+'),
          weight: const Value(3.2),
        ),
      );

      final record = await babies.getBirthRecordById(id);
      expect(record, isNotNull);
      expect(record!.babyName, 'Aarav');
      expect(record.synced, 0);
      expect(record.pregnancyId, isNull); // standalone baby
      expect(record.healthId, isNotNull);

      // The linked health record really exists and carries the baby's data.
      final health = await HealthDbService.instance.getHealthDataById(
        record.healthId!,
      );
      expect(health, isNotNull);
      expect(health!.bloodGroup, 'O+');
      expect(health.weight, 3.2);
      expect(health.pregnancyStatus, 'notpregnant');
    });

    test('an explicit healthId is respected instead of minting a new one',
        () async {
      final id = await babies.createBirthRecord(
        BirthRecordsCompanion(
          babyName: const Value('Existing'),
          dob: Value(DateTime(2025, 1, 1)),
          healthId: const Value('health-existing'),
        ),
      );
      final record = await babies.getBirthRecordById(id);
      expect(record!.healthId, 'health-existing');
    });

    test('update and delete round-trip, and delete cascades', () async {
      final id = await babies.createBirthRecord(
        BirthRecordsCompanion(dob: Value(DateTime(2026, 1, 1))),
      );
      final healthId = (await babies.getBirthRecordById(id))!.healthId!;

      await babies.updateBirthRecord(
        BirthRecordsCompanion(
          id: Value(id),
          babyName: const Value('Renamed'),
          bloodGroup: const Value('AB-'),
        ),
      );
      expect((await babies.getBirthRecordById(id))!.babyName, 'Renamed');

      await babies.createImmunization(
        BabyImmunizationRecordsCompanion(
          birthRecordId: Value(id),
          vaccineName: const Value('BCG'),
        ),
      );
      await babies.createMilestone(
        BabyMilestonesCompanion(
          birthRecordId: Value(id),
          milestone: const Value('Social smile'),
          description: const Value('Smiles back at you.'),
        ),
      );
      expect(await babies.getImmunizations(id), hasLength(1));
      expect(await babies.getMilestones(id), hasLength(1));

      await babies.deleteBirthRecord(id);

      expect(await babies.getBirthRecordById(id), isNull);
      expect(await babies.getImmunizations(id), isEmpty);
      expect(await babies.getMilestones(id), isEmpty);
      // The baby's health record goes with it.
      expect(
        await HealthDbService.instance.getHealthDataById(healthId),
        isNull,
      );
    });

    test('marking a dose given and a milestone achieved', () async {
      final babyId = await babies.createBirthRecord(
        BirthRecordsCompanion(dob: Value(DateTime(2026, 1, 1))),
      );
      final doseId = await babies.createImmunization(
        BabyImmunizationRecordsCompanion(
          birthRecordId: Value(babyId),
          vaccineName: const Value('OPV-1'),
        ),
      );
      final milestoneId = await babies.createMilestone(
        BabyMilestonesCompanion(
          birthRecordId: Value(babyId),
          milestone: const Value('Rolls over'),
          description: const Value('Rolls tummy to back.'),
        ),
      );

      expect((await babies.getImmunizationById(doseId))!.vaccinationDate,
          isNull);
      expect((await babies.getImmunizationById(doseId))!.required, isTrue);
      expect((await babies.getMilestoneById(milestoneId))!.achieved, isFalse);

      await babies.markImmunizationGiven(
        doseId,
        date: DateTime(2026, 2, 12),
        vaccinatedBy: 'Dr. Shalini',
      );
      await babies.setMilestoneAchieved(
        milestoneId,
        achieved: true,
        completedOn: DateTime(2026, 5, 2),
      );

      final dose = await babies.getImmunizationById(doseId);
      expect(dose!.vaccinationDate, DateTime(2026, 2, 12));
      expect(dose.vaccinatedBy, 'Dr. Shalini');

      final milestone = await babies.getMilestoneById(milestoneId);
      expect(milestone!.achieved, isTrue);
      expect(milestone.completed, DateTime(2026, 5, 2));

      // Un-ticking clears the achievement date.
      await babies.setMilestoneAchieved(milestoneId, achieved: false);
      final reverted = await babies.getMilestoneById(milestoneId);
      expect(reverted!.achieved, isFalse);
      expect(reverted.completed, isNull);
    });
  });

  group('BabyCareScheduler', () {
    test('seeds the full plan anchored on the date of birth', () async {
      final dob = DateTime(2026, 3, 1);
      final babyId = await babies.createBirthRecord(
        BirthRecordsCompanion(dob: Value(dob)),
      );

      final result = await BabyCareScheduler.instance.scheduleFor(
        birthRecordId: babyId,
        dob: dob,
      );

      expect(result.immunizations, babyVaccineSchedule.length);
      expect(result.milestones, babyMilestonePlan.length);

      final doses = await babies.getImmunizations(babyId);
      // Ordered by due date, so the birth doses come first.
      expect(doses.first.expectedDate, dob);
      expect(
        doses.where((d) => d.expectedDate == dob).map((d) => d.vaccineName),
        containsAll(['BCG', 'OPV-0 (Oral Polio, birth dose)']),
      );

      // 6-week doses land exactly 42 days out.
      final sixWeek = doses.firstWhere((d) => d.vaccineName == 'Pentavalent-1');
      expect(sixWeek.expectedDate, dob.add(const Duration(days: 42)));

      // 9-month doses use calendar months, not 30-day blocks.
      final nineMonth = doses.firstWhere(
        (d) => d.vaccineName == 'MR-1 (Measles-Rubella, 1st dose)',
      );
      expect(nineMonth.expectedDate, DateTime(2026, 12, 1));

      final milestones = await babies.getMilestones(babyId);
      expect(milestones.first.milestone, 'Lifts head briefly');
      expect(milestones.every((m) => !m.achieved), isTrue);
    });

    test('re-seeding replaces the plan instead of duplicating it', () async {
      final dob = DateTime(2026, 3, 1);
      final babyId = await babies.createBirthRecord(
        BirthRecordsCompanion(dob: Value(dob)),
      );

      await BabyCareScheduler.instance.scheduleFor(
        birthRecordId: babyId,
        dob: dob,
      );
      await BabyCareScheduler.instance.scheduleFor(
        birthRecordId: babyId,
        dob: dob,
      );

      expect(
        await babies.getImmunizations(babyId),
        hasLength(babyVaccineSchedule.length),
      );
      expect(
        await babies.getMilestones(babyId),
        hasLength(babyMilestonePlan.length),
      );
    });

    test('skipping optional doses keeps only the core NIS schedule', () async {
      final dob = DateTime(2026, 3, 1);
      final babyId = await babies.createBirthRecord(
        BirthRecordsCompanion(dob: Value(dob)),
      );

      final result = await BabyCareScheduler.instance.scheduleFor(
        birthRecordId: babyId,
        dob: dob,
        includeOptional: false,
      );

      final requiredCount =
          babyVaccineSchedule.where((v) => v.required).length;
      expect(result.immunizations, requiredCount);
      expect(requiredCount, lessThan(babyVaccineSchedule.length));

      final doses = await babies.getImmunizations(babyId);
      expect(doses.every((d) => d.required == true), isTrue);
    });
  });

  group('BabyRepository', () {
    test('addBaby creates the record, schedule and health row together',
        () async {
      final id = await repo.addBaby(
        dob: DateTime(2026, 3, 1),
        babyName: 'Meera',
        gender: 'female',
        deliveryType: 'normal',
        weight: 3.05,
        complications: const ['jaundice'],
      );

      final baby = await repo.getBaby(id);
      expect(baby!.babyName, 'Meera');
      expect(baby.pregnancyId, isNull);
      expect(baby.healthId, isNotNull);
      expect(jsonDecode(baby.complications!), ['jaundice']);

      expect(
        await babies.getImmunizations(id),
        hasLength(babyVaccineSchedule.length),
      );
      expect(
        await babies.getMilestones(id),
        hasLength(babyMilestonePlan.length),
      );

      // The mother's kid count is re-derived from the table.
      expect(UserSessionManager.instance.kidsCount, 1);
      expect(UserSessionManager.instance.hasKids, isTrue);
    });

    test('blank names and empty complications are stored as null', () async {
      final id = await repo.addBaby(
        dob: DateTime(2026, 3, 1),
        babyName: '   ',
        gender: '',
        seedSchedule: false,
      );
      final baby = await repo.getBaby(id);
      expect(baby!.babyName, isNull);
      expect(baby.gender, isNull);
      expect(baby.complications, isNull);
    });

    test('a completed pregnancy produces a linked birth record', () async {
      await db.into(db.pregnancies).insert(
            PregnanciesCompanion.insert(
              id: 'preg-1',
              lmpDate: Value(DateTime(2025, 6, 1)),
            ),
          );

      final ids = await repo.recordBirthsForPregnancy(
        pregnancyId: 'preg-1',
        deliveryDate: DateTime(2026, 3, 8),
        gender: 'male',
        deliveryType: 'c-section',
        weight: 2.9,
      );

      expect(ids, hasLength(1));
      final baby = await repo.getBaby(ids.single);
      expect(baby!.pregnancyId, 'preg-1');
      expect(baby.dob, DateTime(2026, 3, 8));
      expect(baby.deliveryType, 'c-section');
      expect(baby.weight, 2.9);

      expect(await repo.babiesForPregnancy('preg-1'), hasLength(1));
    });

    test('a delivery photo is stored on the birth record', () async {
      final ids = await repo.recordBirthsForPregnancy(
        pregnancyId: 'preg-photo',
        deliveryDate: DateTime(2026, 3, 8),
        photo: '/data/user/0/allomom/baby.jpg',
      );
      final baby = await repo.getBaby(ids.single);
      expect(baby!.photo, '/data/user/0/allomom/baby.jpg');
    });

    test('twins both get the delivery photo but no shared weight', () async {
      final ids = await repo.recordBirthsForPregnancy(
        pregnancyId: 'preg-twin-photo',
        deliveryDate: DateTime(2026, 3, 8),
        babyCount: 2,
        weight: 2.4,
        photo: '/data/user/0/allomom/twins.jpg',
      );
      for (final id in ids) {
        final baby = await repo.getBaby(id);
        expect(baby!.photo, '/data/user/0/allomom/twins.jpg');
        expect(baby.weight, isNull);
      }
    });

    test('twins produce two independently scheduled babies', () async {
      final ids = await repo.recordBirthsForPregnancy(
        pregnancyId: 'preg-twins',
        deliveryDate: DateTime(2026, 3, 8),
        babyCount: 2,
        weight: 2.4,
      );

      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2)); // distinct ids
      for (final id in ids) {
        expect(
          await babies.getImmunizations(id),
          hasLength(babyVaccineSchedule.length),
        );
        // Weight is ambiguous for a multiple birth, so it is left blank.
        expect((await repo.getBaby(id))!.weight, isNull);
      }
      expect(UserSessionManager.instance.kidsCount, 2);
    });

    test('deleting a baby lowers the kid count again', () async {
      final first = await repo.addBaby(
        dob: DateTime(2024, 1, 1),
        seedSchedule: false,
      );
      await repo.addBaby(dob: DateTime(2026, 1, 1), seedSchedule: false);
      expect(UserSessionManager.instance.kidsCount, 2);

      await repo.deleteBaby(first);
      expect(UserSessionManager.instance.kidsCount, 1);
      expect(UserSessionManager.instance.hasKids, isTrue);
    });

    test('babies are listed newest first', () async {
      await repo.addBaby(
        dob: DateTime(2020, 5, 4),
        babyName: 'Elder',
        seedSchedule: false,
      );
      await repo.addBaby(
        dob: DateTime(2026, 3, 1),
        babyName: 'Newborn',
        seedSchedule: false,
      );

      final list = await repo.getBabies();
      expect(list.map((b) => b.babyName), ['Newborn', 'Elder']);
    });
  });
}
