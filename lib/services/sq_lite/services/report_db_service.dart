import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// CRUD for medical reports, their files, and the AI-parsed detail payload.
///
/// The device is the source of truth. A report is saved here the moment the
/// user taps save — with no account, no Drive and no network — and every write
/// resets `synced` to 0. [ReportsDriveController] is what later pushes those
/// rows to `/me/reports` and their files to the user's Drive; the writes that
/// come back from that sync go through [upsertFromServer], which is the only
/// path that marks a row clean.
class ReportDbService {
  static final ReportDbService instance = ReportDbService._internal();
  ReportDbService._internal();

  final _uuid = const Uuid();

  /// The `healthDataID` reports are filed under on this device.
  ///
  /// The real health record id once the profile has been seeded; the user id,
  /// or a fixed placeholder, before that. Every caller — the list, the add
  /// screen, the sync — has to agree on this or reports are written under one
  /// scope and read under another, so it lives here rather than being spelled
  /// out at each site.
  static String localHealthScope({
    required String healthDataId,
    required String userId,
  }) {
    if (healthDataId.isNotEmpty) return healthDataId;
    if (userId.isNotEmpty) return userId;
    return 'health_me';
  }

  Future<List<Report>> getReports(
    String healthDataId, {
    int? limit,
    int offset = 0,
  }) async {
    final db = await SqLiteService().database;
    final query = db.select(db.reports)
      ..where((tbl) => tbl.healthDataID.equals(healthDataId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Future<List<Report>> getAllReports({int? limit, int offset = 0}) async {
    final db = await SqLiteService().database;
    final query = db.select(db.reports)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Future<Report?> getReportById(String reportId) async {
    final db = await SqLiteService().database;
    return (db.select(db.reports)..where((tbl) => tbl.id.equals(reportId)))
        .getSingleOrNull();
  }

  /// Inserts or updates a report. Returns the id, generating one when absent.
  Future<String> saveReport(ReportsCompanion report) async {
    final db = await SqLiteService().database;
    final id = report.id.present && report.id.value.isNotEmpty
        ? report.id.value
        : _uuid.v4();
    await db.into(db.reports).insertOnConflictUpdate(
          report.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<void> updateReport(ReportsCompanion report) async {
    final db = await SqLiteService().database;
    await (db.update(db.reports)..where((tbl) => tbl.id.equals(report.id.value)))
        .write(report.copyWith(synced: const Value(0)));
  }

  /// Deletes a report and the attachment rows that hang off it.
  Future<void> deleteReport(String reportId) async {
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await (db.delete(db.reportAttachments)
            ..where((tbl) => tbl.reportId.equals(reportId)))
          .go();
      await (db.delete(db.reports)..where((tbl) => tbl.id.equals(reportId)))
          .go();
    });
  }

  /// Report counts by type, plus the newest report per type — the local
  /// equivalent of the old `GET /reports/summary`.
  Future<ReportsSummary> getReportsSummary(String healthDataId) async {
    final reports = await getReports(healthDataId);

    final countsByType = <String, int>{};
    final latestByType = <String, Report>{};
    for (final report in reports) {
      final type = report.reportType;
      countsByType[type] = (countsByType[type] ?? 0) + 1;
      final current = latestByType[type];
      if (current == null || report.createdAt.isAfter(current.createdAt)) {
        latestByType[type] = report;
      }
    }

    return ReportsSummary(
      total: reports.length,
      countsByType: countsByType,
      latestByType: latestByType,
      latest: reports.isEmpty ? null : reports.first,
    );
  }

  Future<List<Report>> unsyncedReports() async {
    final db = await SqLiteService().database;
    return (db.select(db.reports)..where((t) => t.synced.equals(0))).get();
  }

  // ── Sync ───────────────────────────────────────────────────────────────────

  /// Marks rows clean after the server has accepted them.
  ///
  /// Deliberately not routed through [updateReport], which forces `synced` back
  /// to 0 — that is right for a user edit and exactly wrong here.
  Future<void> markReportsSynced(Iterable<String> reportIds) async {
    final ids = reportIds.toList();
    if (ids.isEmpty) return;
    final db = await SqLiteService().database;
    await (db.update(db.reports)..where((t) => t.id.isIn(ids)))
        .write(const ReportsCompanion(synced: Value(1)));
  }

  /// Writes a report the server sent us, clean.
  ///
  /// `imageUrl` and the `detail.files` list are left alone when the incoming
  /// report has nothing to put there: the server strips local file paths, so
  /// overwriting them would blank out the on-device copies of a report this
  /// phone scanned itself.
  Future<void> upsertFromServer({
    required String id,
    required String healthScope,
    required String reportType,
    String? description,
    String? detailJson,
    String? createdBy,
    DateTime? createdAt,
  }) async {
    final db = await SqLiteService().database;
    final existing = await getReportById(id);

    await db.into(db.reports).insertOnConflictUpdate(
          ReportsCompanion(
            id: Value(id),
            reportType: Value(reportType),
            description: Value(description ?? existing?.description),
            detail: Value(detailJson ?? existing?.detail),
            healthDataID: Value(healthScope),
            imageUrl: Value(existing?.imageUrl),
            driveFileId: Value(existing?.driveFileId),
            createdBy: Value(createdBy ?? existing?.createdBy),
            createdAt: Value(createdAt ?? existing?.createdAt ?? DateTime.now()),
            saved: const Value(true),
            synced: const Value(1),
          ),
        );
  }

  // ── Attachments ────────────────────────────────────────────────────────────

  Future<List<ReportAttachment>> attachmentsFor(String reportId) async {
    final db = await SqLiteService().database;
    return (db.select(db.reportAttachments)
          ..where((a) => a.reportId.equals(reportId))
          ..orderBy([(a) => OrderingTerm.asc(a.createdAt)]))
        .get();
  }

  /// Files that exist on this device but not yet in the user's Drive.
  ///
  /// `cloudUrl` being null is the marker: it is filled in only once the upload
  /// has landed, so an interrupted sync leaves the file queued rather than
  /// half-recorded.
  Future<List<ReportAttachment>> attachmentsAwaitingUpload() async {
    final db = await SqLiteService().database;
    return (db.select(db.reportAttachments)
          ..where((a) => a.cloudUrl.isNull() & a.localPath.equals('').not()))
        .get();
  }

  Future<void> markAttachmentUploaded(String id, String? cloudUrl) async {
    final db = await SqLiteService().database;
    await (db.update(db.reportAttachments)..where((a) => a.id.equals(id)))
        .write(ReportAttachmentsCompanion(
      cloudUrl: Value(cloudUrl),
      synced: const Value(1),
    ));
  }

  /// Records an attachment the server told us about.
  ///
  /// [localPath] is empty for a file this device has never held — one scanned
  /// on another phone, or restored after a reinstall. The view screen reads
  /// that as "in Drive only" and fetches the bytes when the user opens it.
  Future<void> upsertAttachmentFromServer({
    required String id,
    required String reportId,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    String? cloudUrl,
    DateTime? createdAt,
  }) async {
    final db = await SqLiteService().database;
    final existing = await (db.select(db.reportAttachments)
          ..where((a) => a.id.equals(id)))
        .getSingleOrNull();

    await db.into(db.reportAttachments).insertOnConflictUpdate(
          ReportAttachmentsCompanion(
            id: Value(id),
            reportId: Value(reportId),
            localPath: Value(existing?.localPath ?? ''),
            cloudUrl: Value(cloudUrl ?? existing?.cloudUrl),
            fileName: Value(fileName ?? existing?.fileName),
            mimeType: Value(mimeType ?? existing?.mimeType),
            fileSizeBytes: Value(fileSizeBytes ?? existing?.fileSizeBytes),
            createdAt: Value(createdAt ?? existing?.createdAt ?? DateTime.now()),
            synced: const Value(1),
          ),
        );
  }

  /// Points an attachment at the copy just downloaded from Drive, so opening
  /// it a second time doesn't cost another round trip.
  Future<void> setAttachmentLocalPath(String id, String localPath) async {
    final db = await SqLiteService().database;
    await (db.update(db.reportAttachments)..where((a) => a.id.equals(id)))
        .write(ReportAttachmentsCompanion(localPath: Value(localPath)));
  }

  /// Drops the attachment rows for reports that are no longer here.
  Future<void> deleteAttachmentsFor(String reportId) async {
    final db = await SqLiteService().database;
    await (db.delete(db.reportAttachments)
          ..where((a) => a.reportId.equals(reportId)))
        .go();
  }

  /// Decodes the JSON `detail` column, returning an empty map when the
  /// payload is missing or malformed.
  static Map<String, dynamic> decodeDetail(Report report) {
    final raw = report.detail;
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }
}

/// Aggregate view over the locally stored reports.
class ReportsSummary {
  const ReportsSummary({
    required this.total,
    required this.countsByType,
    required this.latestByType,
    this.latest,
  });

  final int total;
  final Map<String, int> countsByType;
  final Map<String, Report> latestByType;
  final Report? latest;
}
