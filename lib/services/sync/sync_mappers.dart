import 'package:drift/drift.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sync/sync_codec.dart';

/// Everything one sync module needs to move rows in both directions.
///
/// The engine in [SyncService] is generic over this: it never names a table, so
/// adding a module is adding a mapper here. The two directions are deliberately
/// asymmetric — [applyServerRow] writes every column the server sent, while
/// [toServerJson] sends only the fields the API marks writable, because the
/// rest (ids, server timestamps, owner keys) are the server's to set.
abstract class SyncMapper {
  const SyncMapper();

  /// Module name as `/sync/{module}` expects it.
  String get module;

  /// Writes a row the server sent into the local table, overwriting whatever
  /// is there. Called only for rows that won the last-write-wins comparison.
  Future<void> applyServerRow(AppDriftDatabase db, Map<String, dynamic> json);

  /// Rows edited locally and not yet accepted by the server.
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db);

  /// Ids of rows deleted on this phone that the server still has, sent as
  /// `deleted_ids`. Modules that never delete locally leave this empty.
  Future<List<String>> pendingDeletes(AppDriftDatabase db) async => const [];

  /// Marks rows clean once the server has confirmed them.
  Future<void> markSynced(
    AppDriftDatabase db,
    List<String> ids,
    DateTime syncedAt,
  );

  /// Removes rows the server reports as deleted.
  Future<void> deleteRows(AppDriftDatabase db, List<String> ids);

  /// Drops every row — used when re-seeding from `/me/profile/get_all`.
  Future<void> clear(AppDriftDatabase db);
}

/// Shared implementation for the tables keyed by a client-generatable UUID,
/// which is every module but milestones.
abstract class _UuidKeyedMapper extends SyncMapper {
  const _UuidKeyedMapper();

  TableInfo<Table, dynamic> table(AppDriftDatabase db);
  GeneratedColumn<String> idColumn(AppDriftDatabase db);
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db);
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db);

  @override
  Future<void> markSynced(
    AppDriftDatabase db,
    List<String> ids,
    DateTime syncedAt,
  ) async {
    if (ids.isEmpty) return;
    await db.customUpdate(
      'UPDATE ${table(db).actualTableName} SET synced = 1, synced_at = ? '
      'WHERE ${idColumn(db).name} IN (${List.filled(ids.length, '?').join(',')})',
      variables: [
        Variable<DateTime>(syncedAt),
        ...ids.map((id) => Variable<String>(id)),
      ],
      updates: {table(db)},
    );
  }

  @override
  Future<void> deleteRows(AppDriftDatabase db, List<String> ids) async {
    if (ids.isEmpty) return;
    await db.customUpdate(
      'DELETE FROM ${table(db).actualTableName} '
      'WHERE ${idColumn(db).name} IN (${List.filled(ids.length, '?').join(',')})',
      variables: ids.map((id) => Variable<String>(id)).toList(),
      updates: {table(db)},
    );
  }

  @override
  Future<void> clear(AppDriftDatabase db) => db.delete(table(db)).go();
}

// ── User ─────────────────────────────────────────────────────────────────────

class UserMapper extends _UuidKeyedMapper {
  const UserMapper();

