part of '../drift_database.dart';

class Pregnancies extends Table {
  TextColumn get id => text()(); // UUID
  DateTimeColumn get lmpDate => dateTime().nullable()();
  DateTimeColumn get edDate => dateTime().nullable()();
  TextColumn get healthId => text().named('health_id').nullable()();
  DateTimeColumn get deliveryDate => dateTime().nullable()();
  TextColumn get rchId => text().named('rch_id').nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get createdBy => text().nullable()();
  BoolColumn get registerWithin12Weeks => boolean().withDefault(const Constant(false))();
  TextColumn get highestRiskStatus => text().nullable()();
  TextColumn get allFlaggedComplications => text().named('all_flagged_complications').nullable()(); // JSON array
  TextColumn get riskStatus => text().nullable()();
  TextColumn get flaggedComplications => text().named('flagged_complications').nullable()(); // JSON array
  TextColumn get overallHealth => text().named('overall_health').nullable()(); // JSON object
  TextColumn get methodOfConception => text().nullable()();
  IntColumn get gravidity => integer().withDefault(const Constant(0))();
  IntColumn get parity => integer().withDefault(const Constant(0))();
  IntColumn get livingChildren => integer().withDefault(const Constant(0))();
  IntColumn get abortions => integer().withDefault(const Constant(0))();
  IntColumn get stillBirths => integer().withDefault(const Constant(0))();
  IntColumn get miscarriages => integer().withDefault(const Constant(0))();
  IntColumn get csectionDeliveries => integer().withDefault(const Constant(0))();
  TextColumn get obstetricCode => text().nullable()();
  BoolColumn get mrmbsEligible => boolean().withDefault(const Constant(false))();
  IntColumn get motherAge => integer().nullable()();
  IntColumn get fatherAge => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get deliveryConductedAt => text().nullable()();
  DateTimeColumn get admittedAt => dateTime().nullable()();
  DateTimeColumn get dischargedAt => dateTime().nullable()();
  DateTimeColumn get deceasedAt => dateTime().nullable()();
  TextColumn get causeOfDeath => text().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
