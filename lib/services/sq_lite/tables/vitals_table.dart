part of '../drift_database.dart';

class Vitals extends Table {
  TextColumn get id => text()();
  TextColumn get vitalKey => text().named('vital_key')();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get userId => text().named('user_id').nullable()();
  TextColumn get data => text().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
