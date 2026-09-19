import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:allomom/api/pregnancy_api.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sync/sync_mappers.dart';
import 'package:allomom/services/sync/sync_service.dart';

/// The active pregnancy and its three schedules.
///
/// Reads come from the local database so every screen works offline. Creating a
/// pregnancy is the one operation that needs the server: the ANC, vaccination
/// and report schedules are generated there from the LMP, so the app waits for
/// them rather than seeding a second, divergent copy locally.
class PregnancyController extends GetxController {
  static PregnancyController get instance =>
      Get.isRegistered<PregnancyController>()
      ? Get.find<PregnancyController>()
      : Get.put(PregnancyController._(), permanent: true);

  PregnancyController._();

  List<Pregnancy> _pregnancies = const [];
  Pregnancy? _active;
  List<AncCheckupDate> _ancCheckups = const [];
  List<PregnancyImmunizationRecord> _vaccinations = const [];
  List<PregnancyReportChecklist> _reportChecklists = const [];

  List<Pregnancy> get pregnancies => _pregnancies;
  Pregnancy? get activePregnancy => _active;
  List<AncCheckupDate> get ancCheckups => _ancCheckups;
  List<PregnancyImmunizationRecord> get vaccinations => _vaccinations;
  List<PregnancyReportChecklist> get reportChecklists => _reportChecklists;

  bool get isPregnant => _active != null;

  /// Pregnancies that ended in a birth — what "how many children" is counted
  /// from when the user has not listed them explicitly.
  int get completedPregnancyCount =>
      _pregnancies.where((p) => p.status == 'delivered').length;

  String? get activePregnancyId => _active?.id;
  DateTime? get lmpDate => _active?.lmpDate;
  DateTime? get eddDate => _active?.eddDate;

  /// Days elapsed since the LMP, clamped at zero so a future-dated LMP entered
  /// by mistake cannot render a negative gestation.
  int get currentPregnancyDay {
    final lmp = lmpDate;
    if (lmp == null) return 0;
    final days = DateTime.now().difference(lmp).inDays;
    return days < 0 ? 0 : days;
  }

  /// Gestational age in completed weeks, capped at 42 — beyond that the number
  /// is a data-entry error, not a pregnancy.
  int get currentGestationalWeek {
    final week = (currentPregnancyDay / 7).floor();
    if (week < 0) return 0;
    return week > 42 ? 42 : week;
  }

  int get currentTrimesterNumber {
    final week = currentGestationalWeek;
    if (week < 13) return 1;
    if (week < 28) return 2;
    return 3;
  }

  String get currentTrimester => switch (currentTrimesterNumber) {
    1 => 'First Trimester',
    2 => 'Second Trimester',
    _ => 'Third Trimester',
  };

