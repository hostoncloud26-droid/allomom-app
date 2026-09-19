import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Local reads and writes for the vitals stream.
///
/// Now backed by `vitals_stream`, matching allomom-api-new. The visible change
/// is what a reading is scoped by: rows hang off the health record, not the
/// user, because that is the server's own shape. The `userId` parameters here
/// are kept so the existing screens compile unchanged; they resolve to the
/// signed-in user's health record, which is the only one a device holds.
class VitalsSqLiteService {
  static final VitalsSqLiteService _instance = VitalsSqLiteService._internal();
  factory VitalsSqLiteService() => _instance;
  VitalsSqLiteService._internal();

  final _uuid = const Uuid();

  /// The health record readings hang off.
  ///
  /// Prefers the loaded session, and otherwise reads the single health row the
  /// local database holds. A device stores exactly one account, so that row is
  /// unambiguous — and the fallback means a reading written before the
  /// controllers have finished loading still lands on the right record instead
  /// of being orphaned with a null scope.
  Future<String> _resolveHealthId() async {
    final fromSession = MainController.instance.healthDataId;
    if (fromSession.isNotEmpty) return fromSession;

    final db = await SqLiteService().database;
    final row = await (db.select(db.healthDataTable)..limit(1))
        .getSingleOrNull();
    return row?.id ?? '';
  }

  /// Presents a row in the shape the screens already read, so the column rename
  /// from `vital_key` to `key` stays inside this file.
  Map<String, dynamic> _toMap(VitalsStreamTableData vital) {
    return {
      'id': vital.id,
      'vital_key': vital.key,
      'key': vital.key,
      'value': vital.value,
      'unit': vital.unit,
      'createdAt': vital.createdAt,
      'user_id': MainController.instance.userId,
      'health_id': vital.healthId,
      'data': vital.data,
      'synced': vital.synced,
    };
  }

  /// Saves a reading. Generates a UUID when [id] is omitted.
  Future<String> saveVital({
    String? id,
    required String key,
    required double value,
    required String unit,
    required DateTime createdAt,
    String? userId,
    Map<String, dynamic>? additionalData,
    int synced = 0,
  }) async {
    final db = await SqLiteService().database;
    final recordId = id ?? _uuid.v7();
    final healthId = await _resolveHealthId();
    final now = DateTime.now();

    await db
        .into(db.vitalsStreamTable)
        .insert(
          VitalsStreamTableCompanion(
            id: Value(recordId),
            key: Value(key),
            value: Value(value),
            unit: Value(unit),
            createdAt: Value(createdAt),
            healthId: Value(healthId.isNotEmpty ? healthId : null),
            data: Value(
              additionalData != null ? jsonEncode(additionalData) : null,
            ),
            updatedAt: Value(now),
            synced: Value(synced),
          ),
          mode: InsertMode.insertOrReplace,
        );

    return recordId;
  }

  Future<void> saveVitalsStreamResponse(
    VitalsStreamResponse response, {
    int synced = 1,
    String? userId,
  }) async {
    await saveVital(
      id: response.id.isNotEmpty ? response.id : null,
      key: response.key,
      value: response.value,
      unit: response.unit,
      createdAt: response.createdAt,
      userId: userId,
      additionalData: response.data,
      synced: synced,
    );
  }

