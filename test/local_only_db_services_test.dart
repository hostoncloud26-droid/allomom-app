import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/services/sq_lite/services/family_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/prescription_db_service.dart';
import 'package:allomom/services/sq_lite/services/reminder_db_service.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';

/// Covers the domain services that replaced the allomom-api calls. Every
/// assertion checks both that the data round-trips locally and that the row
/// is left at `synced = 0`, which is what the (future) sync worker keys off.
void main() {
  late AppDriftDatabase db;

  setUp(() {
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });

  Future<String> insertUser({String id = 'usr-1'}) async {
    await db.into(db.users).insert(UsersCompanion.insert(
          id: id,
          name: const Value('Meera'),
          phone: const Value('+919000000000'),
        ));
    return id;
  }

  group('reminders', () {
    test('create / read / toggle / delete round-trips unsynced', () async {
      final userId = await insertUser();

      final id = await ReminderDbService.instance.createReminder(
        userId: userId,
        title: 'Drink water',
        hour: 9,
        minute: 30,
      );

      var reminders = await ReminderDbService.instance.getReminders(userId);
      expect(reminders, hasLength(1));
      expect(reminders.single.title, 'Drink water');
      expect(reminders.single.hour, 9);
      expect(reminders.single.enabled, isTrue);
      expect(reminders.single.synced, 0);

      await ReminderDbService.instance.setEnabled(id, false);
      reminders = await ReminderDbService.instance.getReminders(userId);
      expect(reminders.single.enabled, isFalse);
      expect(reminders.single.synced, 0);

      expect(await ReminderDbService.instance.unsyncedReminders(), hasLength(1));

      await ReminderDbService.instance.deleteReminder(id);
      expect(await ReminderDbService.instance.getReminders(userId), isEmpty);
    });

    test('reminders are scoped to their user', () async {
      final a = await insertUser(id: 'usr-a');
      final b = await insertUser(id: 'usr-b');

      await ReminderDbService.instance.createReminder(userId: a, title: 'A');
      await ReminderDbService.instance.createReminder(userId: b, title: 'B');

      final forA = await ReminderDbService.instance.getReminders(a);
      expect(forA.map((r) => r.title), ['A']);
    });
  });

  group('family', () {
    test('createFamily enrolls the creator and mints a 6-char code', () async {
      final userId = await insertUser();

      final family = await FamilyDbService.instance
          .createFamily(creatorUserId: userId, name: "Meera's Family");

      expect(family.name, "Meera's Family");
      expect(family.code, hasLength(6));
      expect(family.motherId, userId);
      expect(family.synced, 0);

      final members =
          await FamilyDbService.instance.getFamilyMembers(family.id);
      expect(members, hasLength(1));
      expect(members.single.userId, userId);
      expect(members.single.accessLevel, ['owner']);

      // The creator's user row now points at the family.
      expect(await FamilyDbService.instance.getMyFamily(userId),
          isA<Family>().having((f) => f.id, 'id', family.id));
    });

    test('createFamilyMember stores the member and their pregnancy dates',
        () async {
      final userId = await insertUser();
      final family =
          await FamilyDbService.instance.createFamily(creatorUserId: userId);

      final lmp = DateTime(2026, 3, 1);
      final memberId = await FamilyDbService.instance.createFamilyMember(
        familyId: family.id,
        name: 'Anand',
        phone: '+919111111111',
        relation: 'Father',
        gender: 'Male',
        age: 32,
        lmpDate: lmp,
      );

      final members =
          await FamilyDbService.instance.getFamilyMembers(family.id);
      expect(members, hasLength(2));

      final member = members.firstWhere((m) => m.userId == memberId);
      expect(member.name, 'Anand');
      expect(member.relation, 'Father');
      expect(member.phone, '+919111111111');
      expect(member.member.synced, 0);

      final memberUser = member.user!;
      expect(memberUser.gender, 'Male');
      expect(memberUser.dob?.year, DateTime.now().year - 32);
      expect(memberUser.synced, 0);

      // lmpDate given -> a health-data row was created for the member.
      final health = await HealthDbService.instance
          .getHealthDataByUserId(memberId);
      expect(health, isNotNull);
      expect(health!.lmpDate, lmp);
      expect(health.edDate, lmp.add(const Duration(days: 280)));
      expect(health.pregnancyStatus, 'pregnant');
      expect(health.synced, 0);
    });

    test('joinFamilyByCode matches a local family and is idempotent',
        () async {
      final owner = await insertUser(id: 'usr-owner');
      final joiner = await insertUser(id: 'usr-joiner');
      final family =
          await FamilyDbService.instance.createFamily(creatorUserId: owner);

      final joined = await FamilyDbService.instance
          .joinFamilyByCode(code: family.code!, userId: joiner);
      expect(joined?.id, family.id);

      // Joining twice must not duplicate the membership row.
      await FamilyDbService.instance
          .joinFamilyByCode(code: family.code!, userId: joiner);
      final members =
          await FamilyDbService.instance.getFamilyMembers(family.id);
      expect(members.where((m) => m.userId == joiner), hasLength(1));

      expect(
        await FamilyDbService.instance
            .joinFamilyByCode(code: 'ZZZZZZ', userId: joiner),
        isNull,
      );
    });

    test('removeFamilyMember unlinks and soft-deletes the member', () async {
      final owner = await insertUser(id: 'usr-owner');
      final family =
          await FamilyDbService.instance.createFamily(creatorUserId: owner);
      final memberId = await FamilyDbService.instance
          .createFamilyMember(familyId: family.id, name: 'Anand');

      await FamilyDbService.instance
          .removeFamilyMember(familyId: family.id, userId: memberId);

      final members =
          await FamilyDbService.instance.getFamilyMembers(family.id);
      expect(members.where((m) => m.userId == memberId), isEmpty);

      final row = await (db.select(db.users)
            ..where((t) => t.id.equals(memberId)))
          .getSingle();
      expect(row.isDeleted, isTrue);
      expect(row.familyID, isNull);
    });
  });

  group('prescriptions', () {
    Future<({String prescriptionId, String medicineId})> seed() async {
      final medicineId = 'med-1';
      final prescriptionId = await PrescriptionDbService.instance
          .savePrescription(
        PrescriptionsCompanion.insert(
          id: 'presc-1',
          healthId: const Value('hd-1'),
          description: 'Antenatal supplements',
        ),
        [
          PrescriptionMedicinesCompanion.insert(
            id: medicineId,
            medicineName: 'Iron + Folic Acid',
            dosage: '1 Tablet',
            timings: '["08:30","20:00"]',
            durationDays: 2,
            healthId: const Value('hd-1'),
            userId: const Value('usr-1'),
          ),
        ],
      );
      return (prescriptionId: prescriptionId, medicineId: medicineId);
    }

    test('savePrescription writes prescription + medicines unsynced',
        () async {
      final ids = await seed();

      final stored = await PrescriptionDbService.instance
          .getPrescriptionById(ids.prescriptionId);
      expect(stored, isNotNull);
      expect(stored!.description, 'Antenatal supplements');
      expect(stored.synced, 0);

      final meds = await PrescriptionDbService.instance
          .getMedicinesForPrescription(ids.prescriptionId);
      expect(meds, hasLength(1));
      expect(meds.single.prescriptionId, ids.prescriptionId);
      expect(meds.single.synced, 0);
      expect(decodeMedicineTimings(meds.single.timings), ['08:30', '20:00']);
    });

    test('decodeMedicineTimings accepts JSON and legacy comma strings', () {
      expect(decodeMedicineTimings('["08:30","20:00"]'), ['08:30', '20:00']);
      expect(decodeMedicineTimings('08:30,20:00'), ['08:30', '20:00']);
      expect(decodeMedicineTimings(''), isEmpty);
      expect(decodeMedicineTimings(null), isEmpty);
    });

    test('getTimingsInRange returns only the requested day, joined',
        () async {
      final ids = await seed();

      final today = DateTime(2026, 4, 10, 8, 30);
      final tomorrow = DateTime(2026, 4, 11, 8, 30);
      await PrescriptionDbService.instance.logMedicineTiming(
        PrescriptionMedicineTimingsCompanion(
          prescriptionMedicineId: Value(ids.medicineId),
          timingDateTime: Value(today),
          status: const Value('pending'),
        ),
      );
      await PrescriptionDbService.instance.logMedicineTiming(
        PrescriptionMedicineTimingsCompanion(
          prescriptionMedicineId: Value(ids.medicineId),
          timingDateTime: Value(tomorrow),
          status: const Value('pending'),
        ),
      );

      final forToday = await PrescriptionDbService.instance.getTimingsInRange(
        from: DateTime(2026, 4, 10),
        to: DateTime(2026, 4, 10, 23, 59, 59),
        userId: 'usr-1',
      );

      expect(forToday, hasLength(1));
      expect(forToday.single.dateTime, today);
      expect(forToday.single.medicineName, 'Iron + Folic Acid');
      expect(forToday.single.dosage, '1 Tablet');
      expect(forToday.single.prescription?.id, ids.prescriptionId);
      expect(forToday.single.isTaken, isFalse);

      // A different user's medicines are not returned.
      expect(
        await PrescriptionDbService.instance.getTimingsInRange(
          from: DateTime(2026, 4, 10),
          to: DateTime(2026, 4, 10, 23, 59, 59),
          userId: 'someone-else',
        ),
        isEmpty,
      );
    });

    test('markTimingTaken and snoozeTiming update the row unsynced', () async {
      final ids = await seed();
      final scheduled = DateTime(2026, 4, 10, 8, 30);
      final timingId = await PrescriptionDbService.instance.logMedicineTiming(
        PrescriptionMedicineTimingsCompanion(
          prescriptionMedicineId: Value(ids.medicineId),
          timingDateTime: Value(scheduled),
          status: const Value('pending'),
        ),
      );

      final takenAt = DateTime(2026, 4, 10, 8, 45);
      await PrescriptionDbService.instance
          .markTimingTaken(timingId, takenAt: takenAt);

      var detail =
          await PrescriptionDbService.instance.getTimingDetail(timingId);
      expect(detail!.status, 'taken');
      expect(detail.isTaken, isTrue);
      expect(detail.timing.medicineTakenTime, takenAt);
      expect(detail.timing.synced, 0);

      expect(await PrescriptionDbService.instance.snoozeTiming(timingId, 15),
          isTrue);
      detail = await PrescriptionDbService.instance.getTimingDetail(timingId);
      expect(detail!.dateTime, scheduled.add(const Duration(minutes: 15)));
      expect(detail.status, 'pending');
      expect(detail.timing.synced, 0);

      // Missing rows report failure rather than throwing.
      expect(await PrescriptionDbService.instance.snoozeTiming('nope', 15),
          isFalse);
      expect(
          await PrescriptionDbService.instance.getTimingDetail('nope'), isNull);
    });

    test('deletePrescription cascades to medicines and timings', () async {
      final ids = await seed();
      await PrescriptionDbService.instance.logMedicineTiming(
        PrescriptionMedicineTimingsCompanion(
          prescriptionMedicineId: Value(ids.medicineId),
          timingDateTime: Value(DateTime(2026, 4, 10, 8, 30)),
          status: const Value('pending'),
        ),
      );

      await PrescriptionDbService.instance
          .deletePrescription(ids.prescriptionId);

      expect(
          await PrescriptionDbService.instance
              .getPrescriptionById(ids.prescriptionId),
          isNull);
      expect(await db.select(db.prescriptionMedicines).get(), isEmpty);
      expect(await db.select(db.prescriptionMedicineTimings).get(), isEmpty);
    });
  });

  group('reports', () {
    Future<String> addReport(String type, {String healthId = 'hd-1'}) {
      return ReportDbService.instance.saveReport(
        ReportsCompanion(
          reportType: Value(type),
          healthDataID: Value(healthId),
          detail: const Value('{"ocr_summary":"Hb 11.2 g/dL"}'),
          description: const Value('Routine bloodwork'),
        ),
      );
    }

    test('saveReport mints an id and leaves the row unsynced', () async {
      final id = await addReport('Blood Test');
      expect(id, isNotEmpty);

      final stored = await ReportDbService.instance.getReportById(id);
      expect(stored, isNotNull);
      expect(stored!.reportType, 'Blood Test');
      expect(stored.synced, 0);
      expect(ReportDbService.decodeDetail(stored)['ocr_summary'],
          'Hb 11.2 g/dL');
    });

    test('decodeDetail tolerates a missing or malformed payload', () async {
      final id = await ReportDbService.instance.saveReport(
        ReportsCompanion(
          reportType: const Value('MRI'),
          healthDataID: const Value('hd-1'),
          detail: const Value('not json'),
        ),
      );
      final stored = await ReportDbService.instance.getReportById(id);
      expect(ReportDbService.decodeDetail(stored!), isEmpty);
    });

    test('getReports paginates and stays scoped to the health id', () async {
      for (var i = 0; i < 3; i++) {
        await addReport('Blood Test');
      }
      await addReport('MRI', healthId: 'hd-other');

      final firstPage =
          await ReportDbService.instance.getReports('hd-1', limit: 2);
      expect(firstPage, hasLength(2));

      final secondPage = await ReportDbService.instance
          .getReports('hd-1', limit: 2, offset: 2);
      expect(secondPage, hasLength(1));

      expect(await ReportDbService.instance.getReports('hd-other'),
          hasLength(1));
    });

    test('getReportsSummary counts by type', () async {
      await addReport('Blood Test');
      await addReport('Blood Test');
      await addReport('Ultrasound Scan');

      final summary =
          await ReportDbService.instance.getReportsSummary('hd-1');
      expect(summary.total, 3);
      expect(summary.countsByType['Blood Test'], 2);
      expect(summary.countsByType['Ultrasound Scan'], 1);
      expect(summary.latestByType.keys,
          containsAll(['Blood Test', 'Ultrasound Scan']));
      expect(summary.latest, isNotNull);
    });

    test('deleteReport cascades to its attachments', () async {
      final id = await addReport('Blood Test');
      await db.into(db.reportAttachments).insert(
            ReportAttachmentsCompanion.insert(
              id: 'att-1',
              reportId: Value(id),
              localPath: '/tmp/report.pdf',
            ),
          );

      await ReportDbService.instance.deleteReport(id);

      expect(await ReportDbService.instance.getReportById(id), isNull);
      expect(await db.select(db.reportAttachments).get(), isEmpty);
    });
  });

  group('pregnancy', () {
    test('savePregnancy / completePregnancy keep rows unsynced', () async {
      await HealthDbService.instance.saveHealthData(
        HealthDataTableCompanion.insert(
          id: 'hd-1',
          userId: const Value('usr-1'),
          pregnancyStatus: const Value('pregnant'),
          synced: const Value(1), // must be forced back to 0 on write
        ),
      );
      final health = await HealthDbService.instance.getHealthDataById('hd-1');
      expect(health!.synced, 0);

      await HealthDbService.instance.savePregnancy(
        PregnanciesCompanion.insert(
          id: 'preg-1',
          healthId: const Value('hd-1'),
          lmpDate: Value(DateTime(2026, 1, 10)),
          edDate: Value(DateTime(2026, 10, 17)),
          synced: const Value(1),
        ),
      );

      final active = await HealthDbService.instance.getActivePregnancy('hd-1');
      expect(active, isNotNull);
      expect(active!.id, 'preg-1');
      expect(active.synced, 0);

      final delivered = DateTime(2026, 10, 14);
      await HealthDbService.instance.completePregnancy(
        'preg-1',
        deliveryDate: delivered,
        deliveryConductedAt: 'Savemom Hospital',
      );

      expect(await HealthDbService.instance.getActivePregnancy('hd-1'), isNull);

      final completed =
          await HealthDbService.instance.getCompletedPregnancies('hd-1');
      expect(completed, hasLength(1));
      expect(completed.single.status, 'completed');
      expect(completed.single.deliveryDate, delivered);
      expect(completed.single.deliveryConductedAt, 'Savemom Hospital');
      expect(completed.single.synced, 0);

      expect(await HealthDbService.instance.unsyncedPregnancies(),
          hasLength(1));
    });
  });
}
