part of '../drift_database.dart';

class PrescriptionMedicines extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get prescriptionId => text().nullable()();
  TextColumn get medicineName => text()();
  TextColumn get dosage => text()();
  TextColumn get timings => text()(); // JSON array
  IntColumn get durationDays => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get healthId => text().named('health_id').nullable()();
  TextColumn get userId => text().named('user_id').nullable()();
  TextColumn get reminderConfig => text().named('reminder_config').nullable()(); // JSON object
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