  Future<void> saveVitalsStreamResponsesBulk(
    List<VitalsStreamResponse> responses, {
    int synced = 1,
    String? userId,
  }) async {
    final db = await SqLiteService().database;
    final healthId = await _resolveHealthId();
    final now = DateTime.now();

    await db.batch((batch) {
      for (final response in responses) {
        final recordId = response.id.isNotEmpty ? response.id : _uuid.v7();
        batch.insert(
          db.vitalsStreamTable,
          VitalsStreamTableCompanion(
            id: Value(recordId),
            key: Value(response.key),
            value: Value(response.value),
            unit: Value(response.unit),
            createdAt: Value(response.createdAt),
            healthId: Value(healthId.isNotEmpty ? healthId : null),
            data: Value(
              response.data != null ? jsonEncode(response.data) : null,
            ),
            updatedAt: Value(now),
            synced: Value(synced),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Merges [data] into the newest row for [key] recorded on [on] (today by
  /// default), and reports whether there was a row to merge into.
  ///
  /// Used to attach a detail to a reading that is already logged — what she
  /// ate against the meal's own row — rather than writing a second row that
  /// every sum over the day would then count twice. The value is left alone;
  /// only `data` changes, and the row goes back to unsynced so the note
  /// reaches the server.
  Future<bool> mergeDataIntoLatest({
    required String key,
    required Map<String, dynamic> data,
    String? userId,
    DateTime? on,
  }) async {
    final db = await SqLiteService().database;
    final healthId = await _resolveHealthId();
    if (healthId.isEmpty) return false;

    final day = on ?? DateTime.now();
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final row =
        await (db.select(db.vitalsStreamTable)
              ..where(
                (tbl) =>
                    tbl.healthId.equals(healthId) &
                    tbl.key.equals(key) &
                    tbl.deletedAt.isNull() &
                    tbl.createdAt.isBiggerOrEqualValue(start) &
                    tbl.createdAt.isSmallerThanValue(end),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return false;

    final merged = <String, dynamic>{..._decodeData(row.data), ...data};

    await (db.update(db.vitalsStreamTable)
          ..where((tbl) => tbl.id.equals(row.id)))
        .write(
          VitalsStreamTableCompanion(
            data: Value(jsonEncode(merged)),
            updatedAt: Value(DateTime.now()),
            synced: const Value(0),
          ),
        );

    return true;
  }

  Map<String, dynamic> _decodeData(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      // A row whose data is not JSON is replaced rather than lost to a throw.
      return <String, dynamic>{};
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedVitals() async {
    final db = await SqLiteService().database;
    final rows =
        await (db.select(db.vitalsStreamTable)
              ..where((tbl) => tbl.synced.equals(0))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();

    return rows.map(_toMap).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await SqLiteService().database;
    await (db.update(db.vitalsStreamTable)..where((tbl) => tbl.id.equals(id)))
        .write(const VitalsStreamTableCompanion(synced: Value(1)));
  }

  Future<List<Map<String, dynamic>>> getVitalsHistory(
    String userId,
    String key, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await SqLiteService().database;
    final healthId = await _resolveHealthId();

    final query = db.select(db.vitalsStreamTable)
      ..where(
        (tbl) =>
            tbl.healthId.equals(healthId) &
            tbl.key.equals(key) &
            tbl.deletedAt.isNull(),
      );

    if (fromDate != null) {
      query.where((tbl) => tbl.createdAt.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((tbl) => tbl.createdAt.isSmallerOrEqualValue(toDate));
    }

    query.orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final rows = await query.get();
    return rows.map(_toMap).toList();
  }

  Future<List<Map<String, dynamic>>> getAllVitalsForUser(String userId) async {
    final db = await SqLiteService().database;
    final healthId = await _resolveHealthId();
    final rows =
        await (db.select(db.vitalsStreamTable)
              ..where(
                (tbl) => tbl.healthId.equals(healthId) & tbl.deletedAt.isNull(),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();

    return rows.map(_toMap).toList();
  }

  /// The newest reading per key.
  Future<List<Map<String, dynamic>>> getLatestVitals(String userId) async {
    final db = await SqLiteService().database;
    final healthId = await _resolveHealthId();
    final rows =
        await (db.select(db.vitalsStreamTable)
              ..where(
                (tbl) => tbl.healthId.equals(healthId) & tbl.deletedAt.isNull(),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();

    final latestByKey = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      if (latestByKey.containsKey(row.key)) continue;
      latestByKey[row.key] = _toMap(row);
    }

    return latestByKey.values.toList();
  }

  /// Soft delete, so the removal reaches the server. A hard delete would be
  /// re-pulled on the next sync.
  Future<void> deleteVital(String id) async {
    final db = await SqLiteService().database;
    final now = DateTime.now();
    await (db.update(db.vitalsStreamTable)..where((tbl) => tbl.id.equals(id)))
        .write(
          VitalsStreamTableCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            synced: const Value(0),
          ),
        );
  }

  /// Clears rows already soft-deleted and confirmed by the server.
  Future<void> deleteSyncedDeletedVitals() async {
    final db = await SqLiteService().database;
    await (db.delete(db.vitalsStreamTable)
          ..where((tbl) => tbl.deletedAt.isNotNull() & tbl.synced.equals(1)))
        .go();
  }

  Future<void> clearAll() async {
    final db = await SqLiteService().database;
    await db.delete(db.vitalsStreamTable).go();
  }
}
