// Local reads/writes for the meal screens, standing in for AlloConnect's
// HealthVitalsController.getVitalsHistory / updateVitalEntry / deleteVital.
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

class MealVitalsStore {
  const MealVitalsStore._();

  static String resolveUserId(String? userId) =>
      (userId != null && userId.trim().isNotEmpty)
      ? userId.trim()
      : MainController.instance.userId;

  static VitalsStreamResponse fromRow(Map<String, dynamic> map) {
    final rawData = map['data'];
    Map<String, dynamic>? parsedData;
    if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    } else if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) parsedData = Map<String, dynamic>.from(decoded);
      } catch (_) {
        parsedData = null;
      }
    }
    final created = map['createdAt'];
    return VitalsStreamResponse(
      id: map['id']?.toString() ?? '',
      key: (map['vital_key'] ?? map['key'])?.toString() ?? '',
      value: map['value'] is num
          ? (map['value'] as num).toDouble()
          : double.tryParse(map['value']?.toString() ?? '') ?? 0,
      unit: map['unit']?.toString() ?? '',
      createdAt: created is DateTime
          ? created
          : DateTime.tryParse(created?.toString() ?? '') ?? DateTime.now(),
      data: parsedData,
    );
  }

  /// Every row stored under [keys], plus generic `food` rows tagged with
  /// [foodType] (AlloConnect's shape), newest first, without duplicates.
  static Future<List<VitalsStreamResponse>> loadHistory(
    String userId, {
    required List<String> keys,
    required String foodType,
  }) async {
    final service = VitalsSqLiteService();
    final byId = <String, VitalsStreamResponse>{};
    for (final key in keys) {
      try {
        for (final row in await service.getVitalsHistory(userId, key)) {
          final v = fromRow(row);
          byId[v.id] = v;
        }
      } catch (e) {
        debugPrint('Error loading $key history: $e');
      }
    }
    try {
      for (final row in await service.getVitalsHistory(userId, 'food')) {
        final v = fromRow(row);
        if (v.data?['type'] == foodType || v.data?['meal_type'] == foodType) {
          byId[v.id] = v;
        }
      }
    } catch (e) {
      debugPrint('Error loading food history: $e');
    }
    return byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Rewrites an existing row in place and queues it for sync. The row keeps
  /// its key and sync bookkeeping (a replace would drop `synced_at`).
  static Future<void> updateVital({
    required String id,
    required double value,
    required String unit,
    required DateTime createdAt,
    required Map<String, dynamic> data,
  }) async {
    final db = await SqLiteService().database;
    await (db.update(
      db.vitalsStreamTable,
    )..where((t) => t.id.equals(id))).write(
      VitalsStreamTableCompanion(
        value: Value(value),
        unit: Value(unit),
        createdAt: Value(createdAt),
        data: Value(jsonEncode(data)),
        updatedAt: Value(DateTime.now()),
        synced: const Value(0),
      ),
    );
    await _refresh();
  }

  static Future<void> deleteVital(String id) async {
    await VitalsSqLiteService().deleteVital(id);
    await _refresh();
  }

  static Future<void> _refresh() async {
    final controller = HealthVitalsController.instance;
    await controller.fetchLatestVitals(showLoading: false);
    // Pushes the edit/deletion when online; a no-op offline.
    unawaited(controller.syncUnsyncedVitals());
  }
}
