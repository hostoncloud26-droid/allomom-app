part of '../drift_database.dart';

/// Mirrors `pregnancy_report_checklist` in allomom-api-new — the lab tests and
/// scans due across a pregnancy.
///
/// Distinct from [Reports], which holds a report's actual content once it
/// exists; this is the "what still needs doing" list.
class PregnancyReportChecklists extends Table {
  @override
  String get tableName => 'pregnancy_report_checklist';

  TextColumn get id => text()(); // UUID
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()();
  TextColumn get reportName => text().named('report_name')();
  DateTimeColumn get expectedDate => dateTime().named('expected_date').nullable()();
  DateTimeColumn get completedDate => dateTime().named('completed_date').nullable()();
  TextColumn get reportType => text().named('report_type').nullable()();
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
