part of '../drift_database.dart';

/// Files belonging to a report. Created with only local data at first;
/// [cloudUrl] is filled in once the upload completes.
class ReportAttachments extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get reportId => text().named('report_id').nullable()(); // -> reports.id
  TextColumn get localPath => text()(); // path on-device, always present
  TextColumn get cloudUrl => text().nullable()(); // null until uploaded
  TextColumn get fileName => text().nullable()();
  TextColumn get mimeType => text().nullable()(); // 'application/pdf', 'image/png' ...
  IntColumn get fileSizeBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
