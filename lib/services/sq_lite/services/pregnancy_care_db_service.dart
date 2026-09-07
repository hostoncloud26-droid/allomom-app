import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// CRUD for the pregnancy care schedule tables:
/// ANC visits, vaccinations, report checklists and report attachments.
///
/// Every create returns the generated UUID. Any local write resets
/// `synced` to 0 so the sync worker can pick the row up again.
class PregnancyCareDbService {
  static final PregnancyCareDbService instance =
      PregnancyCareDbService._internal();
  PregnancyCareDbService._internal();

  final _uuid = const Uuid();

  // ---------------------- ANC SCHEDULE ----------------------

  Future<String> createAncVisit(PregnancyAncScheduleCompanion visit) async {
    final db = await SqLiteService().database;
    final id = visit.id.present && visit.id.value.isNotEmpty
        ? visit.id.value
        : _uuid.v7();
    await db.into(db.pregnancyAncSchedule).insertOnConflictUpdate(
          visit.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<List<PregnancyAncScheduleData>> getAncVisits(
      String pregnancyId) async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancyAncSchedule)
          ..where((tbl) => tbl.pregnancyId.equals(pregnancyId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  Future<PregnancyAncScheduleData?> getAncVisitById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancyAncSchedule)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<PregnancyAncScheduleData>> watchAncVisits(String pregnancyId) {
    return Stream.fromFuture(SqLiteService().database).asyncExpand((db) {
      return (db.select(db.pregnancyAncSchedule)
            ..where((tbl) => tbl.pregnancyId.equals(pregnancyId))
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
          .watch();
    });
  }

  Future<void> updateAncVisit(PregnancyAncScheduleCompanion visit) async {
    final db = await SqLiteService().database;
    await (db.update(db.pregnancyAncSchedule)
          ..where((tbl) => tbl.id.equals(visit.id.value)))
        .write(visit.copyWith(synced: const Value(0)));
  }

  Future<void> deleteAncVisit(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.pregnancyAncSchedule)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<List<PregnancyAncScheduleData>> unsyncedAncVisits() async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancyAncSchedule)
          ..where((tbl) => tbl.synced.equals(0)))
        .get();
  }

  // ---------------------- CASCADE ----------------------

  /// Removes every schedule row belonging to a pregnancy. Foreign keys are
  /// not enforced by SQLite here, so children are cleared explicitly to
  /// avoid orphan rows when a pregnancy is deleted.
  Future<void> deleteAllForPregnancy(String pregnancyId) async {
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await (db.delete(db.pregnancyAncSchedule)
            ..where((tbl) => tbl.pregnancyId.equals(pregnancyId)))
          .go();
      await (db.delete(db.vaccinations)
            ..where((tbl) => tbl.pregnancyId.equals(pregnancyId)))
          .go();
      await (db.delete(db.reportChecklists)
            ..where((tbl) => tbl.pregnancyId.equals(pregnancyId)))
          .go();
    });
  }

  // ---------------------- VACCINATIONS ----------------------

  Future<String> createVaccination(VaccinationsCompanion vaccination) async {
    final db = await SqLiteService().database;
    final id = vaccination.id.present && vaccination.id.value.isNotEmpty
        ? vaccination.id.value
        : _uuid.v7();
    await db.into(db.vaccinations).insertOnConflictUpdate(
          vaccination.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  /// Vaccinations for a user. Pass [pregnancyId] to narrow to maternal
  /// vaccines tied to that pregnancy.
  Future<List<Vaccination>> getVaccinations(
    String userId, {
    String? pregnancyId,
  }) async {
    final db = await SqLiteService().database;
    final query = db.select(db.vaccinations)
      ..where((tbl) => tbl.userId.equals(userId));
    if (pregnancyId != null) {
      query.where((tbl) => tbl.pregnancyId.equals(pregnancyId));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]);
    return query.get();
  }

  Future<Vaccination?> getVaccinationById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.vaccinations)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateVaccination(VaccinationsCompanion vaccination) async {
    final db = await SqLiteService().database;
    await (db.update(db.vaccinations)
          ..where((tbl) => tbl.id.equals(vaccination.id.value)))
        .write(vaccination.copyWith(synced: const Value(0)));
  }

  Future<void> deleteVaccination(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.vaccinations)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<Vaccination>> unsyncedVaccinations() async {
    final db = await SqLiteService().database;
    return (db.select(db.vaccinations)..where((tbl) => tbl.synced.equals(0)))
        .get();
  }

  // ---------------------- REPORT CHECKLISTS ----------------------

  Future<String> createReportChecklist(
      ReportChecklistsCompanion checklist) async {
    final db = await SqLiteService().database;
    final id = checklist.id.present && checklist.id.value.isNotEmpty
        ? checklist.id.value
        : _uuid.v7();
    await db.into(db.reportChecklists).insertOnConflictUpdate(
          checklist.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<List<ReportChecklist>> getReportChecklists(
    String userId, {
    String? pregnancyId,
  }) async {
    final db = await SqLiteService().database;
    final query = db.select(db.reportChecklists)
      ..where((tbl) => tbl.userId.equals(userId));
    if (pregnancyId != null) {
      query.where((tbl) => tbl.pregnancyId.equals(pregnancyId));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.dueDate)]);
    return query.get();
  }

  Future<ReportChecklist?> getReportChecklistById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.reportChecklists)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateReportChecklist(
      ReportChecklistsCompanion checklist) async {
    final db = await SqLiteService().database;
    await (db.update(db.reportChecklists)
          ..where((tbl) => tbl.id.equals(checklist.id.value)))
        .write(checklist.copyWith(synced: const Value(0)));
  }

  Future<void> deleteReportChecklist(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.reportChecklists)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<List<ReportChecklist>> unsyncedReportChecklists() async {
    final db = await SqLiteService().database;
    return (db.select(db.reportChecklists)
          ..where((tbl) => tbl.synced.equals(0)))
        .get();
  }

  // ---------------------- REPORT ATTACHMENTS ----------------------

  Future<String> createReportAttachment(
      ReportAttachmentsCompanion attachment) async {
    final db = await SqLiteService().database;
    final id = attachment.id.present && attachment.id.value.isNotEmpty
        ? attachment.id.value
        : _uuid.v7();
    await db.into(db.reportAttachments).insertOnConflictUpdate(
          attachment.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<List<ReportAttachment>> getReportAttachments(String reportId) async {
    final db = await SqLiteService().database;
    return (db.select(db.reportAttachments)
          ..where((tbl) => tbl.reportId.equals(reportId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<ReportAttachment?> getReportAttachmentById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.reportAttachments)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateReportAttachment(
      ReportAttachmentsCompanion attachment) async {
    final db = await SqLiteService().database;
    await (db.update(db.reportAttachments)
          ..where((tbl) => tbl.id.equals(attachment.id.value)))
        .write(attachment.copyWith(synced: const Value(0)));
  }

  /// Called once a file finishes uploading, to record its remote copy.
  Future<void> markAttachmentUploaded(String id, String cloudUrl) async {
    await updateReportAttachment(
      ReportAttachmentsCompanion(
        id: Value(id),
        cloudUrl: Value(cloudUrl),
      ),
    );
  }

  Future<void> deleteReportAttachment(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.reportAttachments)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<List<ReportAttachment>> unsyncedReportAttachments() async {
    final db = await SqLiteService().database;
    return (db.select(db.reportAttachments)
          ..where((tbl) => tbl.synced.equals(0)))
        .get();
  }
}