  @override
  String get module => 'user';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) => db.users;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) => db.users.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) => db.users.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.users.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.users)
        .insertOnConflictUpdate(
          UsersCompanion(
            id: Value(json['id'].toString()),
            name: Value(SyncCodec.text(json['name'])),
            email: Value(SyncCodec.text(json['email'])),
            phone: Value(SyncCodec.text(json['phone'])),
            phoneVerified: Value(SyncCodec.date(json['phone_verified'])),
            countryCode: Value(SyncCodec.text(json['country_code'])),
            emailVerified: Value(SyncCodec.date(json['email_verified'])),
            coverPic: Value(SyncCodec.text(json['cover_pic'])),
            bio: Value(SyncCodec.text(json['bio'])),
            gender: Value(SyncCodec.text(json['gender'])),
            dob: Value(SyncCodec.date(json['dob'])),
            profilePicture: Value(SyncCodec.text(json['profile_picture'])),
            userType: Value(SyncCodec.text(json['user_type']) ?? 'User'),
            addressLine1: Value(SyncCodec.text(json['address_line_1'])),
            addressLine2: Value(SyncCodec.text(json['address_line_2'])),
            city: Value(SyncCodec.text(json['city'])),
            pincode: Value(SyncCodec.text(json['pincode'])),
            lat: Value(SyncCodec.number(json['lat'])),
            lng: Value(SyncCodec.number(json['lng'])),
            isRegistered: Value(SyncCodec.boolean(json['is_registered']) ?? false),
            userName: Value(SyncCodec.text(json['user_name'])),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.users)
          ..where((u) => u.synced.equals(0))).get();
    return rows
        .map(
          (u) => <String, dynamic>{
            'id': u.id,
            'updated_at': SyncCodec.isoUtc(u.updatedAt),
            'name': u.name,
            'email': u.email,
            'country_code': u.countryCode,
            'cover_pic': u.coverPic,
            'bio': u.bio,
            'gender': u.gender,
            'dob': SyncCodec.isoDate(u.dob),
            'profile_picture': u.profilePicture,
            'user_type': u.userType,
            'address_line_1': u.addressLine1,
            'address_line_2': u.addressLine2,
            'city': u.city,
            'pincode': u.pincode,
            'lat': u.lat,
            'lng': u.lng,
            'user_name': u.userName,
            'is_registered': u.isRegistered,
          },
        )
        .toList();
  }
}

// ── Health data ──────────────────────────────────────────────────────────────

class HealthMapper extends _UuidKeyedMapper {
  const HealthMapper();

  @override
  String get module => 'health';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) => db.healthDataTable;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) =>
      db.healthDataTable.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) =>
      db.healthDataTable.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.healthDataTable.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.healthDataTable)
        .insertOnConflictUpdate(
          HealthDataTableCompanion(
            id: Value(json['id'].toString()),
            userId: Value(json['user_id'].toString()),
            lmpDate: Value(SyncCodec.date(json['lmp_date'])),
            rchId: Value(SyncCodec.text(json['rch_id'])),
            allergies: Value(SyncCodec.text(json['allergies'])),
            medicalCondition: Value(SyncCodec.text(json['medical_condition'])),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.healthDataTable)
          ..where((h) => h.synced.equals(0))).get();
    return rows
        .map(
          (h) => <String, dynamic>{
            'id': h.id,
            'updated_at': SyncCodec.isoUtc(h.updatedAt),
            'lmp_date': SyncCodec.isoUtc(h.lmpDate),
            'rch_id': h.rchId,
            'allergies': h.allergies,
            'medical_condition': h.medicalCondition,
          },
        )
        .toList();
  }
}

// ── Vitals ───────────────────────────────────────────────────────────────────

class VitalsMapper extends _UuidKeyedMapper {
  const VitalsMapper();

