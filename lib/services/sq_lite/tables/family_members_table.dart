part of '../drift_database.dart';

class FamilyMembersTable extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userid => text().nullable()();
  TextColumn get familyid => text().nullable()();
  TextColumn get relation => text().nullable()();
  TextColumn get accessLevel => text().named('access_level')(); // JSON array
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
