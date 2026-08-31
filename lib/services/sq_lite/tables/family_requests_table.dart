part of '../drift_database.dart';

class FamilyRequestsTable extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().named('userId').nullable()();
  TextColumn get familyId => text().named('familyId').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get status => text().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
