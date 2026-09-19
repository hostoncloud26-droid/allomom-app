import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Local reads and writes for the `health_data` table.
///
/// Matches allomom-api-new column for column, which makes it much thinner than
/// the old local version: measurements such as height, weight and blood group
/// are readings in the vitals stream now, not fields here, so they keep a
/// history instead of being overwritten.
class HealthDbService {
  static final HealthDbService instance = HealthDbService._internal();
  HealthDbService._internal();

  static const _uuid = Uuid();

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  Future<HealthDataTableData?> getForUser(String userId) async {
    final db = await _db;
    return (db.select(db.healthDataTable)
          ..where((h) => h.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Kept under the name the existing call sites use.
  Future<HealthDataTableData?> getHealthDataByUserId(String userId) =>
      getForUser(userId);

  Future<HealthDataTableData?> getHealthDataById(String id) => getById(id);

  /// Writes a health record and marks it dirty, so the next sync pushes it.
  Future<void> saveHealthData(HealthDataTableCompanion health) async {
    final db = await _db;
    await db
        .into(db.healthDataTable)
        .insertOnConflictUpdate(health.copyWith(synced: const Value(0)));
  }

  /// Writes a pregnancy and marks it dirty.
  Future<void> savePregnancy(PregnanciesCompanion pregnancy) async {
    final db = await _db;
    await db
        .into(db.pregnancies)
        .insertOnConflictUpdate(pregnancy.copyWith(synced: const Value(0)));
  }

  Future<List<Pregnancy>> unsyncedPregnancies() async {
    final db = await _db;
    return (db.select(db.pregnancies)..where((p) => p.synced.equals(0))).get();
  }

  Future<HealthDataTableData?> getById(String id) async {
    final db = await _db;
    return (db.select(db.healthDataTable)..where((h) => h.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns the user's health record, creating it if the seed has not run yet.
  ///
  /// Every user has exactly one on the server, so screens are entitled to
  /// assume one exists; creating it locally keeps that true offline too.
  Future<HealthDataTableData> getOrCreateForUser(String userId) async {
    final existing = await getForUser(userId);
    if (existing != null) return existing;

    final db = await _db;
    final now = DateTime.now();
    await db
        .into(db.healthDataTable)
        .insertOnConflictUpdate(
          HealthDataTableCompanion.insert(
            id: _uuid.v4(),
            userId: userId,
            createdAt: Value(now),
            updatedAt: Value(now),
            synced: const Value(0),
          ),
        );
    return (await getForUser(userId))!;
  }

  Future<void> save(HealthDataTableCompanion health) async {
    final db = await _db;
    await db.into(db.healthDataTable).insertOnConflictUpdate(health);
  }

  /// Applies a local edit and queues it for the next sync.
  Future<void> update(HealthDataTableCompanion health) async {
    final db = await _db;
    await (db.update(db.healthDataTable)
          ..where((h) => h.id.equals(health.id.value)))
        .write(
          health.copyWith(
            updatedAt: Value(DateTime.now()),
            synced: const Value(0),
          ),
        );
  }

  Future<void> setLmpDate(String healthId, DateTime? lmpDate) async {
    final db = await _db;
    await (db.update(db.healthDataTable)..where((h) => h.id.equals(healthId)))
        .write(
          HealthDataTableCompanion(
            lmpDate: Value(lmpDate),
            updatedAt: Value(DateTime.now()),
            synced: const Value(0),
          ),
        );
  }

  // ── Pregnancies ────────────────────────────────────────────────────────────
  //
  // Reached through the health record, which is how the server scopes them too:
  // a pregnancy belongs to a `health_data` row, not directly to a user.

  Future<Pregnancy?> getActivePregnancy(String healthId) async {
    final db = await _db;
    return (db.select(db.pregnancies)
          ..where(
            (p) =>
                p.healthId.equals(healthId) &
                p.status.equals('active') &
                p.deletedAt.isNull(),
          )
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Pregnancy>> getPregnancies(String healthId) async {
    final db = await _db;
    return (db.select(db.pregnancies)
          ..where((p) => p.healthId.equals(healthId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  Future<List<Pregnancy>> getCompletedPregnancies(String healthId) async {
    final db = await _db;
    return (db.select(db.pregnancies)
          ..where(
            (p) =>
                p.healthId.equals(healthId) &
                p.status.equals('active').not() &
                p.deletedAt.isNull(),
          )
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  /// Closes a pregnancy out locally and queues the change for sync.
  ///
  /// [status] follows the server's vocabulary: delivered, aborted, miscarriage,
  /// stillbirth, neonatal death, mother_deceased.
  Future<void> completePregnancy(
    String pregnancyId, {
    String status = 'delivered',
    DateTime? deliveredAt,
  }) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.pregnancies)..where((p) => p.id.equals(pregnancyId)))
        .write(
          PregnanciesCompanion(
            status: Value(status),
            deliveryDateTime: Value(deliveredAt ?? now),
            updatedAt: Value(now),
            synced: const Value(0),
          ),
        );
  }

  /// Soft-deletes a pregnancy so the removal reaches the server. A hard delete
  /// would simply be re-pulled on the next sync.
  Future<void> deletePregnancy(String pregnancyId) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.pregnancies)..where((p) => p.id.equals(pregnancyId)))
        .write(
          PregnanciesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            synced: const Value(0),
          ),
        );
  }

  // ── Cycle history (app-local) ──────────────────────────────────────────────
  //
  // `cycle_histories` has no server counterpart. It is the scrollable log the
  // tracker shows, with the end date and flow type the API does not model; the
  // period *start* that predictions run off is recorded separately as a
  // `period_start` reading in the vitals stream, which does sync.

  Future<List<CycleHistory>> getCycleHistories(String healthId) async {
    final db = await _db;
    return (db.select(db.cycleHistories)
          ..where((c) => c.healthId.equals(healthId))
          ..orderBy([(c) => OrderingTerm.desc(c.cycleStartDate)]))
        .get();
  }

  Future<void> saveCycleHistory(CycleHistoriesCompanion history) async {
    final db = await _db;
    await db.into(db.cycleHistories).insertOnConflictUpdate(history);
  }

  Future<void> deleteCycleHistory(String id) async {
    final db = await _db;
    await (db.delete(db.cycleHistories)..where((c) => c.id.equals(id))).go();
  }

  Future<List<HealthDataTableData>> unsynced() async {
    final db = await _db;
    return (db.select(db.healthDataTable)..where((h) => h.synced.equals(0)))
        .get();
  }
}
