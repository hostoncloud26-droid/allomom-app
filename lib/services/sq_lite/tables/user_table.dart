part of '../drift_database.dart';

/// Mirrors `users` in allomom-api-new.
///
/// [syncedAt] is the server `updated_at` this row was last reconciled at, and
/// [synced] is 0 while the row holds a local edit the server has not seen. The
/// pair is what the sync engine reads: dirty rows are pushed, and the highest
/// [syncedAt] across the table is the watermark for the next pull.
class Users extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id => text()(); // UUID
  TextColumn get name => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get phoneVerified => dateTime().named('phone_verified').nullable()();
  TextColumn get countryCode => text().named('country_code').nullable()();
  DateTimeColumn get emailVerified => dateTime().named('email_verified').nullable()();
  TextColumn get coverPic => text().named('cover_pic').nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get gender => text().nullable()();
  DateTimeColumn get dob => dateTime().nullable()();
  TextColumn get profilePicture => text().named('profile_picture').nullable()();
  TextColumn get userType => text().named('user_type').withDefault(const Constant('User'))();
  TextColumn get addressLine1 => text().named('address_line_1').nullable()();
  TextColumn get addressLine2 => text().named('address_line_2').nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get pincode => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  BoolColumn get isRegistered =>
      boolean().named('is_registered').withDefault(const Constant(false))();
  TextColumn get userName => text().named('user_name').nullable()();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
