part of '../drift_database.dart';

/// Mirrors `health_data` in allomom-api-new, column for column.
///
/// Deliberately thin. The height/weight/blood-group/cycle-length fields the old
/// local schema carried are gone: measurements belong in [VitalsStreamTable] as
/// readings with a history, not as a single overwritten value on the profile.
class HealthDataTable extends Table {
  @override
  String get tableName => 'health_data';

  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().named('user_id')();
  DateTimeColumn get lmpDate => dateTime().named('lmp_date').nullable()();
  TextColumn get rchId => text().named('rch_id').nullable()();
  TextColumn get allergies => text().nullable()();
  TextColumn get medicalCondition => text().named('medical_condition').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
