part of '../drift_database.dart';

class CycleHistories extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get healthId => text().named('health_id').nullable()();
  DateTimeColumn get cycleStartDate => dateTime()();
  DateTimeColumn get cycleEndDate => dateTime().nullable()();
  TextColumn get cycleType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