  @override
  String get module => 'vitals';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) => db.vitalsStreamTable;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) =>
      db.vitalsStreamTable.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) =>
      db.vitalsStreamTable.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.vitalsStreamTable.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.vitalsStreamTable)
        .insertOnConflictUpdate(
          VitalsStreamTableCompanion(
            id: Value(json['id'].toString()),
            healthId: Value(SyncCodec.text(json['health_id'])),
            key: Value(json['key'].toString()),
            value: Value(SyncCodec.number(json['value'])),
            unit: Value(SyncCodec.text(json['unit'])),
            data: Value(SyncCodec.encodeJson(json['data'])),
            createdAt: Value(SyncCodec.date(json['createdAt']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    // Deleted rows go up as `deleted_ids`, not as edits.
    final rows = await (db.select(db.vitalsStreamTable)
          ..where((v) => v.synced.equals(0) & v.deletedAt.isNull())).get();
    return rows
        .map(
          (v) => <String, dynamic>{
            'id': v.id,
            'updated_at': SyncCodec.isoUtc(v.updatedAt),
            'key': v.key,
            'value': v.value,
            'unit': v.unit,
            'data': SyncCodec.decodeMap(v.data),
            'createdAt': SyncCodec.isoUtc(v.createdAt),
          },
        )
        .toList();
  }

  /// A tick undone, a reading removed: soft-deleted here, still on the server.
  @override
  Future<List<String>> pendingDeletes(AppDriftDatabase db) async {
    final rows = await (db.select(db.vitalsStreamTable)
          ..where((v) => v.synced.equals(0) & v.deletedAt.isNotNull())).get();
    return rows.map((v) => v.id).toList();
  }
}

// ── Pregnancy ────────────────────────────────────────────────────────────────

class PregnancyMapper extends _UuidKeyedMapper {
  const PregnancyMapper();

  @override
  String get module => 'pregnancy';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) => db.pregnancies;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) => db.pregnancies.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) =>
      db.pregnancies.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.pregnancies.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.pregnancies)
        .insertOnConflictUpdate(
          PregnanciesCompanion(
            id: Value(json['id'].toString()),
            lmpDate: Value(SyncCodec.date(json['lmp_date'])),
            eddDate: Value(SyncCodec.date(json['edd_date'])),
            healthId: Value(SyncCodec.text(json['health_id'])),
            deliveryDateTime: Value(SyncCodec.date(json['delivery_date_time'])),
            status: Value(SyncCodec.text(json['status']) ?? 'active'),
            createdBy: Value(SyncCodec.text(json['created_by'])),
            data: Value(SyncCodec.encodeJson(json['data'])),
            highestRiskStatus: Value(SyncCodec.text(json['highest_risk_status'])),
            allFlaggedComplications: Value(
              SyncCodec.encodeJson(json['all_flagged_complications']),
            ),
            riskStatus: Value(SyncCodec.text(json['risk_status'])),
            flaggedComplications: Value(
              SyncCodec.encodeJson(json['flagged_complications']),
            ),
            overallHealth: Value(SyncCodec.encodeJson(json['overall_health'])),
            gravidity: Value(SyncCodec.integer(json['gravidity']) ?? 0),
            parity: Value(SyncCodec.integer(json['parity']) ?? 0),
            livingChildren: Value(SyncCodec.integer(json['living_children']) ?? 0),
            abortions: Value(SyncCodec.integer(json['abortions']) ?? 0),
            stillBirths: Value(SyncCodec.integer(json['still_births']) ?? 0),
            miscarriages: Value(SyncCodec.integer(json['miscarriages']) ?? 0),
            csectionDeliveries: Value(
              SyncCodec.integer(json['csection_deliveries']) ?? 0,
            ),
            obstetricCode: Value(SyncCodec.text(json['obstetric_code'])),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.pregnancies)
          ..where((p) => p.synced.equals(0))).get();
    return rows
        .map(
          (p) => <String, dynamic>{
            'id': p.id,
            'updated_at': SyncCodec.isoUtc(p.updatedAt),
            // The server's `lmp_date` and `edd_date` are date columns, not
            // timestamps, and reject a full ISO datetime.
            'lmp_date': SyncCodec.isoDate(p.lmpDate),
            'edd_date': SyncCodec.isoDate(p.eddDate),
            'delivery_date_time': SyncCodec.isoUtc(p.deliveryDateTime),
            'status': p.status,
            'data': SyncCodec.decodeMap(p.data),
            'highest_risk_status': p.highestRiskStatus,
            'all_flagged_complications':
                SyncCodec.decodeStringList(p.allFlaggedComplications),
            'risk_status': p.riskStatus,
            'flagged_complications':
                SyncCodec.decodeStringList(p.flaggedComplications),
            'overall_health': SyncCodec.decodeMap(p.overallHealth),
            'gravidity': p.gravidity,
            'parity': p.parity,
            'living_children': p.livingChildren,
            'abortions': p.abortions,
            'still_births': p.stillBirths,
            'miscarriages': p.miscarriages,
            'csection_deliveries': p.csectionDeliveries,
            'obstetric_code': p.obstetricCode,
          },
        )
        .toList();
  }
}

// ── ANC checkups ─────────────────────────────────────────────────────────────

class AncMapper extends _UuidKeyedMapper {
  const AncMapper();

