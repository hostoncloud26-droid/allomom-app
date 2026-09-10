part of '../drift_database.dart';

/// Vaccine schedule & administration records for a baby, tied to its birth
/// record. `immunizationScheduleId` is left as a plain nullable FK column
/// for the reference `ImmunizationSchedule` table to be added separately.
class BabyImmunizationRecords extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get birthRecordId =>
      text().named('birth_record_id').nullable()(); // -> birth_records.id
  TextColumn get vaccineName => text().named('vaccine_name')();
  DateTimeColumn get expectedDate => dateTime().named('expected_date').nullable()();
  BoolColumn get required =>
      boolean().nullable().withDefault(const Constant(true))();
  DateTimeColumn get vaccinationDate => dateTime().named('vaccination_date').nullable()();
  TextColumn get vaccinatedBy => text().named('vaccinated_by').nullable()(); // -> users.id
  TextColumn get immunizationScheduleId =>
      text().named('immunization_schedule_id').nullable()(); // -> ImmunizationSchedule.id (reference table, added later)
  TextColumn get reportId => text().named('report_id').nullable()(); // -> reports.id
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
