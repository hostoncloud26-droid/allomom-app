import 'package:drift/drift.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Local reads and writes for the three pregnancy schedules.
///
/// Rows come from the server, which seeds them when a pregnancy is created, so
/// this is a query surface rather than a source of truth. Writes mark the row
/// `synced = 0` and leave the push to [SyncService]; [PregnancyController] is
/// the usual entry point and calls through here.
class PregnancyCareDbService {
  static final PregnancyCareDbService _instance =
      PregnancyCareDbService._internal();
  factory PregnancyCareDbService() => _instance;
  PregnancyCareDbService._internal();

  static PregnancyCareDbService get instance => _instance;

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── ANC checkups ───────────────────────────────────────────────────────────

  Future<String> createAncVisit(AncCheckupDatesCompanion visit) async {
    final db = await _db;
    await db.into(db.ancCheckupDates).insertOnConflictUpdate(visit);
    return visit.id.value;
  }

  Future<List<AncCheckupDate>> getAncVisits(String pregnancyId) async {
    final db = await _db;
    return (db.select(db.ancCheckupDates)
          ..where((a) => a.pregnancyId.equals(pregnancyId) & a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.month)]))
        .get();
  }

  Future<AncCheckupDate?> getAncVisitById(String id) async {
    final db = await _db;
    return (db.select(db.ancCheckupDates)
          ..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<AncCheckupDate>> watchAncVisits(String pregnancyId) async* {
    final db = await _db;
    yield* (db.select(db.ancCheckupDates)
          ..where((a) => a.pregnancyId.equals(pregnancyId) & a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.month)]))
        .watch();
  }

  Future<void> updateAncVisit(AncCheckupDatesCompanion visit) async {
    final db = await _db;
    await (db.update(db.ancCheckupDates)
          ..where((a) => a.id.equals(visit.id.value)))
        .write(visit.copyWith(synced: const Value(0)));
  }

  /// Soft delete, so the removal itself can be synced. A hard delete would
  /// simply be re-pulled from the server on the next pass.
  Future<void> deleteAncVisit(String id) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.ancCheckupDates)..where((a) => a.id.equals(id))).write(
      AncCheckupDatesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(0),
      ),
    );
  }

  Future<List<AncCheckupDate>> unsyncedAncVisits() async {
    final db = await _db;
    return (db.select(db.ancCheckupDates)..where((a) => a.synced.equals(0)))
        .get();
  }

  // ── Vaccinations ───────────────────────────────────────────────────────────

  Future<String> createVaccination(
    PregnancyImmunizationRecordsCompanion vaccination,
  ) async {
    final db = await _db;
    await db
        .into(db.pregnancyImmunizationRecords)
        .insertOnConflictUpdate(vaccination);
    return vaccination.id.value;
  }

  Future<List<PregnancyImmunizationRecord>> getVaccinations(
    String pregnancyId,
  ) async {
    final db = await _db;
    return (db.select(db.pregnancyImmunizationRecords)
          ..where((v) => v.pregnancyId.equals(pregnancyId) & v.deletedAt.isNull())
          ..orderBy([(v) => OrderingTerm.asc(v.scheduledDate)]))
        .get();
  }

  Future<PregnancyImmunizationRecord?> getVaccinationById(String id) async {
    final db = await _db;
    return (db.select(db.pregnancyImmunizationRecords)
          ..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateVaccination(
    PregnancyImmunizationRecordsCompanion vaccination,
  ) async {
    final db = await _db;
    await (db.update(db.pregnancyImmunizationRecords)
          ..where((v) => v.id.equals(vaccination.id.value)))
        .write(vaccination.copyWith(synced: const Value(0)));
  }

  Future<void> deleteVaccination(String id) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.pregnancyImmunizationRecords)
          ..where((v) => v.id.equals(id)))
        .write(
          PregnancyImmunizationRecordsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            synced: const Value(0),
          ),
        );
  }

  Future<List<PregnancyImmunizationRecord>> unsyncedVaccinations() async {
    final db = await _db;
    return (db.select(db.pregnancyImmunizationRecords)
          ..where((v) => v.synced.equals(0)))
        .get();
  }

  // ── Report checklist ───────────────────────────────────────────────────────

  Future<String> createReportChecklist(
    PregnancyReportChecklistsCompanion checklist,
  ) async {
    final db = await _db;
    await db
        .into(db.pregnancyReportChecklists)
        .insertOnConflictUpdate(checklist);
    return checklist.id.value;
  }

  Future<List<PregnancyReportChecklist>> getReportChecklists(
    String pregnancyId,
  ) async {
    final db = await _db;
    return (db.select(db.pregnancyReportChecklists)
          ..where((r) => r.pregnancyId.equals(pregnancyId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.asc(r.expectedDate)]))
        .get();
  }

  Future<PregnancyReportChecklist?> getReportChecklistById(String id) async {
    final db = await _db;
    return (db.select(db.pregnancyReportChecklists)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateReportChecklist(
    PregnancyReportChecklistsCompanion checklist,
  ) async {
    final db = await _db;
    await (db.update(db.pregnancyReportChecklists)
          ..where((r) => r.id.equals(checklist.id.value)))
        .write(checklist.copyWith(synced: const Value(0)));
  }

  Future<void> deleteReportChecklist(String id) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.pregnancyReportChecklists)..where((r) => r.id.equals(id)))
        .write(
          PregnancyReportChecklistsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            synced: const Value(0),
          ),
        );
  }

  Future<List<PregnancyReportChecklist>> unsyncedReportChecklists() async {
    final db = await _db;
    return (db.select(db.pregnancyReportChecklists)
          ..where((r) => r.synced.equals(0)))
        .get();
  }

  Future<void> deleteAllForPregnancy(String pregnancyId) async {
    final db = await _db;
    await db.transaction(() async {
      await (db.delete(db.ancCheckupDates)
            ..where((a) => a.pregnancyId.equals(pregnancyId)))
          .go();
      await (db.delete(db.pregnancyImmunizationRecords)
            ..where((v) => v.pregnancyId.equals(pregnancyId)))
          .go();
      await (db.delete(db.pregnancyReportChecklists)
            ..where((r) => r.pregnancyId.equals(pregnancyId)))
          .go();
    });
  }

  // ── Report attachments (app-local, no server counterpart yet) ──────────────

  Future<String> createReportAttachment(
    ReportAttachmentsCompanion attachment,
  ) async {
    final db = await _db;
    await db.into(db.reportAttachments).insertOnConflictUpdate(attachment);
    return attachment.id.value;
  }

  Future<List<ReportAttachment>> getReportAttachments(String reportId) async {
    final db = await _db;
    return (db.select(db.reportAttachments)
          ..where((a) => a.reportId.equals(reportId)))
        .get();
  }

  Future<ReportAttachment?> getReportAttachmentById(String id) async {
    final db = await _db;
    return (db.select(db.reportAttachments)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateReportAttachment(
    ReportAttachmentsCompanion attachment,
  ) async {
    final db = await _db;
    await (db.update(db.reportAttachments)
          ..where((a) => a.id.equals(attachment.id.value)))
        .write(attachment);
  }

  Future<void> deleteReportAttachment(String id) async {
    final db = await _db;
    await (db.delete(db.reportAttachments)..where((a) => a.id.equals(id))).go();
  }
}
