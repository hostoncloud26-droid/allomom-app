import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class VitalsSqLiteService {
  static final VitalsSqLiteService _instance = VitalsSqLiteService._internal();
  factory VitalsSqLiteService() => _instance;
  VitalsSqLiteService._internal();

  final _uuid = const Uuid();

  Map<String, dynamic> _toMap(Vital vital) {
    return {
      'id': vital.id,
      'vital_key': vital.vitalKey,
      'value': vital.value,
      'unit': vital.unit,
      'createdAt': vital.createdAt,
      'user_id': vital.userId,
      'data': vital.data,
      'synced': vital.synced,
    };
  }

  /// Saves a vital entry to the local database.
  /// If [id] is not provided, generates a UUID v7.
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
    final String recordId = id ?? _uuid.v7();
    final String targetUserId = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : UserSessionManager.instance.userId;

    await db
        .into(db.vitals)
        .insert(
          VitalsCompanion(
            id: Value(recordId),
            vitalKey: Value(key),
            value: Value(value),
            unit: Value(unit),
            createdAt: Value(createdAt),
            userId: Value(targetUserId.isNotEmpty ? targetUserId : null),
            data: Value(
              additionalData != null ? jsonEncode(additionalData) : null,
            ),
            synced: Value(synced),
          ),
          mode: InsertMode.insertOrReplace,
        );

    return recordId;
  }

  /// Saves a VitalsStreamResponse to the local database.
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

  /// Bulk saves a list of VitalsStreamResponse objects.
  Future<void> saveVitalsStreamResponsesBulk(
    List<VitalsStreamResponse> responses, {
    int synced = 1,
    String? userId,
  }) async {
    final db = await SqLiteService().database;
    final String targetUserId = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : UserSessionManager.instance.userId;

    await db.batch((batch) {
      for (var response in responses) {
        final recordId = response.id.isNotEmpty ? response.id : _uuid.v7();
        batch.insert(
          db.vitals,
          VitalsCompanion(
            id: Value(recordId),
            vitalKey: Value(response.key),
            value: Value(response.value),
            unit: Value(response.unit),
            createdAt: Value(response.createdAt),
            userId: Value(targetUserId.isNotEmpty ? targetUserId : null),
            data: Value(
              response.data != null ? jsonEncode(response.data) : null,
            ),
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
    final String targetUserId = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : UserSessionManager.instance.userId;
    if (targetUserId.isEmpty) return false;

    final day = on ?? DateTime.now();
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final row = await (db.select(db.vitals)
          ..where((tbl) =>
              tbl.userId.equals(targetUserId) &
              tbl.vitalKey.equals(key) &
              tbl.createdAt.isBiggerOrEqualValue(start) &
              tbl.createdAt.isSmallerThanValue(end))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return false;

    final merged = <String, dynamic>{..._decodeData(row.data), ...data};

    await (db.update(db.vitals)..where((tbl) => tbl.id.equals(row.id))).write(
      VitalsCompanion(
        data: Value(jsonEncode(merged)),
        synced: const Value(0),
      ),
    );

    return true;
  }

  Map<String, dynamic> _decodeData(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
    } catch (_) {
      // A row whose data is not JSON is replaced rather than lost to a throw.
      return <String, dynamic>{};
    }
  }

  /// Retrieves all unsynced vital records.
  Future<List<Map<String, dynamic>>> getUnsyncedVitals() async {
    final db = await SqLiteService().database;
    final rows =
        await (db.select(db.vitals)
              ..where((tbl) => tbl.synced.equals(0))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();

    return rows.map(_toMap).toList();
  }

  /// Marks a vital record as synced.
  Future<void> markAsSynced(String id) async {
    final db = await SqLiteService().database;
    await (db.update(db.vitals)..where((tbl) => tbl.id.equals(id))).write(
      const VitalsCompanion(synced: Value(1)),
    );
  }

  /// Retrieves vitals history for a specific user and type with optional date filtering.
  Future<List<Map<String, dynamic>>> getVitalsHistory(
    String userId,
    String key, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await SqLiteService().database;

    final query = db.select(db.vitals)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.vitalKey.equals(key));

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

  /// Retrieves all vitals for a specific user (all vital types).
  Future<List<Map<String, dynamic>>> getAllVitalsForUser(String userId) async {
    final db = await SqLiteService().database;
    final rows = await (db.select(db.vitals)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    return rows.map(_toMap).toList();
  }

  /// Retrieves the latest vital per key for a specific user.
  Future<List<Map<String, dynamic>>> getLatestVitals(String userId) async {
    final db = await SqLiteService().database;
    final rows = await (db.select(db.vitals)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    final latestByKey = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final map = _toMap(row);
      final key = map['vital_key'] as String?;
      if (key == null || latestByKey.containsKey(key)) {
        continue;
      }
      latestByKey[key] = map;
    }

    return latestByKey.values.toList();
  }

  /// Deletes a vital record by ID.
  Future<void> deleteVital(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.vitals)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Deletes all vital records where key is 'deleted' and synced is 1.
  Future<void> deleteSyncedDeletedVitals() async {
    final db = await SqLiteService().database;
    await (db.delete(db.vitals)..where(
          (tbl) => tbl.vitalKey.equals('deleted') & tbl.synced.equals(1),
        ))
        .go();
  }

  /// Clears all vitals records.
  Future<void> clearAll() async {
    final db = await SqLiteService().database;
    await db.delete(db.vitals).go();
  }
}
