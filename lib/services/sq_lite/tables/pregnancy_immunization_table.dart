part of '../drift_database.dart';

/// Mirrors `pregnancy_immunization_record` in allomom-api-new — the mother's
/// own vaccinations (Td doses, influenza) for one pregnancy.
class PregnancyImmunizationRecords extends Table {
  @override
  String get tableName => 'pregnancy_immunization_record';

  TextColumn get id => text()(); // UUID
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()();
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
