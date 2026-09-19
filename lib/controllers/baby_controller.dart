import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:allomom/api/baby_api.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sync/sync_mappers.dart';
import 'package:allomom/services/sync/sync_service.dart';

/// The user's babies, with their immunization schedule and milestone checklist.
///
/// As with pregnancies, adding a baby goes through the server so the National
/// Immunization Schedule and the milestone list are generated in one place.
class BabyController extends GetxController {
  static BabyController get instance => Get.isRegistered<BabyController>()
      ? Get.find<BabyController>()
      : Get.put(BabyController._(), permanent: true);

  BabyController._();

  List<Baby> _babies = const [];
  final Map<String, List<BabyImmunizationRecord>> _vaccinations = {};
  final Map<String, List<BabyMilestone>> _milestones = {};

  List<Baby> get babies => _babies;
  bool get hasKids => _babies.isNotEmpty;
  int get kidsCount => _babies.length;

  /// The most recently born baby — what "my baby" means on the home screen.
  Baby? get youngest => _babies.isEmpty ? null : _babies.first;

  DateTime? get youngestBabyDob => youngest?.deliveryDate;

  List<BabyImmunizationRecord> vaccinationsFor(String babyId) =>
      _vaccinations[babyId] ?? const [];

  List<BabyMilestone> milestonesFor(String babyId) =>
      _milestones[babyId] ?? const [];

  /// Days since the most recent delivery, or null if there has not been one.
  int? get daysSinceDelivery {
    final dob = youngestBabyDob;
    if (dob == null) return null;
    final days = DateTime.now().difference(dob).inDays;
    return days < 0 ? 0 : days;
  }

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── Local reads ────────────────────────────────────────────────────────────

  Future<void> loadFromLocal() async {
    final db = await _db;
    final pregnancyIds =
        PregnancyController.instance.pregnancies.map((p) => p.id).toList();

    if (pregnancyIds.isEmpty) {
      reset();
      return;
    }

    _babies =
        await (db.select(db.babies)
              ..where(
                (b) => b.pregnancyId.isIn(pregnancyIds) & b.deletedAt.isNull(),
              )
              ..orderBy([(b) => drift.OrderingTerm.desc(b.deliveryDate)]))
            .get();

    _vaccinations.clear();
    _milestones.clear();

    for (final baby in _babies) {
      _vaccinations[baby.id] =
          await (db.select(db.babyImmunizationRecords)
                ..where((v) => v.babyId.equals(baby.id) & v.deletedAt.isNull())
                ..orderBy([(v) => drift.OrderingTerm.asc(v.scheduledDate)]))
              .get();

      _milestones[baby.id] =
          await (db.select(db.babyMilestones)
                ..where((m) => m.babyId.equals(baby.id) & m.deletedAt.isNull())
                ..orderBy([(m) => drift.OrderingTerm.asc(m.expectedDate)]))
              .get();
    }

    update();
  }

