part of '../drift_database.dart';

class Prescriptions extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get healthId => text().named('health_id').nullable()();
  TextColumn get description => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get driveFileId => text().named('drive_file_id').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
