import 'package:drift/drift.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

class ReportDbService {
  static final ReportDbService instance = ReportDbService._internal();
  ReportDbService._internal();

  Future<List<Report>> getReports(String healthDataId) async {
    final db = await SqLiteService().database;
    return (db.select(db.reports)
          ..where((tbl) => tbl.healthDataID.equals(healthDataId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> saveReport(ReportsCompanion report) async {
    final db = await SqLiteService().database;
    await db.into(db.reports).insertOnConflictUpdate(report);
  }

  Future<void> deleteReport(String reportId) async {
    final db = await SqLiteService().database;
    await (db.delete(db.reports)..where((tbl) => tbl.id.equals(reportId))).go();
  }
}
