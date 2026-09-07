part of '../drift_database.dart';

/// Vaccine schedule & administration records.
/// [pregnancyId] is null for general/child vaccines and set for maternal
/// vaccines tied to a specific pregnancy.
class Vaccinations extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().named('user_id').nullable()(); // -> users.id
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()(); // -> pregnancies.id
  TextColumn get vaccineName => text()(); // 'TT', 'Tdap', 'BCG', 'MMR' ...
  IntColumn get doseNumber => integer().withDefault(const Constant(1))();
  /// Pregnancy month (1-10) this dose is due in; null for child vaccines.
  IntColumn get pregnancyMonth => integer().named('pregnancy_month').nullable()();
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get administeredDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, done, missed
  TextColumn get batchNumber => text().nullable()();
  TextColumn get administeredBy => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
