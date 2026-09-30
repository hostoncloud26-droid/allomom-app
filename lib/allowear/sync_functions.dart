import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/device_raw_vitals_storage.dart';
import 'package:allomom/allowear/vitals_verification_storage.dart';
import 'package:allomom/allowear/compat/user_api.dart';
import 'package:allomom/allowear/compat/vitals_api.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vital_sync_item.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:localstorage/localstorage.dart';
import 'package:uuid/uuid.dart';
import 'package:allowear_sdk/allowear_sdk.dart';

/// The locally remembered connect ID of the paired wearable, or `null` when
/// no device has been paired on this phone.
String? getConnectedAllowearMac() {
  final mac = localStorage.getItem('allowear_connected_device_mac')?.trim();
  return (mac == null || mac.isEmpty) ? null : mac;
}

/// The wearable's hardware MAC (`AA:BB:CC:DD:EE:FF`) as read from the SDK,
/// for tagging data sent to the server. Falls back to the connect ID when the
/// device has not reported one yet.
String? getAllowearDeviceMac() {
  final mac = localStorage.getItem('allowear_device_mac')?.trim();
  if (mac != null && mac.isNotEmpty) return mac;
  return getConnectedAllowearMac();
}

/// Result of vitals data validation.
///
/// [validVitals] — vitals confirmed during worn periods (steps > 0 or sleep).
/// [unverifiedVitals] — vitals from unknown periods, stored for later re-check.
class CheckedVitalsResult {
  final List<VitalSyncItem> validVitals;
  final List<VitalSyncItem> unverifiedVitals;

  CheckedVitalsResult({
    required this.validVitals,
    required this.unverifiedVitals,
  });
}

String _hourKey(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}-${t.hour.toString().padLeft(2, '0')}';

