import 'package:drift/drift.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

class HealthDbService {
  static final HealthDbService instance = HealthDbService._internal();
  HealthDbService._internal();

  Future<HealthDataTableData?> getHealthDataByUserId(String userId) async {
    final db = await SqLiteService().database;
    return (db.select(db.healthDataTable)..where((tbl) => tbl.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<HealthDataTableData?> getHealthDataById(String healthId) async {
    final db = await SqLiteService().database;
    return (db.select(db.healthDataTable)..where((tbl) => tbl.id.equals(healthId)))
        .getSingleOrNull();
  }

  Future<void> saveHealthData(HealthDataTableCompanion data) async {
    final db = await SqLiteService().database;
    await db.into(db.healthDataTable).insertOnConflictUpdate(data);
  }

  Future<Pregnancy?> getActivePregnancy(String healthId) async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancies)
          ..where((tbl) => tbl.healthId.equals(healthId) & tbl.status.equals('active')))
        .getSingleOrNull();
  }

  Future<void> savePregnancy(PregnanciesCompanion pregnancy) async {
    final db = await SqLiteService().database;
    await db.into(db.pregnancies).insertOnConflictUpdate(pregnancy);
  }

  Future<List<CycleHistory>> getCycleHistories(String healthId) async {
    final db = await SqLiteService().database;
    return (db.select(db.cycleHistories)
          ..where((tbl) => tbl.healthId.equals(healthId))
          ..orderBy([(t) => OrderingTerm.desc(t.cycleStartDate)]))
        .get();
  }

  Future<void> saveCycleHistory(CycleHistoriesCompanion history) async {
    final db = await SqLiteService().database;
    await db.into(db.cycleHistories).insertOnConflictUpdate(history);
  }
}
