part of '../drift_database.dart';

/// Mirrors `BabyMilestones` in allomom-api-new.
///
/// The one table whose primary key is a server-assigned integer rather than a
/// client-generated UUID, so the app cannot mint rows offline and have them
/// keep their identity. It does not need to: the server seeds the whole
/// checklist when a baby is added, and the app only stamps [completedAt].
class BabyMilestones extends Table {
  @override
  String get tableName => 'baby_milestones';

  IntColumn get id => integer()();
  TextColumn get babyId => text().named('baby_id').nullable()();
  DateTimeColumn get expectedDate => dateTime().named('expected_date').nullable()();
  TextColumn get milestone => text()();
  TextColumn get description => text()();
  DateTimeColumn get completedAt => dateTime().named('completed_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
