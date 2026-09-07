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
    await db
        .into(db.healthDataTable)
        .insertOnConflictUpdate(data.copyWith(synced: const Value(0)));
  }

  Future<Pregnancy?> getActivePregnancy(String healthId) async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancies)
          ..where((tbl) => tbl.healthId.equals(healthId) & tbl.status.equals('active')))
        .getSingleOrNull();
  }

  Future<void> savePregnancy(PregnanciesCompanion pregnancy) async {
    final db = await SqLiteService().database;
    await db
        .into(db.pregnancies)
        .insertOnConflictUpdate(pregnancy.copyWith(synced: const Value(0)));
  }

  /// Partial update of one pregnancy row — only the fields present on
  /// [pregnancy] are written. `synced` is reset to 0.
  Future<void> updatePregnancy(PregnanciesCompanion pregnancy) async {
    final db = await SqLiteService().database;
    await (db.update(db.pregnancies)
          ..where((tbl) => tbl.id.equals(pregnancy.id.value)))
        .write(pregnancy.copyWith(synced: const Value(0)));
  }

  /// Marks a pregnancy as delivered/completed.
  Future<void> completePregnancy(
    String pregnancyId, {
    required DateTime deliveryDate,
    String? deliveryConductedAt,
  }) async {
    await updatePregnancy(
      PregnanciesCompanion(
        id: Value(pregnancyId),
        status: const Value('completed'),
        deliveryDate: Value(deliveryDate),
        completedAt: Value(DateTime.now()),
        deliveryConductedAt: Value(deliveryConductedAt),
      ),
    );
  }

  Future<List<HealthDataTableData>> unsyncedHealthData() async {
    final db = await SqLiteService().database;
    return (db.select(db.healthDataTable)..where((t) => t.synced.equals(0)))
        .get();
  }

  Future<List<Pregnancy>> unsyncedPregnancies() async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancies)..where((t) => t.synced.equals(0))).get();
  }

  Future<List<Pregnancy>> getAllPregnancies() async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancies)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<Pregnancy>> getCompletedPregnancies([String? healthId]) async {
    final db = await SqLiteService().database;
    final query = db.select(db.pregnancies)
      ..where((tbl) => tbl.status.isNotValue('active'));
    if (healthId != null && healthId.isNotEmpty) {
      query.where((tbl) => tbl.healthId.equals(healthId));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.deliveryDate), (t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  Future<Pregnancy?> getPregnancyById(String pregnancyId) async {
    final db = await SqLiteService().database;
    return (db.select(db.pregnancies)..where((tbl) => tbl.id.equals(pregnancyId)))
        .getSingleOrNull();
  }

  Future<void> deletePregnancy(String pregnancyId) async {
    final db = await SqLiteService().database;
    await (db.delete(db.pregnancies)..where((tbl) => tbl.id.equals(pregnancyId)))
        .go();
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
    await db
        .into(db.cycleHistories)
        .insertOnConflictUpdate(history.copyWith(synced: const Value(0)));
  }
}
