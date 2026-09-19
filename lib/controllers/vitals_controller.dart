import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sync/sync_service.dart';

/// Well-known keys in the vitals stream.
///
/// Anything measured over time lives here rather than as a single field on the
/// health profile, so it keeps a history. That now includes the cycle: the
/// health record no longer carries `average_cycle` or `pregnancy_status`, so
/// the tracker reads [periodStart] and [cycleLength] readings instead.
class VitalKeys {
  const VitalKeys._();

  static const weight = 'weight';
  static const height = 'height';
  static const bmi = 'bmi';
  static const bloodPressure = 'blood_pressure';
  static const bloodPressureSystolic = 'bp_systolic';
  static const bloodPressureDiastolic = 'bp_diastolic';
  static const heartRate = 'heart_rate';
  static const hrv = 'hrv';
  static const bloodGlucose = 'blood_glucose';
  static const bloodOxygen = 'blood_oxygen';
  static const haemoglobin = 'haemoglobin';
  static const temperature = 'temperature';
  static const steps = 'steps';
  static const sleep = 'sleep';
  static const stress = 'stress';
  static const calories = 'calories';
  static const water = 'water';

  /// The first day of a period. The cycle predictor reads the series of these.
  static const periodStart = 'period_start';

  /// An observed cycle length in days.
  static const cycleLength = 'cycle_length';

  /// An observed period duration in days.
  static const periodDuration = 'period_duration';

  /// Blood group, carried in [VitalsStreamTableData.data] since it is not a
  /// number. Stored as a reading so it has a provenance and a date.
  static const bloodGroup = 'blood_group';
}

/// The vitals stream: every measurement the app records, with its history.
class VitalsController extends GetxController {
  static VitalsController get instance => Get.isRegistered<VitalsController>()
      ? Get.find<VitalsController>()
      : Get.put(VitalsController._(), permanent: true);

  VitalsController._();

  static const _uuid = Uuid();

  /// Readings grouped by key, newest first within each key.
  final Map<String, List<VitalsStreamTableData>> _byKey = {};

  List<VitalsStreamTableData> readings(String key) => _byKey[key] ?? const [];

