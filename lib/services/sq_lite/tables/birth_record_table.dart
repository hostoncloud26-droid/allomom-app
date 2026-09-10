part of '../drift_database.dart';

/// A baby's birth record. Created once delivery happens; `pregnancyId` links
/// it back to the pregnancy that produced it (nullable so a birth record can
/// exist standalone, e.g. a previous child added during registration).
class BirthRecords extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get pregnancyId => text().named('pregnancy_id').nullable()(); // -> pregnancies.id
  TextColumn get babyName => text().named('baby_name').nullable()();
  DateTimeColumn get dob => dateTime().nullable()();
  TextColumn get deliveryType => text().named('delivery_type').nullable()(); // 'normal' | 'c-section'
  TextColumn get gender => text().nullable()();
  RealColumn get weight => real().nullable()(); // birth weight, kg
  TextColumn get bloodGroup => text().named('blood_group').nullable()();
  TextColumn get photo => text().nullable()(); // local path or URL
  TextColumn get video => text().nullable()(); // local path or URL
  TextColumn get healthId => text().named('health_id').nullable()(); // -> health_data_table.id (baby's own health record, once created)
  DateTimeColumn get deceasedAt => dateTime().named('deceased_at').nullable()();
  TextColumn get causeOfDeath => text().named('cause_of_death').nullable()();
  TextColumn get infantId => text().named('infant_id').nullable()(); // -> users.id, once the baby gets its own profile
  TextColumn get complications => text().nullable()(); // JSON array
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