  @override
  String get module => 'anc';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) => db.ancCheckupDates;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) =>
      db.ancCheckupDates.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) =>
      db.ancCheckupDates.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.ancCheckupDates.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.ancCheckupDates)
        .insertOnConflictUpdate(
          AncCheckupDatesCompanion(
            id: Value(json['id'].toString()),
            pregnancyId: Value(SyncCodec.text(json['pregnancy_id'])),
            scheduledDate: Value(SyncCodec.date(json['scheduled_date'])),
            month: Value(SyncCodec.integer(json['month']) ?? 0),
            completedAt: Value(SyncCodec.date(json['completed_at'])),
            scheduledDateRangeFrom: Value(
              SyncCodec.date(json['scheduled_date_range_from']),
            ),
            scheduledDateRangeTo: Value(
              SyncCodec.date(json['scheduled_date_range_to']),
            ),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.ancCheckupDates)
          ..where((a) => a.synced.equals(0))).get();
    return rows
        .map(
          (a) => <String, dynamic>{
            'id': a.id,
            'pregnancy_id': a.pregnancyId,
            'updated_at': SyncCodec.isoUtc(a.updatedAt),
            'scheduled_date': SyncCodec.isoDate(a.scheduledDate),
            'month': a.month,
            'completed_at': SyncCodec.isoUtc(a.completedAt),
            'scheduled_date_range_from':
                SyncCodec.isoDate(a.scheduledDateRangeFrom),
            'scheduled_date_range_to': SyncCodec.isoDate(a.scheduledDateRangeTo),
          },
        )
        .toList();
  }
}

// ── Pregnancy vaccinations ───────────────────────────────────────────────────

class PregnancyVaccinationMapper extends _UuidKeyedMapper {
  const PregnancyVaccinationMapper();

  @override
  String get module => 'pregnancy_vaccination';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) =>
      db.pregnancyImmunizationRecords;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) =>
      db.pregnancyImmunizationRecords.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) =>
      db.pregnancyImmunizationRecords.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.pregnancyImmunizationRecords.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.pregnancyImmunizationRecords)
        .insertOnConflictUpdate(
          PregnancyImmunizationRecordsCompanion(
            id: Value(json['id'].toString()),
            pregnancyId: Value(SyncCodec.text(json['pregnancy_id'])),
            vaccineName: Value(json['vaccine_name'].toString()),
            scheduledDate: Value(SyncCodec.date(json['scheduled_date'])),
            receivedDate: Value(SyncCodec.date(json['received_date'])),
            required: Value(SyncCodec.boolean(json['required']) ?? true),
            scheduledDateRangeFrom: Value(
              SyncCodec.date(json['scheduled_date_range_from']),
            ),
            scheduledDateRangeTo: Value(
              SyncCodec.date(json['scheduled_date_range_to']),
            ),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.pregnancyImmunizationRecords)
          ..where((v) => v.synced.equals(0))).get();
    return rows
        .map(
          (v) => <String, dynamic>{
            'id': v.id,
            'pregnancy_id': v.pregnancyId,
            'updated_at': SyncCodec.isoUtc(v.updatedAt),
            'vaccine_name': v.vaccineName,
            'scheduled_date': SyncCodec.isoDate(v.scheduledDate),
            'received_date': SyncCodec.isoUtc(v.receivedDate),
            'required': v.required,
            'scheduled_date_range_from':
                SyncCodec.isoDate(v.scheduledDateRangeFrom),
            'scheduled_date_range_to': SyncCodec.isoDate(v.scheduledDateRangeTo),
          },
        )
        .toList();
  }
}

// ── Report checklist ─────────────────────────────────────────────────────────

class ReportChecklistMapper extends _UuidKeyedMapper {
  const ReportChecklistMapper();

  @override
  String get module => 'report_checklist';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) =>
      db.pregnancyReportChecklists;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) =>
      db.pregnancyReportChecklists.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) =>
      db.pregnancyReportChecklists.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.pregnancyReportChecklists.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.pregnancyReportChecklists)
        .insertOnConflictUpdate(
          PregnancyReportChecklistsCompanion(
            id: Value(json['id'].toString()),
            pregnancyId: Value(SyncCodec.text(json['pregnancy_id'])),
            reportName: Value(json['report_name'].toString()),
            expectedDate: Value(SyncCodec.date(json['expected_date'])),
            completedDate: Value(SyncCodec.date(json['completed_date'])),
            reportType: Value(SyncCodec.text(json['report_type'])),
            required: Value(SyncCodec.boolean(json['required']) ?? true),
            scheduledDateRangeFrom: Value(
              SyncCodec.date(json['scheduled_date_range_from']),
            ),
            scheduledDateRangeTo: Value(
              SyncCodec.date(json['scheduled_date_range_to']),
            ),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.pregnancyReportChecklists)
          ..where((r) => r.synced.equals(0))).get();
    return rows
        .map(
          (r) => <String, dynamic>{
            'id': r.id,
            'pregnancy_id': r.pregnancyId,
            'updated_at': SyncCodec.isoUtc(r.updatedAt),
            'report_name': r.reportName,
            'expected_date': SyncCodec.isoUtc(r.expectedDate),
            'completed_date': SyncCodec.isoUtc(r.completedDate),
            'report_type': r.reportType,
            'required': r.required,
            'scheduled_date_range_from':
                SyncCodec.isoDate(r.scheduledDateRangeFrom),
            'scheduled_date_range_to': SyncCodec.isoDate(r.scheduledDateRangeTo),
          },
        )
        .toList();
  }
}

