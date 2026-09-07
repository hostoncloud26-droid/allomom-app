import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// CRUD for prescriptions, their medicines and the per-dose intake log.
///
/// Local-only. Every write resets `synced` to 0 so a future sync worker can
/// push the row to allomom-api.
class PrescriptionDbService {
  static final PrescriptionDbService instance = PrescriptionDbService._internal();
  PrescriptionDbService._internal();

  final _uuid = const Uuid();

  // ---------------------- PRESCRIPTIONS ----------------------

  Future<List<Prescription>> getPrescriptions(
    String healthId, {
    int? limit,
    int offset = 0,
  }) async {
    final db = await SqLiteService().database;
    final query = db.select(db.prescriptions)
      ..where((tbl) => tbl.healthId.equals(healthId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (limit != null) query.limit(limit, offset: offset);
    return query.get();
  }

  Future<List<Prescription>> getAllPrescriptions() async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<Prescription?> getPrescriptionById(String prescriptionId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptions)
          ..where((tbl) => tbl.id.equals(prescriptionId)))
        .getSingleOrNull();
  }

  Future<List<PrescriptionMedicine>> getMedicinesForPrescription(
      String prescriptionId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicines)
          ..where((tbl) => tbl.prescriptionId.equals(prescriptionId)))
        .get();
  }

  Future<List<PrescriptionMedicine>> getAllActiveMedicines(
      String healthId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicines)
          ..where((tbl) => tbl.healthId.equals(healthId)))
        .get();
  }

  Future<PrescriptionMedicine?> getMedicineById(String medicineId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicines)
          ..where((tbl) => tbl.id.equals(medicineId)))
        .getSingleOrNull();
  }

  /// Inserts (or updates) a prescription together with its medicines.
  /// Returns the prescription id, generating one when absent.
  Future<String> savePrescription(
    PrescriptionsCompanion prescription,
    List<PrescriptionMedicinesCompanion> medicines,
  ) async {
    final db = await SqLiteService().database;
    final prescriptionId =
        prescription.id.present && prescription.id.value.isNotEmpty
            ? prescription.id.value
            : _uuid.v4();

    await db.transaction(() async {
      await db.into(db.prescriptions).insertOnConflictUpdate(
            prescription.copyWith(
              id: Value(prescriptionId),
              synced: const Value(0),
            ),
          );
      for (final med in medicines) {
        final medId = med.id.present && med.id.value.isNotEmpty
            ? med.id.value
            : _uuid.v4();
        await db.into(db.prescriptionMedicines).insertOnConflictUpdate(
              med.copyWith(
                id: Value(medId),
                prescriptionId: Value(prescriptionId),
                synced: const Value(0),
              ),
            );
      }
    });

    return prescriptionId;
  }

  Future<void> updatePrescription(PrescriptionsCompanion prescription) async {
    final db = await SqLiteService().database;
    await (db.update(db.prescriptions)
          ..where((tbl) => tbl.id.equals(prescription.id.value)))
        .write(prescription.copyWith(synced: const Value(0)));
  }

  /// Deletes a prescription and cascades to its medicines and their timings.
  Future<void> deletePrescription(String prescriptionId) async {
    final db = await SqLiteService().database;
    await db.transaction(() async {
      final meds = await (db.select(db.prescriptionMedicines)
            ..where((tbl) => tbl.prescriptionId.equals(prescriptionId)))
          .get();
      for (final med in meds) {
        await (db.delete(db.prescriptionMedicineTimings)
              ..where((tbl) => tbl.prescriptionMedicineId.equals(med.id)))
            .go();
      }
      await (db.delete(db.prescriptionMedicines)
            ..where((tbl) => tbl.prescriptionId.equals(prescriptionId)))
          .go();
      await (db.delete(db.prescriptions)
            ..where((tbl) => tbl.id.equals(prescriptionId)))
          .go();
    });
  }

  // ---------------------- MEDICINES ----------------------

  Future<String> saveMedicine(PrescriptionMedicinesCompanion medicine) async {
    final db = await SqLiteService().database;
    final id = medicine.id.present && medicine.id.value.isNotEmpty
        ? medicine.id.value
        : _uuid.v4();
    await db.into(db.prescriptionMedicines).insertOnConflictUpdate(
          medicine.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<void> deleteMedicine(String medicineId) async {
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await (db.delete(db.prescriptionMedicineTimings)
            ..where((tbl) => tbl.prescriptionMedicineId.equals(medicineId)))
          .go();
      await (db.delete(db.prescriptionMedicines)
            ..where((tbl) => tbl.id.equals(medicineId)))
          .go();
    });
  }

  // ---------------------- TIMINGS ----------------------

  Future<String> logMedicineTiming(
      PrescriptionMedicineTimingsCompanion timing) async {
    final db = await SqLiteService().database;
    final id = timing.id.present && timing.id.value.isNotEmpty
        ? timing.id.value
        : _uuid.v4();
    await db.into(db.prescriptionMedicineTimings).insertOnConflictUpdate(
          timing.copyWith(id: Value(id), synced: const Value(0)),
        );
    return id;
  }

  Future<PrescriptionMedicineTiming?> getTimingById(String timingId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicineTimings)
          ..where((tbl) => tbl.id.equals(timingId)))
        .getSingleOrNull();
  }

  /// Every logged dose between [from] and [to], joined with its medicine and
  /// parent prescription. [userId] narrows to one family member's medicines
  /// when the medicine row records an owner.
  Future<List<MedicineTimingDetail>> getTimingsInRange({
    required DateTime from,
    required DateTime to,
    String? userId,
    String? healthId,
  }) async {
    final db = await SqLiteService().database;

    final medicineQuery = db.select(db.prescriptionMedicines);
    if (userId != null && userId.isNotEmpty) {
      medicineQuery.where((tbl) => tbl.userId.equals(userId));
    }
    if (healthId != null && healthId.isNotEmpty) {
      medicineQuery.where((tbl) => tbl.healthId.equals(healthId));
    }
    final medicines = await medicineQuery.get();
    if (medicines.isEmpty) return const [];

    final medicineById = {for (final m in medicines) m.id: m};

    final timings = await (db.select(db.prescriptionMedicineTimings)
          ..where((tbl) =>
              tbl.prescriptionMedicineId.isIn(medicineById.keys) &
              tbl.timingDateTime.isBiggerOrEqualValue(from) &
              tbl.timingDateTime.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.timingDateTime)]))
        .get();

    final prescriptionCache = <String, Prescription?>{};
    final details = <MedicineTimingDetail>[];

    for (final timing in timings) {
      final medicine = medicineById[timing.prescriptionMedicineId];
      if (medicine == null) continue;

      Prescription? prescription;
      final pid = medicine.prescriptionId;
      if (pid != null && pid.isNotEmpty) {
        prescription =
            prescriptionCache[pid] ??= await getPrescriptionById(pid);
      }

      details.add(MedicineTimingDetail(
        timing: timing,
        medicine: medicine,
        prescription: prescription,
      ));
    }

    return details;
  }

  /// Full detail for one logged dose, or null when the row is gone.
  Future<MedicineTimingDetail?> getTimingDetail(String timingId) async {
    final timing = await getTimingById(timingId);
    if (timing == null) return null;

    PrescriptionMedicine? medicine;
    final medId = timing.prescriptionMedicineId;
    if (medId != null && medId.isNotEmpty) {
      medicine = await getMedicineById(medId);
    }

    Prescription? prescription;
    final pid = medicine?.prescriptionId;
    if (pid != null && pid.isNotEmpty) {
      prescription = await getPrescriptionById(pid);
    }

    return MedicineTimingDetail(
      timing: timing,
      medicine: medicine,
      prescription: prescription,
    );
  }

  Future<void> markTimingTaken(String timingId, {DateTime? takenAt}) async {
    final db = await SqLiteService().database;
    await (db.update(db.prescriptionMedicineTimings)
          ..where((tbl) => tbl.id.equals(timingId)))
        .write(PrescriptionMedicineTimingsCompanion(
      status: const Value('taken'),
      medicineTakenTime: Value(takenAt ?? DateTime.now()),
      synced: const Value(0),
    ));
  }

  /// Pushes a pending dose out by [minutes]. Returns false when the row is
  /// missing, so the caller can tell the user nothing was rescheduled.
  Future<bool> snoozeTiming(String timingId, int minutes) async {
    final db = await SqLiteService().database;
    final timing = await getTimingById(timingId);
    if (timing == null) return false;

    await (db.update(db.prescriptionMedicineTimings)
          ..where((tbl) => tbl.id.equals(timingId)))
        .write(PrescriptionMedicineTimingsCompanion(
      timingDateTime:
          Value(timing.timingDateTime.add(Duration(minutes: minutes))),
      status: const Value('pending'),
      synced: const Value(0),
    ));
    return true;
  }

  Future<void> deleteTiming(String timingId) async {
    final db = await SqLiteService().database;
    await (db.delete(db.prescriptionMedicineTimings)
          ..where((tbl) => tbl.id.equals(timingId)))
        .go();
  }

  // ---------------------- SYNC HELPERS ----------------------

  Future<List<Prescription>> unsyncedPrescriptions() async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptions)..where((t) => t.synced.equals(0))).get();
  }

  Future<List<PrescriptionMedicine>> unsyncedMedicines() async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicines)..where((t) => t.synced.equals(0)))
        .get();
  }

  Future<List<PrescriptionMedicineTiming>> unsyncedTimings() async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicineTimings)
          ..where((t) => t.synced.equals(0)))
        .get();
  }
}

/// Decodes the `timings` column of a medicine row into `HH:mm` strings.
///
/// Rows are written as a JSON array, but older rows used a comma-separated
/// string, so both shapes are accepted.
List<String> decodeMedicineTimings(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }
  } catch (_) {
    // Not JSON — fall through to the legacy comma-separated form.
  }
  return raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// One logged dose together with the medicine and prescription it belongs to.
class MedicineTimingDetail {
  const MedicineTimingDetail({
    required this.timing,
    this.medicine,
    this.prescription,
  });

  final PrescriptionMedicineTiming timing;
  final PrescriptionMedicine? medicine;
  final Prescription? prescription;

  String get id => timing.id;
  DateTime get dateTime => timing.timingDateTime;
  String get status => timing.status;
  bool get isTaken => timing.status == 'taken';
  String get medicineName => medicine?.medicineName ?? 'Medicine';
  String get dosage => medicine?.dosage ?? '';
  String? get notes => medicine?.notes;
  List<String> get scheduledTimes => decodeMedicineTimings(medicine?.timings);
  String? get prescriptionDescription => prescription?.description;
}
