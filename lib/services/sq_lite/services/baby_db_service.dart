import 'package:drift/drift.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Local reads and writes for babies and their two schedules.
///
/// What was `birth_records` is now `baby`, matching allomom-api-new: a baby
/// hangs off a pregnancy rather than standing alone, which is how the server
/// establishes who it belongs to. [BabyController] is the usual entry point.
class BabyDbService {
  static final BabyDbService _instance = BabyDbService._internal();
  factory BabyDbService() => _instance;
  BabyDbService._internal();

  static BabyDbService get instance => _instance;

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── Baby ───────────────────────────────────────────────────────────────────

  Future<String> createBaby(BabiesCompanion baby) async {
    final db = await _db;
    await db.into(db.babies).insertOnConflictUpdate(baby);
    return baby.id.value;
  }

  Future<List<Baby>> getBabies() async {
    final db = await _db;
    return (db.select(db.babies)
          ..where((b) => b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm.desc(b.deliveryDate)]))
        .get();
  }

  Future<Baby?> getBabyById(String id) async {
    final db = await _db;
    return (db.select(db.babies)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Baby>> getBabiesForPregnancy(String pregnancyId) async {
    final db = await _db;
    return (db.select(db.babies)
          ..where((b) => b.pregnancyId.equals(pregnancyId) & b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm.desc(b.deliveryDate)]))
        .get();
  }

  Stream<List<Baby>> watchBabies() {
    return Stream.fromFuture(_db).asyncExpand((db) {
      return (db.select(db.babies)
            ..where((b) => b.deletedAt.isNull())
            ..orderBy([(b) => OrderingTerm.desc(b.deliveryDate)]))
          .watch();
    });
  }

  Future<void> updateBaby(BabiesCompanion baby) async {
    final db = await _db;
    await (db.update(db.babies)..where((b) => b.id.equals(baby.id.value)))
        .write(baby.copyWith(synced: const Value(0)));
  }

  /// Soft delete, so the removal syncs. A hard delete would be re-pulled.
  Future<void> deleteBaby(String id) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.babies)..where((b) => b.id.equals(id))).write(
      BabiesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(0),
      ),
    );
  }

  Future<List<Baby>> unsyncedBabies() async {
    final db = await _db;
    return (db.select(db.babies)..where((b) => b.synced.equals(0))).get();
  }

  // ── Immunizations ──────────────────────────────────────────────────────────

  Future<String> createImmunization(
    BabyImmunizationRecordsCompanion record,
  ) async {
    final db = await _db;
    await db.into(db.babyImmunizationRecords).insertOnConflictUpdate(record);
    return record.id.value;
  }

  Future<List<BabyImmunizationRecord>> getImmunizations(String babyId) async {
    final db = await _db;
    return (db.select(db.babyImmunizationRecords)
          ..where((v) => v.babyId.equals(babyId) & v.deletedAt.isNull())
          ..orderBy([(v) => OrderingTerm.asc(v.scheduledDate)]))
        .get();
  }

  Future<BabyImmunizationRecord?> getImmunizationById(String id) async {
    final db = await _db;
    return (db.select(db.babyImmunizationRecords)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateImmunization(
    BabyImmunizationRecordsCompanion record,
  ) async {
    final db = await _db;
    await (db.update(db.babyImmunizationRecords)
          ..where((v) => v.id.equals(record.id.value)))
        .write(record.copyWith(synced: const Value(0)));
  }

  Future<void> markImmunizationGiven(String id, DateTime receivedDate) async {
    final db = await _db;
    await (db.update(db.babyImmunizationRecords)..where((v) => v.id.equals(id)))
        .write(
          BabyImmunizationRecordsCompanion(
            receivedDate: Value(receivedDate),
            updatedAt: Value(DateTime.now()),
            synced: const Value(0),
          ),
        );
  }

  Future<void> deleteImmunization(String id) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.babyImmunizationRecords)..where((v) => v.id.equals(id)))
        .write(
          BabyImmunizationRecordsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            synced: const Value(0),
          ),
        );
  }

  Future<List<BabyImmunizationRecord>> unsyncedImmunizations() async {
    final db = await _db;
    return (db.select(db.babyImmunizationRecords)
          ..where((v) => v.synced.equals(0)))
        .get();
  }

  // ── Milestones ─────────────────────────────────────────────────────────────

  Future<int> createMilestone(BabyMilestonesCompanion milestone) async {
    final db = await _db;
    await db.into(db.babyMilestones).insertOnConflictUpdate(milestone);
    return milestone.id.value;
  }

  Future<List<BabyMilestone>> getMilestones(String babyId) async {
    final db = await _db;
    return (db.select(db.babyMilestones)
          ..where((m) => m.babyId.equals(babyId) & m.deletedAt.isNull())
          ..orderBy([(m) => OrderingTerm.asc(m.expectedDate)]))
        .get();
  }

  Future<BabyMilestone?> getMilestoneById(int id) async {
    final db = await _db;
    return (db.select(db.babyMilestones)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateMilestone(BabyMilestonesCompanion milestone) async {
    final db = await _db;
    await (db.update(db.babyMilestones)
          ..where((m) => m.id.equals(milestone.id.value)))
        .write(milestone.copyWith(synced: const Value(0)));
  }

  /// Stamps a milestone as reached, or clears it when [completedAt] is null.
  ///
  /// There is no separate `achieved` flag any more: a milestone is reached
  /// exactly when it has a completion date, which is what the server records
  /// and removes the chance of the two disagreeing.
  Future<void> setMilestoneAchieved(int id, DateTime? completedAt) async {
    final db = await _db;
    await (db.update(db.babyMilestones)..where((m) => m.id.equals(id))).write(
      BabyMilestonesCompanion(
        completedAt: Value(completedAt),
        updatedAt: Value(DateTime.now()),
        synced: const Value(0),
      ),
    );
  }

  Future<void> deleteMilestone(int id) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.babyMilestones)..where((m) => m.id.equals(id))).write(
      BabyMilestonesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        synced: const Value(0),
      ),
    );
  }

  Future<List<BabyMilestone>> unsyncedMilestones() async {
    final db = await _db;
    return (db.select(db.babyMilestones)..where((m) => m.synced.equals(0)))
        .get();
  }

  Future<void> deleteScheduleFor(String babyId) async {
    final db = await _db;
    await db.transaction(() async {
      await (db.delete(db.babyImmunizationRecords)
            ..where((v) => v.babyId.equals(babyId)))
          .go();
      await (db.delete(db.babyMilestones)..where((m) => m.babyId.equals(babyId)))
          .go();
    });
  }
}
