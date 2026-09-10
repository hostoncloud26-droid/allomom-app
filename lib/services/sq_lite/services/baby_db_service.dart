import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// CRUD for the baby tables: birth records, immunisation records and
/// developmental milestones.
///
/// Every create returns the generated UUID. Any local write resets `synced`
/// to 0 so the sync worker can pick the row up again.
class BabyDbService {
  static final BabyDbService instance = BabyDbService._internal();
  BabyDbService._internal();

  final _uuid = const Uuid();

  // ---------------------- BIRTH RECORDS ----------------------

  /// Inserts or updates a birth record.
  ///
  /// When [record] carries no id, one is generated. Pass [createHealthRecord]
  /// to also mint the baby's own `health_data_table` row and link it through
  /// `health_id`, so the baby's vitals and reports have somewhere to live.
  Future<String> createBirthRecord(
    BirthRecordsCompanion record, {
    bool createHealthRecord = true,
  }) async {
    final db = await SqLiteService().database;
    final id = record.id.present && record.id.value.isNotEmpty
        ? record.id.value
        : _uuid.v7();

    var row = record.copyWith(id: Value(id), synced: const Value(0));

    if (createHealthRecord && !_hasValue(record.healthId)) {
      final healthId = _uuid.v7();
      await db
          .into(db.healthDataTable)
          .insertOnConflictUpdate(
            HealthDataTableCompanion(
              id: Value(healthId),
              // The baby has no user account yet, so userId stays null until
              // `infant_id` is filled in and a profile is created for them.
              bloodGroup: record.bloodGroup,
              weight: record.weight,
              pregnancyStatus: const Value('notpregnant'),
              synced: const Value(0),
            ),
          );
      row = row.copyWith(healthId: Value(healthId));
    }

    await db.into(db.birthRecords).insertOnConflictUpdate(row);
    return id;
  }

  static bool _hasValue(Value<String?> value) =>
      value.present && (value.value ?? '').isNotEmpty;

