part of '../drift_database.dart';

class Reports extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get reportType => text().named('report_type')();
  TextColumn get detail => text().nullable()(); // JSON object of parameters
  TextColumn get healthDataID => text().named('healthDataID').nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get driveFileId => text().named('drive_file_id').nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  BoolColumn get saved => boolean().withDefault(const Constant(false))();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