  int get daysLeftUntilEdd {
    final edd = eddDate;
    if (edd == null) return 0;
    final days = edd.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── Local reads ────────────────────────────────────────────────────────────

  Future<void> loadFromLocal() async {
    final db = await _db;
    final healthId = MainController.instance.healthDataId;

    if (healthId.isEmpty) {
      reset();
      return;
    }

    _pregnancies =
        await (db.select(db.pregnancies)
              ..where((p) => p.healthId.equals(healthId) & p.deletedAt.isNull())
              ..orderBy([
                (p) => drift.OrderingTerm.desc(p.createdAt),
              ]))
            .get();

    _active = _pregnancies
        .where((p) => p.status == 'active')
        .cast<Pregnancy?>()
        .firstWhere((_) => true, orElse: () => null);

    final id = _active?.id;
    if (id == null) {
      _ancCheckups = const [];
      _vaccinations = const [];
      _reportChecklists = const [];
      update();
      return;
    }

    _ancCheckups =
        await (db.select(db.ancCheckupDates)
              ..where((a) => a.pregnancyId.equals(id) & a.deletedAt.isNull())
              ..orderBy([(a) => drift.OrderingTerm.asc(a.month)]))
            .get();

    _vaccinations =
        await (db.select(db.pregnancyImmunizationRecords)
              ..where((v) => v.pregnancyId.equals(id) & v.deletedAt.isNull())
              ..orderBy([(v) => drift.OrderingTerm.asc(v.scheduledDate)]))
            .get();

    _reportChecklists =
        await (db.select(db.pregnancyReportChecklists)
              ..where((r) => r.pregnancyId.equals(id) & r.deletedAt.isNull())
              ..orderBy([(r) => drift.OrderingTerm.asc(r.expectedDate)]))
            .get();

    update();
  }

  void reset() {
    _pregnancies = const [];
    _active = null;
    _ancCheckups = const [];
    _vaccinations = const [];
    _reportChecklists = const [];
    update();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Registers a pregnancy and pulls back the schedules the server generated.
  ///
  /// Returns the new pregnancy id, or null if the call could not be made. This
  /// one write is deliberately online-only: seeding nine ANC visits, four
  /// vaccinations and sixteen reports locally and then reconciling them against
  /// a server that generated its own set would duplicate the entire calendar.
  Future<String?> createPregnancy({
    required DateTime lmpDate,
    DateTime? eddDate,
    int? gravidity,
    int? parity,
    int? livingChildren,
    Map<String, dynamic>? data,
  }) async {
    final response = await PregnancyApi.create({
      'lmp_date': SyncCodec.isoDate(lmpDate),
      if (eddDate != null) 'edd_date': SyncCodec.isoDate(eddDate),
      'status': 'active',
      if (gravidity != null) 'gravidity': gravidity,
      if (parity != null) 'parity': parity,
      if (livingChildren != null) 'living_children': livingChildren,
      if (data != null) 'data': data,
      'seed_schedules': true,
    });

    if (!response.success || response.item is! Map) {
      debugPrint('❌ [PregnancyController] create failed: ${response.detail}');
      return null;
    }

    await _persistDetail(Map<String, dynamic>.from(response.item as Map));
    await MainController.instance.loadFromLocal();
    return response.id?.toString();
  }

  /// Applies a change locally, then pushes it.
  ///
  /// Editing the LMP makes the server reschedule everything still outstanding,
  /// so the whole detail payload is written back rather than just the patched
  /// fields.
  Future<bool> updatePregnancy(
    String pregnancyId,
    Map<String, dynamic> changes,
  ) async {
    final db = await _db;
    await (db.update(db.pregnancies)..where((p) => p.id.equals(pregnancyId)))
        .write(
          PregnanciesCompanion(
            lmpDate: changes.containsKey('lmp_date')
                ? drift.Value(SyncCodec.date(changes['lmp_date']))
                : const drift.Value.absent(),
            eddDate: changes.containsKey('edd_date')
                ? drift.Value(SyncCodec.date(changes['edd_date']))
                : const drift.Value.absent(),
            deliveryDateTime: changes.containsKey('delivery_date_time')
                ? drift.Value(SyncCodec.date(changes['delivery_date_time']))
                : const drift.Value.absent(),
            status: changes.containsKey('status')
                ? drift.Value(changes['status'].toString())
                : const drift.Value.absent(),
            riskStatus: changes.containsKey('risk_status')
                ? drift.Value(SyncCodec.text(changes['risk_status']))
                : const drift.Value.absent(),
            flaggedComplications: changes.containsKey('flagged_complications')
                ? drift.Value(
                    SyncCodec.encodeJson(changes['flagged_complications']),
                  )
                : const drift.Value.absent(),
            updatedAt: drift.Value(DateTime.now()),
            synced: const drift.Value(0),
          ),
        );
    await loadFromLocal();

    final response = await PregnancyApi.patch(pregnancyId, changes);
    if (response.success && response.item is Map) {
      await _persistDetail(Map<String, dynamic>.from(response.item as Map));
      await MainController.instance.loadFromLocal();
      return true;
    }
    return false;
  }

  /// Marks an ANC visit done, or clears it when [completedAt] is null.
  Future<bool> setAncCompleted(String ancId, DateTime? completedAt) =>
      _patchSchedule(
        localWrite: (db) async => (db.update(db.ancCheckupDates)
              ..where((a) => a.id.equals(ancId)))
            .write(
              AncCheckupDatesCompanion(
                completedAt: drift.Value(completedAt),
                updatedAt: drift.Value(DateTime.now()),
                synced: const drift.Value(0),
              ),
            ),
        module: 'anc',
      );

  Future<bool> setVaccinationReceived(
    String vaccinationId,
    DateTime? receivedDate,
  ) => _patchSchedule(
    localWrite: (db) async => (db.update(db.pregnancyImmunizationRecords)
          ..where((v) => v.id.equals(vaccinationId)))
        .write(
          PregnancyImmunizationRecordsCompanion(
            receivedDate: drift.Value(receivedDate),
            updatedAt: drift.Value(DateTime.now()),
            synced: const drift.Value(0),
          ),
        ),
    module: 'pregnancy_vaccination',
  );

  Future<bool> setReportCompleted(
    String checklistId,
    DateTime? completedDate,
  ) => _patchSchedule(
    localWrite: (db) async => (db.update(db.pregnancyReportChecklists)
          ..where((r) => r.id.equals(checklistId)))
        .write(
          PregnancyReportChecklistsCompanion(
            completedDate: drift.Value(completedDate),
            updatedAt: drift.Value(DateTime.now()),
            synced: const drift.Value(0),
          ),
        ),
    module: 'report_checklist',
  );

  /// The shared shape of a schedule tick: write locally, show it, then let sync
  /// carry it up. Offline the local write is the whole operation and the row
  /// stays queued until the next successful pass.
  Future<bool> _patchSchedule({
    required Future<void> Function(AppDriftDatabase db) localWrite,
    required String module,
  }) async {
    final db = await _db;
    await localWrite(db);
    await loadFromLocal();
    final pushed = await SyncService.instance.syncModule(module);
    if (pushed) await loadFromLocal();
    return true;
  }

  Future<bool> deletePregnancy(String pregnancyId) async {
    final db = await _db;
    await (db.update(db.pregnancies)..where((p) => p.id.equals(pregnancyId)))
        .write(
          PregnanciesCompanion(
            deletedAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
            synced: const drift.Value(0),
          ),
        );
    await loadFromLocal();
    final response = await PregnancyApi.remove(pregnancyId);
    await MainController.instance.loadFromLocal();
    return response.success;
  }

  /// Writes a `PregnancyDetailOut` — the pregnancy plus its three schedules —
  /// into the local tables in one transaction.
  Future<void> _persistDetail(Map<String, dynamic> detail) async {
    final db = await _db;
    await db.transaction(() async {
      await const PregnancyMapper().applyServerRow(db, detail);
      for (final anc in (detail['anc_checkups'] as List? ?? const [])) {
        if (anc is Map) {
          await const AncMapper()
              .applyServerRow(db, Map<String, dynamic>.from(anc));
        }
      }
      for (final v in (detail['vaccinations'] as List? ?? const [])) {
        if (v is Map) {
          await const PregnancyVaccinationMapper()
              .applyServerRow(db, Map<String, dynamic>.from(v));
        }
      }
      for (final r in (detail['report_checklists'] as List? ?? const [])) {
        if (r is Map) {
          await const ReportChecklistMapper()
              .applyServerRow(db, Map<String, dynamic>.from(r));
        }
      }
    });
    await loadFromLocal();
  }
}