/// Validates vitals data against step activity and sleep sessions.
///
/// ### Validation rules
/// 1. If a vital's timestamp falls within a **sleep session**
///    (`start` → `end`) → **valid**.
/// 2. If the **hourly step count > 0** for the vital's hour → **valid**.
/// 3. Otherwise → **unverified** (device may not have been worn).
///
/// Previously stored unverified vitals (from the `InitialSetup` table) are
/// re-checked against the current sleep data so they can be recovered if new
/// sleep data now covers their timestamps.
Future<CheckedVitalsResult> checkVitalsData({
  required List<VitalSyncItem> vitalsItems,
  required List<DailySteps> stepData,
  required List<SleepSession> sleepData,
}) async {
  // ── 1. Build a set of "active hours" from step data ────────────────────
  //    Key format: "YYYY-MM-DD-HH" (e.g. "2026-05-22-14"). The SDK already
  //    hands every day back as local midnight, so the calendar day is stable.
  final Set<String> activeHours = {};
  for (final day in stepData) {
    for (final item in day.hourly) {
      if (item.steps > 0) {
        activeHours.add(_hourKey(DateTime(
            day.date.year, day.date.month, day.date.day, item.hour)));
      }
    }
  }
  print('CHECK_VITALS: Active hours with steps > 0: ${activeHours.length}');

  // ── 2. Build sleep time ranges ─────────────────────────────────────────
  final List<_TimeRange> sleepRanges = [];
  for (final sleep in sleepData) {
    if (sleep.start.millisecondsSinceEpoch > 0 && sleep.end.isAfter(sleep.start)) {
      sleepRanges.add(_TimeRange(start: sleep.start, end: sleep.end));
    }
  }
  print('CHECK_VITALS: Sleep ranges found: ${sleepRanges.length}');

  // ── 3. Load previously unverified vitals ───────────────────────────────
  final List<VitalSyncItem> previouslyUnverified =
      await VitalsVerificationStorage.getUnverifiedVitals();
  print(
      'CHECK_VITALS: Previously unverified vitals loaded: ${previouslyUnverified.length}');

  // ── 4. Validate each vital ─────────────────────────────────────────────
  final List<VitalSyncItem> valid = [];
  final List<VitalSyncItem> unverified = [];

  // Combine current vitals + previously unverified for a single pass
  final allToCheck = [...vitalsItems, ...previouslyUnverified];

  // Keep track of which previously unverified vitals were recovered
  final Set<String> previouslyUnverifiedIds =
      previouslyUnverified.map((v) => v.id).toSet();

  for (final vital in allToCheck) {
    final ts = vital.createdAt;
    if (ts == null) {
      unverified.add(vital);
      continue;
    }

    // Scheduled vital captures are taken hourly (00-01 min) and half-hourly (30-31 min).
    // All other vitals (manually triggered) are automatically valid.
    final bool isScheduledCapture = (ts.minute == 0 || ts.minute == 1) ||
        (ts.minute == 30 || ts.minute == 31);

    if (!isScheduledCapture) {
      valid.add(vital);
      if (previouslyUnverifiedIds.contains(vital.id)) {
        print(
            'CHECK_VITALS: Recovered unverified vital: [${vital.key}] value: ${vital.value} recorded at ${ts} (Bypassed: Manually triggered at minute ${ts.minute})');
      }
      continue;
    }

    // Check sleep ranges first (more definitive signal)
    bool inSleep = false;
    for (final range in sleepRanges) {
      if (!ts.isBefore(range.start) && !ts.isAfter(range.end)) {
        inSleep = true;
        break;
      }
    }

    if (inSleep) {
      valid.add(vital);
      if (previouslyUnverifiedIds.contains(vital.id)) {
        print(
            'CHECK_VITALS: Recovered unverified vital: [${vital.key}] value: ${vital.value} recorded at ${ts} (Verified by Sleep Session)');
      }
      continue;
    }

    // Check step activity for the current hour and the last hour (H and H-1)
    final currentHourKey = _hourKey(ts);
    final lastHourKey = _hourKey(ts.subtract(const Duration(hours: 1)));

    if (activeHours.contains(currentHourKey) &&
        activeHours.contains(lastHourKey)) {
      valid.add(vital);
      if (previouslyUnverifiedIds.contains(vital.id)) {
        print(
            'CHECK_VITALS: Recovered unverified vital: [${vital.key}] value: ${vital.value} recorded at ${ts} (Verified by step activity in current hour ${currentHourKey} and last hour ${lastHourKey})');
      }
      continue;
    }

    // Neither sleep nor steps → unverified
    unverified.add(vital);
  }

  print(
      'CHECK_VITALS: Result — valid: ${valid.length}, unverified: ${unverified.length}');

  // ── 5. Persist remaining unverified vitals for next sync ───────────────
  if (unverified.isNotEmpty) {
    await VitalsVerificationStorage.saveUnverifiedVitals(unverified);
  } else {
    await VitalsVerificationStorage.clearUnverifiedVitals();
  }

  return CheckedVitalsResult(
    validVitals: valid,
    unverifiedVitals: unverified,
  );
}

/// Simple time range helper.
class _TimeRange {
  final DateTime start;
  final DateTime end;
  _TimeRange({required this.start, required this.end});
}