// ── Baby ─────────────────────────────────────────────────────────────────────

class BabyMapper extends _UuidKeyedMapper {
  const BabyMapper();

  @override
  String get module => 'baby';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) => db.babies;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) => db.babies.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) => db.babies.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.babies.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.babies)
        .insertOnConflictUpdate(
          BabiesCompanion(
            id: Value(json['id'].toString()),
            pregnancyId: Value(SyncCodec.text(json['pregnancy_id'])),
            name: Value(json['name']?.toString() ?? ''),
            deliveryDate: Value(
              SyncCodec.date(json['delivery_date']) ?? DateTime.now(),
            ),
            typeOfDelivery: Value(json['type_of_delivery']?.toString() ?? 'normal'),
            condition: Value(SyncCodec.text(json['condition'])),
            gender: Value(SyncCodec.text(json['gender'])),
            weight: Value(SyncCodec.number(json['weight'])),
            height: Value(SyncCodec.number(json['height'])),
            photo: Value(SyncCodec.encodeJson(json['photo'])),
            video: Value(SyncCodec.encodeJson(json['video'])),
            bloodGroup: Value(SyncCodec.text(json['blood_group'])),
            complications: Value(SyncCodec.encodeJson(json['complications'])),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.babies)
          ..where((b) => b.synced.equals(0))).get();
    return rows
        .map(
          (b) => <String, dynamic>{
            'id': b.id,
            'pregnancy_id': b.pregnancyId,
            'updated_at': SyncCodec.isoUtc(b.updatedAt),
            'name': b.name,
            'delivery_date': SyncCodec.isoUtc(b.deliveryDate),
            'type_of_delivery': b.typeOfDelivery,
            'condition': b.condition,
            'gender': b.gender,
            'weight': b.weight,
            'height': b.height,
            'photo': SyncCodec.decodeStringList(b.photo),
            'video': SyncCodec.decodeStringList(b.video),
            'blood_group': b.bloodGroup,
            'complications': SyncCodec.decodeStringList(b.complications),
          },
        )
        .toList();
  }
}

// ── Baby vaccinations ────────────────────────────────────────────────────────

class BabyVaccinationMapper extends _UuidKeyedMapper {
  const BabyVaccinationMapper();

  @override
  String get module => 'baby_vaccination';
  @override
  TableInfo<Table, dynamic> table(AppDriftDatabase db) =>
      db.babyImmunizationRecords;
  @override
  GeneratedColumn<String> idColumn(AppDriftDatabase db) =>
      db.babyImmunizationRecords.id;
  @override
  GeneratedColumn<int> syncedColumn(AppDriftDatabase db) =>
      db.babyImmunizationRecords.synced;
  @override
  GeneratedColumn<DateTime> syncedAtColumn(AppDriftDatabase db) =>
      db.babyImmunizationRecords.syncedAt;

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.babyImmunizationRecords)
        .insertOnConflictUpdate(
          BabyImmunizationRecordsCompanion(
            id: Value(json['id'].toString()),
            babyId: Value(SyncCodec.text(json['baby_id'])),
            vaccineName: Value(json['vaccine_name'].toString()),
            scheduledDate: Value(SyncCodec.date(json['scheduled_date'])),
            receivedDate: Value(SyncCodec.date(json['received_date'])),
            required: Value(SyncCodec.boolean(json['required']) ?? true),
            scheduledDateRangeFrom: Value(
              SyncCodec.date(json['scheduled_date_range_from']),
            ),
            scheduledDateRangeTo: Value(
              SyncCodec.date(json['scheduled_date_range_to']),
            ),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.babyImmunizationRecords)
          ..where((v) => v.synced.equals(0))).get();
    return rows
        .map(
          (v) => <String, dynamic>{
            'id': v.id,
            'baby_id': v.babyId,
            'updated_at': SyncCodec.isoUtc(v.updatedAt),
            'vaccine_name': v.vaccineName,
            'scheduled_date': SyncCodec.isoDate(v.scheduledDate),
            'received_date': SyncCodec.isoUtc(v.receivedDate),
            'required': v.required,
            'scheduled_date_range_from':
                SyncCodec.isoDate(v.scheduledDateRangeFrom),
            'scheduled_date_range_to': SyncCodec.isoDate(v.scheduledDateRangeTo),
          },
        )
        .toList();
  }
}

