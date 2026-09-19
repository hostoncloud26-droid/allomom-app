part of '../drift_database.dart';

/// One row per sync module holding the watermark to replay next time.
///
/// [syncedAt] is always a value the *server* handed back, never a device clock
/// reading: a phone whose clock is wrong would otherwise ask for changes since
/// a time that never existed and silently skip a window of updates.
class SyncStates extends Table {
  @override
  String get tableName => 'sync_state';

  TextColumn get module => text()();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().named('last_attempt_at').nullable()();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column> get primaryKey => {module};
}
