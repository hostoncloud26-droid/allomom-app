/// Builds an [AlloBotContext] out of the app's live state.
///
/// The impure counterpart to `allobot_context.dart`: this is the only file in
/// the AlloBot stack that touches GetX, SQLite or the care catalogue, which is
/// what keeps the phrasing rules testable with a hand-built context.
///
/// Every read is wrapped individually. A mother with no ANC schedule yet, or a
/// vitals table that has not synced, must still get a working chat — a failed
/// lookup degrades that one fact to null rather than taking down the reply.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/allobot/allobot_context.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// Vital keys read as point-in-time measurements rather than daily sums.
const Set<String> measurementVitalKeys = {
  'weight',
  'weight_kg',
  'blood_pressure',
  'bp',
  'sugar',
  'blood_sugar',
  'hemoglobin',
  'haemoglobin',
  'temperature',
  'spo2',
  'heart_rate',
};

/// Vital keys summed over the day, because their rows hold increments.
const Set<String> cumulativeVitalKeys = {
  'water',
  'kick_count',
  'snacks',
  'drinks',
  'steps',
  'todocare',
};

class AlloBotContextLoader {
  AlloBotContextLoader._();

  /// Assembles the context AlloBot answers from.
  ///
  /// [now] is injectable so the day-part and ANC-proximity phrasing can be
  /// tested at a fixed time.
  static Future<AlloBotContext> load({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final session = UserSessionManager.instance;
    final part = CareDayPart.at(at);

    final userId = session.userId;
    final isPregnant = session.isPregnant;

    final health = await _healthData(userId);
    final pregnancy = await _activePregnancy(session.healthDataId);

    final ancVisits = await _ancVisits(pregnancy?.id);
    final vaccines = await _vaccines(userId, pregnancy?.id);
    final labReports = await _labReports(userId, pregnancy?.id);

    final careItems = careItemsFor(
      part: part,
      isPregnant: isPregnant,
      pregnancyDay: session.currentPregnancyDay,
    );

    final todayTotals = await _todayTotals(userId, careItems);
    final latestVitals = await _latestVitals(userId);

    return AlloBotContext(
      motherName: session.userName,
      isPregnant: isPregnant,
      isNewMom: session.isNewMom,
      pregnancyDay: session.currentPregnancyDay,
      gestationalWeek: isPregnant ? session.currentGestationalWeek : 0,
      daysLeftUntilEdd: session.daysLeftUntilEdd,
      now: at,
      dayPartLabel: part.label,
      greetingWord: part.greeting,
      dayPartHeadline: part.headline,
      lmpDate: session.lmpDate,
      eddDate: session.eddDate,
      formattedEdd: session.formattedEddDate,
      riskStatus: session.riskStatus,
      bloodGroup: session.bloodGroup ?? health?.bloodGroup,
      heightCm: health?.height,
      weightKg: health?.weight,
      allergies: _decodeStringList(health?.allergies),
      medicalConditions: _decodeStringList(health?.medicalConditions),
      flaggedComplications: _decodeStringList(pregnancy?.flaggedComplications),
      ancVisits: ancVisits,
      vaccines: vaccines,
      labReports: labReports,
      latestVitals: latestVitals,
      todayTotals: todayTotals,
      todayCare: _careContexts(careItems, part, todayTotals),
      kidsCount: session.kidsCount,
      completedPregnancyCount: session.completedPregnancyCount,
    );
  }

  static Future<HealthDataTableData?> _healthData(String userId) async {
    if (userId.isEmpty) return null;
    try {
      return await HealthDbService.instance.getHealthDataByUserId(userId);
    } catch (e) {
      debugPrint('AlloBotContextLoader: health data unavailable: $e');
      return null;
    }
  }

  static Future<Pregnancy?> _activePregnancy(String healthId) async {
    if (healthId.isEmpty) return null;
    try {
      return await HealthDbService.instance.getActivePregnancy(healthId);
    } catch (e) {
      debugPrint('AlloBotContextLoader: active pregnancy unavailable: $e');
      return null;
    }
  }

  static Future<List<AncVisitContext>> _ancVisits(String? pregnancyId) async {
    if (pregnancyId == null || pregnancyId.isEmpty) return const [];
    try {
      final rows = await PregnancyCareDbService.instance.getAncVisits(pregnancyId);
      return rows
          .map(
            (row) => AncVisitContext(
              id: row.id,
              visitNumber: row.visitNumber,
              scheduledDate: row.scheduledDate,
              status: row.status,
              pregnancyMonth: row.pregnancyMonth,
              trimester: row.trimester,
              actualDate: row.actualDate,
              bp: row.bp,
              weightKg: row.weightKg,
              fetalHeartRate: row.fetalHeartRate,
              notes: row.notes,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('AlloBotContextLoader: ANC schedule unavailable: $e');
      return const [];
    }
  }

  static Future<List<VaccineContext>> _vaccines(
    String userId,
    String? pregnancyId,
  ) async {
    if (userId.isEmpty) return const [];
    try {
      final rows = await PregnancyCareDbService.instance
          .getVaccinations(userId, pregnancyId: pregnancyId);
      return rows
          .map(
            (row) => VaccineContext(
              id: row.id,
              name: row.vaccineName,
              doseNumber: row.doseNumber,
              scheduledDate: row.scheduledDate,
              status: row.status,
              pregnancyMonth: row.pregnancyMonth,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('AlloBotContextLoader: vaccine schedule unavailable: $e');
      return const [];
    }
  }

  static Future<List<LabReportContext>> _labReports(
    String userId,
    String? pregnancyId,
  ) async {
    if (userId.isEmpty) return const [];
    try {
      final rows = await PregnancyCareDbService.instance
          .getReportChecklists(userId, pregnancyId: pregnancyId);
      return rows
          .map(
            (row) => LabReportContext(
              name: row.reportName,
              status: row.status,
              category: row.category,
              pregnancyMonth: row.pregnancyMonth,
              dueDate: row.dueDate,
              completedDate: row.completedDate,
              isRequired: row.isRequired,
              resultSummary: row.resultSummary,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('AlloBotContextLoader: lab report checklist unavailable: $e');
      return const [];
    }
  }

  /// Sums today's rows for every cumulative key, plus any count-backed care
  /// item on today's list.
  ///
  /// Rows hold increments, so summing is the only correct reading — the same
  /// rule Today's Care follows. Calorie-backed keys (`snacks`, `drinks`) put
  /// kcal in `value` and the portion count in `data['count']`, so those are
  /// counted from `data` and default to one unit when a row was written
  /// elsewhere in the app without it.
  static Future<Map<String, double>> _todayTotals(
    String userId,
    List<CareItem> careItems,
  ) async {
    if (userId.isEmpty) return const {};

    final calorieBackedKeys = <String>{
      for (final item in careItems)
        if (item.countVitalKey != null && item.caloriesPerUnit != null)
          item.countVitalKey!,
    };
    final keys = <String>{
      ...cumulativeVitalKeys,
      for (final item in careItems)
        if (item.countVitalKey != null) item.countVitalKey!,
      for (final item in careItems)
        if (item.doneVitalKey != null) item.doneVitalKey!,
    };

    final startOfToday = _startOfToday();
    final totals = <String, double>{};

    for (final key in keys) {
      try {
        final rows = await VitalsSqLiteService()
            .getVitalsHistory(userId, key, fromDate: startOfToday);
        if (rows.isEmpty) continue;

        var total = 0.0;
        for (final row in rows) {
          if (calorieBackedKeys.contains(key)) {
            final recorded = _decodeData(row)['count'];
            final parsed = recorded is num
                ? recorded.toDouble()
                : double.tryParse(recorded?.toString() ?? '');
            total += parsed ?? 1;
          } else {
            total += (row['value'] as num?)?.toDouble() ?? 0;
          }
        }
        if (total > 0) totals[key] = total;
      } catch (e) {
        debugPrint('AlloBotContextLoader: could not sum "$key" vitals: $e');
      }
    }

    return totals;
  }

  static Future<Map<String, VitalContext>> _latestVitals(String userId) async {
    if (userId.isEmpty) return const {};
    try {
      final rows = await VitalsSqLiteService().getLatestVitals(userId);
      final vitals = <String, VitalContext>{};
      for (final row in rows) {
        final key = row['vital_key']?.toString();
        if (key == null || key.isEmpty) continue;
        // Cumulative keys are reported from the day's sum instead; a single
        // latest row would understate them.
        if (cumulativeVitalKeys.contains(key)) continue;
        vitals[key] = VitalContext(
          key: key,
          value: (row['value'] as num?)?.toDouble() ?? 0,
          unit: row['unit']?.toString() ?? '',
          recordedAt: _parseDate(row['created_at']) ?? DateTime.now(),
        );
      }
      return vitals;
    } catch (e) {
      debugPrint('AlloBotContextLoader: latest vitals unavailable: $e');
      return const {};
    }
  }

  static List<TodayCareContext> _careContexts(
    List<CareItem> items,
    CareDayPart part,
    Map<String, double> totals,
  ) {
    return items.map((item) {
      final key = item.countVitalKey ?? item.doneVitalKey;
      return TodayCareContext(
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        dayPartLabel: part.label,
        target: item.dailyTarget,
        loggedToday: key == null ? null : totals[key],
        unit: item.unitPlural,
      );
    }).toList();
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// The health table stores allergies and conditions as a JSON array, but
  /// older rows hold a plain comma-separated string.
  static List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList();
      }
      if (decoded is String) return _splitPlainList(decoded);
    } catch (_) {
      // Not JSON — fall through to the comma-separated reading.
    }
    return _splitPlainList(raw);
  }

  static List<String> _splitPlainList(String raw) => raw
      .split(RegExp(r'[,;]'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  static Map<String, dynamic> _decodeData(Map<String, dynamic> row) {
    final raw = row['data'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }
}