// ── Baby milestones ──────────────────────────────────────────────────────────

/// The one module keyed by a server-assigned integer.
///
/// That means the app cannot mint a milestone offline and have it keep its
/// identity, so this mapper never pushes inserts — only edits to rows the
/// server already seeded, which is all the UI offers.
class BabyMilestoneMapper extends SyncMapper {
  const BabyMilestoneMapper();

  @override
  String get module => 'milestone';

  @override
  Future<void> applyServerRow(
    AppDriftDatabase db,
    Map<String, dynamic> json,
  ) async {
    final id = SyncCodec.integer(json['id']);
    if (id == null) return;
    final updatedAt = SyncCodec.date(json['updated_at']);
    await db
        .into(db.babyMilestones)
        .insertOnConflictUpdate(
          BabyMilestonesCompanion(
            id: Value(id),
            babyId: Value(SyncCodec.text(json['baby_id'])),
            expectedDate: Value(SyncCodec.date(json['expected_date'])),
            milestone: Value(json['milestone']?.toString() ?? ''),
            description: Value(json['description']?.toString() ?? ''),
            completedAt: Value(SyncCodec.date(json['completed_at'])),
            createdAt: Value(SyncCodec.date(json['created_at']) ?? DateTime.now()),
            updatedAt: Value(updatedAt ?? DateTime.now()),
            deletedAt: Value(SyncCodec.date(json['deleted_at'])),
            syncedAt: Value(updatedAt),
            synced: const Value(1),
          ),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> dirtyRows(AppDriftDatabase db) async {
    final rows = await (db.select(db.babyMilestones)
          ..where((m) => m.synced.equals(0))).get();
    return rows
        .map(
          (m) => <String, dynamic>{
            'id': m.id,
            'baby_id': m.babyId,
            'updated_at': SyncCodec.isoUtc(m.updatedAt),
            'milestone': m.milestone,
            'description': m.description,
            'expected_date': SyncCodec.isoDate(m.expectedDate),
            'completed_at': SyncCodec.isoUtc(m.completedAt),
          },
        )
        .toList();
  }

  @override
  Future<void> markSynced(
    AppDriftDatabase db,
    List<String> ids,
    DateTime syncedAt,
  ) async {
    final intIds = ids.map(int.tryParse).whereType<int>().toList();
    if (intIds.isEmpty) return;
    await (db.update(db.babyMilestones)..where((m) => m.id.isIn(intIds))).write(
      BabyMilestonesCompanion(synced: const Value(1), syncedAt: Value(syncedAt)),
    );
  }

  @override
  Future<void> deleteRows(AppDriftDatabase db, List<String> ids) async {
    final intIds = ids.map(int.tryParse).whereType<int>().toList();
    if (intIds.isEmpty) return;
    await (db.delete(db.babyMilestones)..where((m) => m.id.isIn(intIds))).go();
  }

  @override
  Future<void> clear(AppDriftDatabase db) => db.delete(db.babyMilestones).go();
}

/// Every mapper, in dependency order.
///
/// Order matters on a pull: a pregnancy must land before its ANC rows and a
/// baby before its vaccinations, or the child rows reference a parent the local
/// database does not have yet. It matches the server's own module ordering.
const List<SyncMapper> kSyncMappers = [
  UserMapper(),
  HealthMapper(),
  VitalsMapper(),
  PregnancyMapper(),
  AncMapper(),
  PregnancyVaccinationMapper(),
  ReportChecklistMapper(),
  BabyMapper(),
  BabyVaccinationMapper(),
  BabyMilestoneMapper(),
];

final Map<String, SyncMapper> kSyncMappersByModule = {
  for (final mapper in kSyncMappers) mapper.module: mapper,
};
