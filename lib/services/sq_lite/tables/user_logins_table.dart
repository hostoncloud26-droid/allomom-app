part of '../drift_database.dart';

/// Mirrors `user_logins` in allomom-api-new, minus the refresh token.
///
/// The token itself never lands here — it lives in [SecureTokenStore]. This
/// table is the device-visible session list ("signed in on Pixel 7, Chennai"),
/// so it holds only what a settings screen would show.
class UserLoginsTable extends Table {
  @override
  String get tableName => 'user_logins';

  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().named('user_id')();
  TextColumn get ipAddress => text().named('ip_address').nullable()();
  TextColumn get deviceType => text().named('device_type').nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get latitude => text().nullable()();
  TextColumn get longitude => text().nullable()();
  DateTimeColumn get revokedAt => dateTime().named('revoked_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  TextColumn get fcmToken => text().named('fcm_token').nullable()();
  DateTimeColumn get lastAccessedAt => dateTime().named('last_accessed_at').nullable()();
  DateTimeColumn get loggedOutAt => dateTime().named('logged_out_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