  void reset() {
    _babies = const [];
    _vaccinations.clear();
    _milestones.clear();
    update();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Adds a baby and pulls back the schedules the server seeded.
  ///
  /// [pregnancyId] may be omitted: the server attaches the baby to the most
  /// recent pregnancy, or creates a placeholder if there is none. That is what
  /// lets the registration flow record previous children before the app knows
  /// anything about pregnancy records.
  Future<String?> addBaby({
    required String name,
    required DateTime deliveryDate,
    String typeOfDelivery = 'normal',
    String? pregnancyId,
    String? gender,
    double? weight,
    double? height,
    String? bloodGroup,
    String condition = 'live',
  }) async {
    final response = await BabyApi.create({
      'name': name,
      'delivery_date': SyncCodec.isoUtc(deliveryDate),
      'type_of_delivery': typeOfDelivery,
      'condition': condition,
      if (pregnancyId != null) 'pregnancy_id': pregnancyId,
      if (gender != null) 'gender': gender,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      'seed_schedules': true,
    });

    if (!response.success || response.item is! Map) {
      debugPrint('❌ [BabyController] add failed: ${response.detail}');
      return null;
    }

    await _persistDetail(Map<String, dynamic>.from(response.item as Map));
    // A baby may have caused the server to create a placeholder pregnancy, so
    // the pregnancy list has to catch up before the baby can be read back —
    // local ownership is resolved through it.
    await PregnancyController.instance.loadFromLocal();
    await loadFromLocal();
    return response.id?.toString();
  }

  Future<bool> updateBaby(String babyId, Map<String, dynamic> changes) async {
    final db = await _db;
    await (db.update(db.babies)..where((b) => b.id.equals(babyId))).write(
      BabiesCompanion(
        name: changes.containsKey('name')
            ? drift.Value(changes['name'].toString())
            : const drift.Value.absent(),
        deliveryDate: changes.containsKey('delivery_date')
            ? drift.Value(
                SyncCodec.date(changes['delivery_date']) ?? DateTime.now(),
              )
            : const drift.Value.absent(),
        gender: changes.containsKey('gender')
            ? drift.Value(SyncCodec.text(changes['gender']))
            : const drift.Value.absent(),
        weight: changes.containsKey('weight')
            ? drift.Value(SyncCodec.number(changes['weight']))
            : const drift.Value.absent(),
        height: changes.containsKey('height')
            ? drift.Value(SyncCodec.number(changes['height']))
            : const drift.Value.absent(),
        bloodGroup: changes.containsKey('blood_group')
            ? drift.Value(SyncCodec.text(changes['blood_group']))
            : const drift.Value.absent(),
        condition: changes.containsKey('condition')
            ? drift.Value(SyncCodec.text(changes['condition']))
            : const drift.Value.absent(),
        updatedAt: drift.Value(DateTime.now()),
        synced: const drift.Value(0),
      ),
    );
    await loadFromLocal();

    final response = await BabyApi.patch(babyId, changes);
    if (response.success && response.item is Map) {
      await _persistDetail(Map<String, dynamic>.from(response.item as Map));
      await loadFromLocal();
      return true;
    }
    return false;
  }

  Future<bool> setVaccinationReceived(
    String vaccinationId,
    DateTime? receivedDate,
  ) async {
    final db = await _db;
    await (db.update(db.babyImmunizationRecords)
          ..where((v) => v.id.equals(vaccinationId)))
        .write(
          BabyImmunizationRecordsCompanion(
            receivedDate: drift.Value(receivedDate),
            updatedAt: drift.Value(DateTime.now()),
            synced: const drift.Value(0),
          ),
        );
    await loadFromLocal();
    if (await SyncService.instance.syncModule('baby_vaccination')) {
      await loadFromLocal();
    }
    return true;
  }

  Future<bool> setMilestoneCompleted(
    int milestoneId,
    DateTime? completedAt,
  ) async {
    final db = await _db;
    await (db.update(db.babyMilestones)..where((m) => m.id.equals(milestoneId)))
        .write(
          BabyMilestonesCompanion(
            completedAt: drift.Value(completedAt),
            updatedAt: drift.Value(DateTime.now()),
            synced: const drift.Value(0),
          ),
        );
    await loadFromLocal();
    if (await SyncService.instance.syncModule('milestone')) {
      await loadFromLocal();
    }
    return true;
  }

  Future<bool> deleteBaby(String babyId) async {
    final db = await _db;
    await (db.update(db.babies)..where((b) => b.id.equals(babyId))).write(
      BabiesCompanion(
        deletedAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
        synced: const drift.Value(0),
      ),
    );
    await loadFromLocal();
    final response = await BabyApi.remove(babyId);
    return response.success;
  }

  /// Writes a `BabyDetailOut` — the baby plus its vaccinations and milestones —
  /// into the local tables in one transaction.
  Future<void> _persistDetail(Map<String, dynamic> detail) async {
    final db = await _db;
    await db.transaction(() async {
      await const BabyMapper().applyServerRow(db, detail);
      for (final v in (detail['vaccinations'] as List? ?? const [])) {
        if (v is Map) {
          await const BabyVaccinationMapper()
              .applyServerRow(db, Map<String, dynamic>.from(v));
        }
      }
      for (final m in (detail['milestones'] as List? ?? const [])) {
        if (m is Map) {
          await const BabyMilestoneMapper()
              .applyServerRow(db, Map<String, dynamic>.from(m));
        }
      }
    });
  }
}
