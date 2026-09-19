part of '../drift_database.dart';

/// Mirrors `baby` in allomom-api-new.
///
/// A baby always hangs off a pregnancy — that is the server's only route from a
/// user to a baby, so [pregnancyId] is how ownership is established locally too.
class Babies extends Table {
  @override
  String get tableName => 'baby';

  TextColumn get id => text()(); // UUID
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()();
  TextColumn get name => text()();
  DateTimeColumn get deliveryDate => dateTime().named('delivery_date')();
  TextColumn get typeOfDelivery => text().named('type_of_delivery')();
  TextColumn get condition => text().nullable()(); // live | deceased | neonatal death
  TextColumn get gender => text().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get height => real().nullable()();
  TextColumn get photo => text().nullable()(); // JSON array of urls
  TextColumn get video => text().nullable()(); // JSON array of urls
  TextColumn get bloodGroup => text().named('blood_group').nullable()();
  TextColumn get complications => text().nullable()(); // JSON array
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
