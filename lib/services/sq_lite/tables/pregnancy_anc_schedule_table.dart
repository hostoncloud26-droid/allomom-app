part of '../drift_database.dart';

/// One row per antenatal-care visit tied to a specific pregnancy.
class PregnancyAncSchedule extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()(); // -> pregnancies.id
  IntColumn get visitNumber => integer().withDefault(const Constant(1))(); // ANC-1, ANC-2, ...
  IntColumn get trimester => integer().nullable()(); // 1 | 2 | 3
  /// Pregnancy month (1-10) this visit was booked for.
  IntColumn get pregnancyMonth => integer().named('pregnancy_month').nullable()();
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get actualDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, done, missed
  RealColumn get weightKg => real().nullable()();
  TextColumn get bp => text().nullable()(); // e.g. "120/80"
  RealColumn get fundalHeightCm => real().nullable()();
  IntColumn get fetalHeartRate => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
