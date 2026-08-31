part of '../drift_database.dart';

class UserEntities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get type => text()();
  DateTimeColumn get leftAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();
}
