part of '../drift_database.dart';

class PrescriptionMedicineTimings extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get prescriptionMedicineId => text().named('prescriptionMedicineId').nullable()();
  DateTimeColumn get timingDateTime => dateTime().named('dateTime')();
  DateTimeColumn get medicineTakenTime => dateTime().nullable()();
  TextColumn get status => text()(); // pending, taken, missed
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
