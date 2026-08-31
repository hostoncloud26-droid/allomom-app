import 'package:drift/drift.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

class PrescriptionDbService {
  static final PrescriptionDbService instance = PrescriptionDbService._internal();
  PrescriptionDbService._internal();

  Future<List<Prescription>> getPrescriptions(String healthId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptions)
          ..where((tbl) => tbl.healthId.equals(healthId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<PrescriptionMedicine>> getMedicinesForPrescription(String prescriptionId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicines)
          ..where((tbl) => tbl.prescriptionId.equals(prescriptionId)))
        .get();
  }

  Future<List<PrescriptionMedicine>> getAllActiveMedicines(String healthId) async {
    final db = await SqLiteService().database;
    return (db.select(db.prescriptionMedicines)
          ..where((tbl) => tbl.healthId.equals(healthId)))
        .get();
  }

  Future<void> savePrescription(
    PrescriptionsCompanion prescription,
    List<PrescriptionMedicinesCompanion> medicines,
  ) async {
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await db.into(db.prescriptions).insertOnConflictUpdate(prescription);
      for (final med in medicines) {
        await db.into(db.prescriptionMedicines).insertOnConflictUpdate(med);
      }
    });
  }

  Future<void> logMedicineTiming(PrescriptionMedicineTimingsCompanion timing) async {
    final db = await SqLiteService().database;
    await db.into(db.prescriptionMedicineTimings).insertOnConflictUpdate(timing);
  }
}