Future<void> syncHealthDataToServer(
  String bluetoothMac,
  HealthSyncResult result,
) async {
  final deviceType = result.deviceType;

  // ── Convert raw sensor data to VitalSyncItems ──────────────────────────
  final List<VitalSyncItem> allVitals = [];
  allVitals.addAll(convertHeartRateData(result.heartRate, deviceType));
  allVitals.addAll(convertBloodOxygenData(result.spo2, deviceType));
  allVitals.addAll(convertHrvData(result.hrv, deviceType));
  allVitals.addAll(convertStressData(result.stress, deviceType));
  allVitals.addAll(convertTemperatureData(result.temperature, deviceType));
  allVitals.addAll(convertBloodPressureData(result.bloodPressure, deviceType));

  // The Allowear Fit's history is erased after every sync (see below), so it
  // only ever hands back what it recorded since the last one.
  final clearsAfterSync = result.deviceType == AllowearDeviceType.v8;

  var stepItems = convertStepData(result.steps, deviceType);
  if (clearsAfterSync) stepItems = await _mergeWithStoredSteps(stepItems);
  final sleepItems = convertSleepToServerFormat(result.sleep, deviceType);

  // ── Store device raw vitals (including steps and sleep) before validation ──
  final List<VitalSyncItem> rawDeviceItems = [
    ...allVitals,
    ...stepItems,
    ...sleepItems,
  ];
  if (rawDeviceItems.isNotEmpty) {
    await DeviceRawVitalsStorage.addRawVitals(rawDeviceItems);
  }

  // ── Validate vitals against step & sleep data ──────────────────────────
  // The Allowear Fit's vitals are taken as recorded, without the worn check.
  final List<VitalSyncItem> validVitals;
  if (clearsAfterSync) {
    validVitals = allVitals;
    print('SYNC: ${validVitals.length} vitals (worn check skipped for V8)');
  } else {
    final checked = await checkVitalsData(
      vitalsItems: allVitals,
      stepData: result.steps,
      sleepData: result.sleep,
    );
    validVitals = checked.validVitals;
    print(
        'SYNC: ${validVitals.length} valid vitals, ${checked.unverifiedVitals.length} unverified (stored for later)');
  }

  // Convert valid vitals to JSON for the API call
  final List<Map<String, dynamic>> jsonData =
      validVitals.map((item) => item.toJson()).toList();

  print("Syncing the following health data to server:");

  // Steps stay one aggregated row per day, but each sleep record is its own
  // session (a nap and a night are separate items), so sleep is stored by its
  // stable session id instead of being merged into a single daily row.

  // Save valid vitals to local database (mark as unsynced initially)
  await VitalsSqLiteService().saveVitalsBulk(validVitals, synced: 0);
  await VitalsSqLiteService()
      .saveVitalsBulkDailyDataWithIds(stepItems, synced: 0);
  await VitalsSqLiteService().saveVitalsBulk(sleepItems, synced: 0);

  // Everything is in the local db now, unsynced rows included, and the
  // background sync uploads whatever this call fails to — so the device's
  // copy can go. The next sync then only returns new records.
  if (clearsAfterSync) {
    try {
      await AllowearSdk.instance.clearDeviceData();
      print('SYNC: cleared device history after saving locally');
    } catch (e) {
      print('SYNC: clearing device history failed: $e');
    }
  }

  // Steps and sleep are always valid — add them to the sync payload
  jsonData.addAll(stepItems.map((e) => e.toJson()).toList());
  jsonData.addAll(sleepItems.map((e) => e.toJson()).toList());

  Get.find<HealthVitalsController>().fetchLatestVitals();

  if (jsonData.isEmpty) {
    Fluttertoast.showToast(
      msg: "No health data to sync".tr,
      gravity: ToastGravity.BOTTOM,
    );
    return;
  }

  final req = await VitalsApi.syncDataBulk(bluetoothMac, jsonData);

  if (req.success) {
    // Update local database (mark as synced)
    await VitalsSqLiteService().saveVitalsBulk(validVitals, synced: 1);
    await VitalsSqLiteService()
        .saveVitalsBulkDailyDataWithIds(stepItems, synced: 1);
    await VitalsSqLiteService().saveVitalsBulk(sleepItems, synced: 1);
    // Fluttertoast.showToast(
    //   msg: "Health data synced successfully".tr,
    //   gravity: ToastGravity.BOTTOM,
    // );
  } else {
    // Fluttertoast.showToast(
    //   msg: "Failed to sync: ${req.detail}".tr,
    //   gravity: ToastGravity.BOTTOM,
    // );
  }
}

