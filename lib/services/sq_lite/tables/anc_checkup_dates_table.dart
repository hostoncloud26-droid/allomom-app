part of '../drift_database.dart';

/// Mirrors `anc_checkup_dates` in allomom-api-new.
///
/// Each row is one monthly antenatal contact. The server seeds all nine when a
/// pregnancy is created; the app only ever stamps [completedAt].
class AncCheckupDates extends Table {
  @override
  String get tableName => 'anc_checkup_dates';

  TextColumn get id => text()(); // UUID
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()();
  DateTimeColumn get scheduledDate => dateTime().named('scheduled_date').nullable()();
  IntColumn get month => integer()();
  DateTimeColumn get completedAt => dateTime().named('completed_at').nullable()();
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