  Future<List<BirthRecord>> getBirthRecords() async {
    final db = await SqLiteService().database;
    return (db.select(db.birthRecords)
          ..orderBy([
            (t) => OrderingTerm.desc(t.dob),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
  }

  Future<BirthRecord?> getBirthRecordById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.birthRecords)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// The baby born of a given pregnancy, if one has been recorded.
  Future<List<BirthRecord>> getBirthRecordsForPregnancy(
    String pregnancyId,
  ) async {
    final db = await SqLiteService().database;
    return (db.select(db.birthRecords)
          ..where((tbl) => tbl.pregnancyId.equals(pregnancyId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Stream<List<BirthRecord>> watchBirthRecords() {
    return Stream.fromFuture(SqLiteService().database).asyncExpand((db) {
      return (db.select(db.birthRecords)
            ..orderBy([(t) => OrderingTerm.desc(t.dob)]))
          .watch();
    });
  }

  Future<void> updateBirthRecord(BirthRecordsCompanion record) async {
    final db = await SqLiteService().database;
    await (db.update(db.birthRecords)
          ..where((tbl) => tbl.id.equals(record.id.value)))
        .write(record.copyWith(synced: const Value(0)));
  }

  /// Deletes a birth record along with its immunisations and milestones.
  ///
  /// Foreign keys are not enforced by SQLite here, so children are cleared
  /// explicitly to avoid orphan rows. The baby's `health_data_table` row is
  /// removed too when nothing else points at it.
  Future<void> deleteBirthRecord(String id) async {
    final db = await SqLiteService().database;
    final record = await getBirthRecordById(id);

    await db.transaction(() async {
      await (db.delete(db.babyImmunizationRecords)
            ..where((tbl) => tbl.birthRecordId.equals(id)))
          .go();
      await (db.delete(db.babyMilestones)
            ..where((tbl) => tbl.birthRecordId.equals(id)))
          .go();
      await (db.delete(db.birthRecords)..where((tbl) => tbl.id.equals(id)))
          .go();

      final healthId = record?.healthId;
      if (healthId != null && healthId.isNotEmpty) {
        await (db.delete(db.healthDataTable)
              ..where((tbl) => tbl.id.equals(healthId)))
            .go();
      }
    });
  }

  Future<List<BirthRecord>> unsyncedBirthRecords() async {
    final db = await SqLiteService().database;
    return (db.select(db.birthRecords)..where((tbl) => tbl.synced.equals(0)))
        .get();
  }

  // ---------------------- BABY IMMUNISATIONS ----------------------

  Future<String> createImmunization(
    BabyImmunizationRecordsCompanion record,
  ) async {
    final db = await SqLiteService().database;
    final id = record.id.present && record.id.value.isNotEmpty
        ? record.id.value
        : _uuid.v7();
    await db
        .into(db.babyImmunizationRecords)
        .insertOnConflictUpdate(
          record.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<List<BabyImmunizationRecord>> getImmunizations(
    String birthRecordId,
  ) async {
    final db = await SqLiteService().database;
    return (db.select(db.babyImmunizationRecords)
          ..where((tbl) => tbl.birthRecordId.equals(birthRecordId))
          ..orderBy([(t) => OrderingTerm.asc(t.expectedDate)]))
        .get();
  }

  Future<BabyImmunizationRecord?> getImmunizationById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.babyImmunizationRecords)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateImmunization(
    BabyImmunizationRecordsCompanion record,
  ) async {
    final db = await SqLiteService().database;
    await (db.update(db.babyImmunizationRecords)
          ..where((tbl) => tbl.id.equals(record.id.value)))
        .write(record.copyWith(synced: const Value(0)));
  }

  /// Records a dose as given on [date].
  Future<void> markImmunizationGiven(
    String id, {
    required DateTime date,
    String? vaccinatedBy,
  }) async {
    await updateImmunization(
      BabyImmunizationRecordsCompanion(
        id: Value(id),
        vaccinationDate: Value(date),
        vaccinatedBy: Value(vaccinatedBy),
      ),
    );
  }

  Future<void> deleteImmunization(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.babyImmunizationRecords)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<List<BabyImmunizationRecord>> unsyncedImmunizations() async {
    final db = await SqLiteService().database;
    return (db.select(db.babyImmunizationRecords)
          ..where((tbl) => tbl.synced.equals(0)))
        .get();
  }

  // ---------------------- BABY MILESTONES ----------------------

  Future<String> createMilestone(BabyMilestonesCompanion milestone) async {
    final db = await SqLiteService().database;
    final id = milestone.id.present && milestone.id.value.isNotEmpty
        ? milestone.id.value
        : _uuid.v7();
    await db
        .into(db.babyMilestones)
        .insertOnConflictUpdate(
          milestone.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<List<BabyMilestone>> getMilestones(String birthRecordId) async {
    final db = await SqLiteService().database;
    return (db.select(db.babyMilestones)
          ..where((tbl) => tbl.birthRecordId.equals(birthRecordId))
          ..orderBy([(t) => OrderingTerm.asc(t.expectedDate)]))
        .get();
  }

  Future<BabyMilestone?> getMilestoneById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.babyMilestones)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> updateMilestone(BabyMilestonesCompanion milestone) async {
    final db = await SqLiteService().database;
    await (db.update(db.babyMilestones)
          ..where((tbl) => tbl.id.equals(milestone.id.value)))
        .write(
          milestone.copyWith(
            synced: const Value(0),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Ticks a milestone off (or un-ticks it), stamping the achievement date.
  Future<void> setMilestoneAchieved(
    String id, {
    required bool achieved,
    DateTime? completedOn,
  }) async {
    await updateMilestone(
      BabyMilestonesCompanion(
        id: Value(id),
        achieved: Value(achieved),
        completed: Value(achieved ? (completedOn ?? DateTime.now()) : null),
      ),
    );
  }

  Future<void> deleteMilestone(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.babyMilestones)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<List<BabyMilestone>> unsyncedMilestones() async {
    final db = await SqLiteService().database;
    return (db.select(db.babyMilestones)..where((tbl) => tbl.synced.equals(0)))
        .get();
  }

  // ---------------------- BULK ----------------------

  /// Clears the schedule rows for a birth record, so re-seeding replaces the
  /// plan instead of duplicating it.
  Future<void> deleteScheduleFor(String birthRecordId) async {
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await (db.delete(db.babyImmunizationRecords)
            ..where((tbl) => tbl.birthRecordId.equals(birthRecordId)))
          .go();
      await (db.delete(db.babyMilestones)
            ..where((tbl) => tbl.birthRecordId.equals(birthRecordId)))
          .go();
    });
  }
}