String formatDateFromTimeStamp(int timestamp) {
  if (timestamp <= 0) {
    return DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
  }

  // iOS sync payloads are typically already in milliseconds, while some sources use seconds.
  final normalizedMillis =
      timestamp > 1000000000000 ? timestamp : timestamp * 1000;
  final date = DateTime.fromMillisecondsSinceEpoch(normalizedMillis);

  return date.toIso8601String();
}

/// Tags every synced record: `source` is always "allowear", and
/// `device_type` names the model ("v1" bracelet, "v8" Allowear Fit, "nx").
Map<String, dynamic> _deviceTag(AllowearDeviceType deviceType) => {
      "source": "allowear",
      "device_type": deviceType.id,
    };

List<VitalSyncItem> convertStepData(List<DailySteps> stepData,
    AllowearDeviceType deviceType) {
  return stepData
      .map((step) => VitalSyncItem(
              key: "steps",
              value: step.totalSteps.toDouble(),
              createdAt: step.date,
              unit: "steps",
              data: {
                ..._deviceTag(deviceType),
                "distance": step.totalDistance,
                "calories": step.totalCalories,
                "steps": step.totalSteps,
                "hourly_data": step.hourly
                    .map((e) => {
                          "hour": e.hour,
                          "steps": e.steps,
                          "calorie": e.calories,
                          "distance": e.distance,
                        })
                    .toList(),
              }))
      .toList();
}

List<VitalSyncItem> _convertSamples(
  List<VitalSample> samples, {
  required String key,
  required String unit,
  required AllowearDeviceType deviceType,
}) {
  return samples
      .map((sample) => VitalSyncItem(
            key: key,
            value: sample.value.toDouble(),
            createdAt: sample.time,
            unit: unit,
            data: {
              ..._deviceTag(deviceType),
            },
          ))
      .toList();
}

List<VitalSyncItem> convertHeartRateData(List<VitalSample> heartRateData,
        AllowearDeviceType deviceType) =>
    _convertSamples(heartRateData,
        key: "heart_rate", unit: "bpm", deviceType: deviceType);

List<VitalSyncItem> convertBloodOxygenData(List<VitalSample> bloodOxygenData,
        AllowearDeviceType deviceType) =>
    _convertSamples(bloodOxygenData,
        key: "blood_oxygen", unit: "%", deviceType: deviceType);

List<VitalSyncItem> convertHrvData(List<VitalSample> hrvData,
        AllowearDeviceType deviceType) =>
    _convertSamples(hrvData, key: "hrv", unit: "ms", deviceType: deviceType);

List<VitalSyncItem> convertStressData(List<VitalSample> stressData,
        AllowearDeviceType deviceType) =>
    _convertSamples(stressData, key: "stress", unit: "level", deviceType: deviceType);

/// Skin / body temperature in °C.
List<VitalSyncItem> convertTemperatureData(List<VitalSample> temperatureData,
        AllowearDeviceType deviceType) =>
    _convertSamples(temperatureData,
        key: "temperature", unit: "°C", deviceType: deviceType);

/// Blood pressure in the shape manual entries already use: the systolic value
/// as the row's value, with both numbers in `data`.
List<VitalSyncItem> convertBloodPressureData(
    List<BloodPressureSample> bloodPressureData,
    AllowearDeviceType deviceType) {
  return bloodPressureData
      .map((bp) => VitalSyncItem(
            key: "blood_pressure",
            value: bp.systolic.toDouble(),
            createdAt: bp.time,
            unit: "mmHg",
            data: {
              ..._deviceTag(deviceType),
              "systolic": bp.systolic,
              "diastolic": bp.diastolic,
            },
          ))
      .toList();
}

