part of '../drift_database.dart';

/// Mirrors `pregnancy` in allomom-api-new.
///
/// The array and JSON columns the server stores natively (`flagged_complications`,
/// `overall_health`, `data`) are held here as JSON text, since sqlite has no
/// array type; [PregnancySyncMapper] is the single place that encodes and
/// decodes them so no screen has to think about it.
class Pregnancies extends Table {
  @override
  String get tableName => 'pregnancy';

  TextColumn get id => text()(); // UUID
  DateTimeColumn get lmpDate => dateTime().named('lmp_date').nullable()();
  DateTimeColumn get eddDate => dateTime().named('edd_date').nullable()();
  TextColumn get healthId => text().named('health_id').nullable()();
  DateTimeColumn get deliveryDateTime =>
      dateTime().named('delivery_date_time').nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get createdBy => text().named('created_by').nullable()();
  TextColumn get data => text().nullable()(); // JSON object
  TextColumn get highestRiskStatus => text().named('highest_risk_status').nullable()();
  TextColumn get allFlaggedComplications =>
      text().named('all_flagged_complications').nullable()(); // JSON array
  TextColumn get riskStatus => text().named('risk_status').nullable()();
  TextColumn get flaggedComplications =>
      text().named('flagged_complications').nullable()(); // JSON array
  TextColumn get overallHealth => text().named('overall_health').nullable()(); // JSON object
  IntColumn get gravidity => integer().withDefault(const Constant(0))();
  IntColumn get parity => integer().withDefault(const Constant(0))();
  IntColumn get livingChildren =>
      integer().named('living_children').withDefault(const Constant(0))();
  IntColumn get abortions => integer().withDefault(const Constant(0))();
  IntColumn get stillBirths =>
      integer().named('still_births').withDefault(const Constant(0))();
  IntColumn get miscarriages => integer().withDefault(const Constant(0))();
  IntColumn get csectionDeliveries =>
      integer().named('csection_deliveries').withDefault(const Constant(0))();
  TextColumn get obstetricCode => text().named('obstetric_code').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
