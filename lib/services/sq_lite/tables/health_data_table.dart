part of '../drift_database.dart';

class HealthDataTable extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().named('UserID').nullable()();
  RealColumn get height => real().nullable()();
  RealColumn get weight => real().nullable()();
  TextColumn get bloodGroup => text().nullable()();
  TextColumn get allergies => text().nullable()(); // JSON array
  TextColumn get medicalConditions => text().nullable()(); // JSON array
  TextColumn get rchId => text().named('rch_id').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get recoveryPhone => text().nullable()();
  TextColumn get recoveryEmail => text().nullable()();
  DateTimeColumn get lmpDate => dateTime().nullable()();
  RealColumn get averagePeriodDuration => real().nullable()();
  RealColumn get averageCycle => real().nullable()();
  TextColumn get cycleType => text().nullable()();
  DateTimeColumn get edDate => dateTime().nullable()();
  TextColumn get pregnancyStatus => text().nullable()(); // 'pregnant', 'not pregnant'
  DateTimeColumn get lastDeliveryDate => dateTime().nullable()();
  TextColumn get healthStatus => text().nullable()();
  BoolColumn get allowFamilyAccess => boolean().withDefault(const Constant(false))();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
