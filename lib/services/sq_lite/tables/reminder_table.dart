part of '../drift_database.dart';

/// User-configured reminders (custom health reminders + the built-in
/// pregnancy reminder toggles). Stored locally only; `synced = 0` until a
/// sync worker pushes them to allomom-api.
class Reminders extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().named('user_id').nullable()(); // -> users.id
  TextColumn get title => text()();
  TextColumn get reminderType => text().named('reminder_type').nullable()();
  TextColumn get frequency => text().withDefault(const Constant('Daily'))();
  IntColumn get hour => integer().nullable()();
  IntColumn get minute => integer().nullable()();
  TextColumn get channels => text().nullable()(); // JSON array
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get configurable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startDate => dateTime().named('start_date').nullable()();
  DateTimeColumn get endDate => dateTime().named('end_date').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
