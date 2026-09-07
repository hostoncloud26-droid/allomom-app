part of '../drift_database.dart';

/// Tracks lab tests, scans and other reports the user still needs to complete.
/// Distinct from [Reports], which holds a report's actual content once it exists.
class ReportChecklists extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().named('user_id').nullable()(); // -> users.id
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()(); // -> pregnancies.id
  TextColumn get reportName => text()(); // 'CBC', 'Urine R/E', 'USG Level II'
  TextColumn get category => text().nullable()(); // blood, urine, imaging, other
  /// Pregnancy month (1-10) this test belongs to. Stored rather than derived
  /// because month arithmetic off the LMP is lossy at month ends.
  IntColumn get pregnancyMonth => integer().named('pregnancy_month').nullable()();
  /// False for tests a doctor orders only when indicated (TB screening, NST).
  BoolColumn get isRequired =>
      boolean().named('is_required').withDefault(const Constant(true))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get completedDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, done, missed
  TextColumn get filePath => text().nullable()(); // local path to PDF/image
  TextColumn get resultSummary => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
