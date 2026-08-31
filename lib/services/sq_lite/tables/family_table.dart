part of '../drift_database.dart';

class Families extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().nullable()();
  TextColumn get code => text().nullable()();
  TextColumn get motherId => text().nullable()();
  TextColumn get fatherId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  TextColumn get profileImage => text().nullable()();
  TextColumn get bannerImage => text().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
