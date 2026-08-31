part of '../drift_database.dart';

class Users extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get phoneVerified => dateTime().nullable()();
  TextColumn get countryCode => text().named('country_code').nullable()();
  TextColumn get password => text().nullable()();
  DateTimeColumn get emailVerified => dateTime().nullable()();
  TextColumn get gender => text().nullable()();
  DateTimeColumn get dob => dateTime().nullable()();
  TextColumn get image => text().nullable()();
  TextColumn get roleId => text().nullable()();
  TextColumn get userType => text().withDefault(const Constant('User'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get adline1 => text().nullable()();
  TextColumn get adline2 => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get pincode => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get entity => text().nullable()();
  TextColumn get userName => text().named('user_name').nullable()();
  TextColumn get coverPic => text().named('cover_pic').nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get familyID => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get healthDataID => text().named('HealthDataID').nullable()();
  TextColumn get allowearMacAddress => text().named('allowear_mac_address').nullable()();
  DateTimeColumn get lastActiveAt => dateTime().named('last_active_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