/// Folds each synced day into the one already stored for that date.
///
/// The daily save replaces the stored day outright, and after an erase the
/// ring only reports the hours since — so the synced day is laid over the
/// stored one first. The ring reports every hour it does send in full (the
/// hour of the erase included), so a synced hour **replaces** the stored one,
/// and hours the ring no longer holds keep their stored values. The same rule
/// is right whether or not the last erase happened.
Future<List<VitalSyncItem>> _mergeWithStoredSteps(
    List<VitalSyncItem> stepItems) async {
  final userId = Userapi.getUserID();
  if (userId == null) return stepItems;

  num numOf(Object? value) => value is num ? value : 0;

  final merged = <VitalSyncItem>[];
  for (final item in stepItems) {
    final day = item.createdAt;
    Map<String, dynamic>? stored;
    if (day != null) {
      try {
        final rows = await VitalsSqLiteService().getVitalsHistory(
          userId,
          'steps',
          fromDate: DateTime(day.year, day.month, day.day),
          toDate: DateTime(day.year, day.month, day.day, 23, 59, 59),
        );
        final raw = rows.isEmpty ? null : rows.first['data'];
        if (raw is String) stored = jsonDecode(raw) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('SYNC: reading stored steps failed: $e');
      }
    }
    if (stored == null) {
      merged.add(item);
      continue;
    }

    Map<int, Map> byHour(Object? list) => {
          if (list is List)
            for (final entry in list.whereType<Map>())
              if (entry['hour'] is num) (entry['hour'] as num).toInt(): entry,
        };

    // Synced hours win; stored hours fill in the ones the ring no longer has.
    final hours = {
      ...byHour(stored['hourly_data']),
      ...byHour(item.data?['hourly_data']),
    };
    final hourly = [
      for (final hour in hours.keys.toList()..sort())
        {
          'hour': hour,
          for (final key in const ['steps', 'calorie', 'distance'])
            key: numOf(hours[hour]![key]),
        },
    ];

    num hourlySum(String key) =>
        hourly.fold<num>(0, (sum, h) => sum + numOf(h[key]));
    // The day is the sum of its hours, unless the ring's own running total
    // for the day is ahead of its hourly buckets.
    num total(String key) => max(hourlySum(key == 'calories' ? 'calorie' : key),
        numOf(item.data?[key]));

    final steps = total('steps');
    merged.add(VitalSyncItem(
      id: item.id,
      key: item.key,
      value: steps.toDouble(),
      createdAt: item.createdAt,
      unit: item.unit,
      data: {
        ...?item.data,
        'steps': steps,
        'distance': total('distance'),
        'calories': total('calories'),
        'hourly_data': hourly,
      },
    ));
  }
  return merged;
}

/// Stable id for one sleep session.
///
/// Sleep is stored per session, not per day, so the id has to be derived from
/// the session itself — a re-sync of the same night then updates that row
/// (locally and on the server) instead of inserting a duplicate.
String _sleepSessionId(SleepSession session) {
  return const Uuid().v5(
    Namespace.url.value,
    'allowear:sleep_data:${session.start.millisecondsSinceEpoch}:${session.end.millisecondsSinceEpoch}',
  );
}

List<VitalSyncItem> convertSleepToServerFormat(List<SleepSession> sleepData,
    AllowearDeviceType deviceType) {
  return sleepData.map((session) {
    // A session belongs to the day it ended on: a night from 23:00 to 06:00 is
    // counted on the wake-up date, never on the date it started.
    return VitalSyncItem(
        id: _sleepSessionId(session),
        key: "sleep_data",
        value: session.totalSleepMinutes.toDouble(),
        createdAt: session.end,
        unit: "minutes",
        data: {
          ..._deviceTag(deviceType),
          "sleep_time": session.start.toIso8601String(),
          "awake_time": session.end.toIso8601String(),
          "total_sleep_duration": session.totalSleepMinutes,
          "deep_sleep_duration": session.deepMinutes,
          "light_sleep_duration": session.lightMinutes,
          "rem_sleep_duration": session.remMinutes,
          "awake_duration": session.awakeMinutes,
        });
  }).toList();
}