  VitalsStreamTableData? latest(String key) {
    final list = _byKey[key];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  double? latestValue(String key) => latest(key)?.value;

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── Local reads ────────────────────────────────────────────────────────────

  Future<void> loadFromLocal() async {
    final db = await _db;
    final healthId = MainController.instance.healthDataId;

    _byKey.clear();
    if (healthId.isEmpty) {
      update();
      return;
    }

    final rows =
        await (db.select(db.vitalsStreamTable)
              ..where(
                (v) => v.healthId.equals(healthId) & v.deletedAt.isNull(),
              )
              ..orderBy([(v) => drift.OrderingTerm.desc(v.createdAt)]))
            .get();

    for (final row in rows) {
      _byKey.putIfAbsent(row.key, () => []).add(row);
    }
    update();
  }

  void reset() {
    _byKey.clear();
    update();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Records a reading locally, then lets sync push it.
  ///
  /// The id is generated here rather than by the server so the row keeps its
  /// identity across a retry — a reading taken offline and pushed twice lands
  /// on the same row instead of being double-counted.
  Future<String?> record(
    String key, {
    double? value,
    String? unit,
    Map<String, dynamic>? data,
    DateTime? recordedAt,
  }) async {
    final healthId = MainController.instance.healthDataId;
    if (healthId.isEmpty) return null;

    final db = await _db;
    final id = _uuid.v4();
    final now = DateTime.now();

    await db
        .into(db.vitalsStreamTable)
        .insert(
          VitalsStreamTableCompanion.insert(
            id: id,
            key: key,
            healthId: drift.Value(healthId),
            value: drift.Value(value),
            unit: drift.Value(unit),
            data: drift.Value(data == null ? null : jsonEncode(data)),
            createdAt: drift.Value(recordedAt ?? now),
            updatedAt: drift.Value(now),
            synced: const drift.Value(0),
          ),
        );

    await loadFromLocal();
    if (await SyncService.instance.syncModule('vitals')) {
      await loadFromLocal();
    }
    return id;
  }

  /// Records several readings taken at the same moment, such as a blood
  /// pressure pair, in one local write and one push.
  Future<void> recordBatch(
    List<({String key, double? value, String? unit})> entries, {
    DateTime? recordedAt,
  }) async {
    final healthId = MainController.instance.healthDataId;
    if (healthId.isEmpty || entries.isEmpty) return;

    final db = await _db;
    final now = DateTime.now();

    await db.batch((batch) {
      for (final entry in entries) {
        batch.insert(
          db.vitalsStreamTable,
          VitalsStreamTableCompanion.insert(
            id: _uuid.v4(),
            key: entry.key,
            healthId: drift.Value(healthId),
            value: drift.Value(entry.value),
            unit: drift.Value(entry.unit),
            createdAt: drift.Value(recordedAt ?? now),
            updatedAt: drift.Value(now),
            synced: const drift.Value(0),
          ),
        );
      }
    });

    await loadFromLocal();
    if (await SyncService.instance.syncModule('vitals')) {
      await loadFromLocal();
    }
  }

  Future<bool> deleteReading(String id) async {
    final db = await _db;
    final now = DateTime.now();
    await (db.update(db.vitalsStreamTable)..where((v) => v.id.equals(id))).write(
      VitalsStreamTableCompanion(
        deletedAt: drift.Value(now),
        updatedAt: drift.Value(now),
        synced: const drift.Value(0),
      ),
    );
    await loadFromLocal();
    await SyncService.instance.syncModule('vitals');
    return true;
  }

  // ── Cycle ──────────────────────────────────────────────────────────────────

  /// Period start dates, newest first.
  List<DateTime> get periodStarts =>
      readings(VitalKeys.periodStart).map((r) => r.createdAt).toList();

  /// The most recent period start, which is the LMP the cycle predictor uses.
  DateTime? get lastPeriodStart => periodStarts.isEmpty ? null : periodStarts.first;

  /// Average observed cycle length, or null if there is nothing recorded.
  ///
  /// Prefers explicitly logged [VitalKeys.cycleLength] readings and otherwise
  /// derives it from the gaps between period starts, which needs at least two.
  double? get averageCycleLength {
    final logged = readings(VitalKeys.cycleLength)
        .map((r) => r.value)
        .whereType<double>()
        .toList();
    if (logged.isNotEmpty) {
      return logged.reduce((a, b) => a + b) / logged.length;
    }

    final starts = periodStarts;
    if (starts.length < 2) return null;
    final gaps = <int>[];
    for (var i = 0; i < starts.length - 1; i++) {
      final gap = starts[i].difference(starts[i + 1]).inDays;
      // Ignore impossible gaps — a mis-entered date should not drag the mean.
      if (gap >= 15 && gap <= 60) gaps.add(gap);
    }
    if (gaps.isEmpty) return null;
    return gaps.reduce((a, b) => a + b) / gaps.length;
  }

  double? get averagePeriodDuration {
    final logged = readings(VitalKeys.periodDuration)
        .map((r) => r.value)
        .whereType<double>()
        .toList();
    if (logged.isEmpty) return null;
    return logged.reduce((a, b) => a + b) / logged.length;
  }

  /// Logs the first day of a period.
  Future<String?> recordPeriodStart(DateTime date, {int? durationDays}) async {
    final id = await record(
      VitalKeys.periodStart,
      value: 1,
      unit: 'day',
      recordedAt: date,
    );
    if (durationDays != null) {
      await record(
        VitalKeys.periodDuration,
        value: durationDays.toDouble(),
        unit: 'days',
        recordedAt: date,
      );
    }
    return id;
  }

  /// The blood group, read from the latest reading carrying one.
  String? get bloodGroup {
    final reading = latest(VitalKeys.bloodGroup);
    if (reading == null) return null;
    final data = SyncCodec.decodeMap(reading.data);
    return data['value']?.toString();
  }

  Future<void> setBloodGroup(String group) =>
      record(VitalKeys.bloodGroup, data: {'value': group}).then((_) {});
}
