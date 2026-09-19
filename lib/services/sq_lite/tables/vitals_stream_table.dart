part of '../drift_database.dart';

/// Mirrors `vitals_stream` in allomom-api-new.
///
/// The app's single time series for anything measured: weight, blood pressure,
/// haemoglobin, steps — and, since the health profile no longer stores cycle
/// settings, the period-start and cycle-length readings the cycle tracker
/// predicts from. [data] carries a JSON blob for readings that do not reduce to
/// one number, such as a blood-pressure pair.
class VitalsStreamTable extends Table {
  @override
  String get tableName => 'vitals_stream';

  TextColumn get id => text()(); // UUID
  TextColumn get healthId => text().named('health_id').nullable()();
  TextColumn get key => text()();
  RealColumn get value => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get data => text().nullable()(); // JSON object
  DateTimeColumn get createdAt => dateTime().named('createdAt').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
