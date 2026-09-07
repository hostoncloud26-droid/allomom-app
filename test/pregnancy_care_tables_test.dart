import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';

/// Exercises the v3 pregnancy-care tables end to end against an in-memory
/// database: schema creation, CRUD, the sync flag and the FK wiring to the
/// existing `pregnancies` / `reports` tables.
void main() {
  late AppDriftDatabase db;

  setUp(() {
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<String> insertPregnancy() async {
    const id = 'preg-1';
    await db.into(db.pregnancies).insert(PregnanciesCompanion.insert(
          id: id,
          lmpDate: Value(DateTime(2026, 1, 10)),
          edDate: Value(DateTime(2026, 10, 17)),
          gravidity: const Value(2),
          parity: const Value(1),
        ));
    return id;
  }

  test('all v3 tables are created', () async {
    final names = db.allTables.map((t) => t.actualTableName).toList();
    expect(
      names,
      containsAll([
        'pregnancy_anc_schedule',
        'vaccinations',
        'report_checklists',
        'report_attachments',
      ]),
    );
    // Forces the schema to actually be built, not just declared.
    await db.customSelect('SELECT COUNT(*) FROM pregnancy_anc_schedule').get();
    await db.customSelect('SELECT COUNT(*) FROM vaccinations').get();
    await db.customSelect('SELECT COUNT(*) FROM report_checklists').get();
    await db.customSelect('SELECT COUNT(*) FROM report_attachments').get();
  });

  test('ANC visit CRUD round-trips and defaults are applied', () async {
    final pregnancyId = await insertPregnancy();

    await db.into(db.pregnancyAncSchedule).insert(
          PregnancyAncScheduleCompanion.insert(
            id: 'anc-1',
            pregnancyId: Value(pregnancyId),
            visitNumber: const Value(1),
            trimester: const Value(1),
            scheduledDate: DateTime(2026, 3, 1),
            bp: const Value('118/76'),
            weightKg: const Value(62.8),
          ),
        );

    var visit = await (db.select(db.pregnancyAncSchedule)
          ..where((t) => t.id.equals('anc-1')))
        .getSingle();
    expect(visit.pregnancyId, pregnancyId);
    expect(visit.status, 'pending'); // column default
    expect(visit.synced, 0); // column default
    expect(visit.bp, '118/76');
    expect(visit.weightKg, 62.8);
    expect(visit.actualDate, isNull);

    // UPDATE
    await (db.update(db.pregnancyAncSchedule)
          ..where((t) => t.id.equals('anc-1')))
        .write(PregnancyAncScheduleCompanion(
      status: const Value('done'),
      actualDate: Value(DateTime(2026, 3, 2)),
      fetalHeartRate: const Value(152),
    ));

    visit = await (db.select(db.pregnancyAncSchedule)
          ..where((t) => t.id.equals('anc-1')))
        .getSingle();
    expect(visit.status, 'done');
    expect(visit.actualDate, DateTime(2026, 3, 2));
    expect(visit.fetalHeartRate, 152);

    // DELETE
    await (db.delete(db.pregnancyAncSchedule)
          ..where((t) => t.id.equals('anc-1')))
        .go();
    expect(await db.select(db.pregnancyAncSchedule).get(), isEmpty);
  });

  test('vaccinations support both maternal and general scope', () async {
    final pregnancyId = await insertPregnancy();

    await db.into(db.vaccinations).insert(VaccinationsCompanion.insert(
          id: 'vac-maternal',
          userId: const Value('user-1'),
          pregnancyId: Value(pregnancyId),
          vaccineName: 'Tdap',
          scheduledDate: DateTime(2026, 6, 1),
        ));
    await db.into(db.vaccinations).insert(VaccinationsCompanion.insert(
          id: 'vac-general',
          userId: const Value('user-1'),
          vaccineName: 'BCG',
          scheduledDate: DateTime(2026, 11, 1),
        ));

    final all = await (db.select(db.vaccinations)
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
    expect(all.map((v) => v.vaccineName), ['Tdap', 'BCG']);
    expect(all.first.doseNumber, 1); // column default
    expect(all.first.pregnancyId, pregnancyId);
    expect(all.last.pregnancyId, isNull); // general vaccine

    final maternalOnly = await (db.select(db.vaccinations)
          ..where((t) => t.pregnancyId.equals(pregnancyId)))
        .get();
    expect(maternalOnly, hasLength(1));
  });

  test('report checklist CRUD round-trips', () async {
    await db.into(db.reportChecklists).insert(
          ReportChecklistsCompanion.insert(
            id: 'chk-1',
            userId: const Value('user-1'),
            reportName: 'CBC',
            category: const Value('blood'),
            dueDate: Value(DateTime(2026, 4, 1)),
          ),
        );

    var item = await (db.select(db.reportChecklists)
          ..where((t) => t.id.equals('chk-1')))
        .getSingle();
    expect(item.reportName, 'CBC');
    expect(item.status, 'pending');
    expect(item.completedDate, isNull);

    await (db.update(db.reportChecklists)..where((t) => t.id.equals('chk-1')))
        .write(ReportChecklistsCompanion(
      status: const Value('done'),
      completedDate: Value(DateTime(2026, 4, 3)),
      resultSummary: const Value('Hb 11.2 g/dL'),
    ));

    item = await (db.select(db.reportChecklists)
          ..where((t) => t.id.equals('chk-1')))
        .getSingle();
    expect(item.status, 'done');
    expect(item.resultSummary, 'Hb 11.2 g/dL');

    await (db.delete(db.reportChecklists)..where((t) => t.id.equals('chk-1')))
        .go();
    expect(await db.select(db.reportChecklists).get(), isEmpty);
  });

  test('report attachment starts local-only then records its cloud copy',
      () async {
    await db.into(db.reports).insert(ReportsCompanion.insert(
          id: 'rep-1',
          reportType: 'Lab Report',
        ));

    await db.into(db.reportAttachments).insert(
          ReportAttachmentsCompanion.insert(
            id: 'att-1',
            reportId: const Value('rep-1'),
            localPath: '/data/user/0/allomom/cbc.pdf',
            fileName: const Value('cbc.pdf'),
            mimeType: const Value('application/pdf'),
            fileSizeBytes: const Value(48213),
          ),
        );

    var attachment = await (db.select(db.reportAttachments)
          ..where((t) => t.id.equals('att-1')))
        .getSingle();
    expect(attachment.reportId, 'rep-1');
    expect(attachment.localPath, '/data/user/0/allomom/cbc.pdf');
    expect(attachment.cloudUrl, isNull); // not uploaded yet
    expect(attachment.synced, 0);

    await (db.update(db.reportAttachments)..where((t) => t.id.equals('att-1')))
        .write(const ReportAttachmentsCompanion(
      cloudUrl: Value('https://cdn.example.com/att-1'),
    ));

    attachment = await (db.select(db.reportAttachments)
          ..where((t) => t.id.equals('att-1')))
        .getSingle();
    expect(attachment.cloudUrl, 'https://cdn.example.com/att-1');
  });

  test('unsynced queries pick up locally written rows', () async {
    final pregnancyId = await insertPregnancy();
    await db.into(db.pregnancyAncSchedule).insert(
          PregnancyAncScheduleCompanion.insert(
            id: 'anc-unsynced',
            pregnancyId: Value(pregnancyId),
            scheduledDate: DateTime(2026, 5, 1),
          ),
        );
    await db.into(db.pregnancyAncSchedule).insert(
          PregnancyAncScheduleCompanion.insert(
            id: 'anc-synced',
            pregnancyId: Value(pregnancyId),
            scheduledDate: DateTime(2026, 5, 2),
            synced: const Value(1),
          ),
        );

    final pending = await (db.select(db.pregnancyAncSchedule)
          ..where((t) => t.synced.equals(0)))
        .get();
    expect(pending.map((v) => v.id), ['anc-unsynced']);
  });

  test('existing pregnancies / reports columns are untouched', () async {
    // The three pre-existing tables were deliberately left alone, so the
    // columns the app already reads must still be there.
    final pregnancyId = await insertPregnancy();
    final pregnancy = await (db.select(db.pregnancies)
          ..where((t) => t.id.equals(pregnancyId)))
        .getSingle();
    expect(pregnancy.edDate, DateTime(2026, 10, 17));
    expect(pregnancy.gravidity, 2);
    expect(pregnancy.parity, 1);
    expect(pregnancy.status, 'active');
    expect(pregnancy.riskStatus, isNull);

    await db.into(db.reports).insert(ReportsCompanion.insert(
          id: 'rep-legacy',
          reportType: 'Ultrasound',
          detail: const Value('{"weeks":20}'),
          imageUrl: const Value('https://example.com/scan.png'),
        ));
    final report = await (db.select(db.reports)
          ..where((t) => t.id.equals('rep-legacy')))
        .getSingle();
    expect(report.reportType, 'Ultrasound');
    expect(report.detail, '{"weeks":20}');
    expect(report.imageUrl, 'https://example.com/scan.png');
  });
}
