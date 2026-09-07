import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// CRUD for medical reports and their AI-parsed detail payload.
///
/// Local-only. Every write resets `synced` to 0 so a future sync worker can
/// push the row to allomom-api.
class ReportDbService {
  static final ReportDbService instance = ReportDbService._internal();
  ReportDbService._internal();

  final _uuid = const Uuid();

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
