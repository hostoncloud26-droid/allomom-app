part of '../drift_database.dart';

/// Mirrors `baby_immunization_records` in allomom-api-new — the infant's
/// National Immunization Schedule, seeded by the server from the birth date.
class BabyImmunizationRecords extends Table {
  @override
  String get tableName => 'baby_immunization_records';

  TextColumn get id => text()(); // UUID
  TextColumn get babyId => text().named('baby_id').nullable()();
  TextColumn get vaccineName => text().named('vaccine_name')();
  DateTimeColumn get scheduledDate => dateTime().named('scheduled_date').nullable()();
  DateTimeColumn get receivedDate => dateTime().named('received_date').nullable()();
  BoolColumn get required => boolean().withDefault(const Constant(true))();
  DateTimeColumn get scheduledDateRangeFrom =>
      dateTime().named('scheduled_date_range_from').nullable()();
  DateTimeColumn get scheduledDateRangeTo =>
      dateTime().named('scheduled_date_range_to').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
