part of '../drift_database.dart';

/// Developmental milestone checklist for a baby, tied to its birth record.
class BabyMilestones extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get birthRecordId =>
      text().named('birth_record_id').nullable()(); // -> birth_records.id
  DateTimeColumn get expectedDate => dateTime().named('expected_date').nullable()();
  TextColumn get milestone => text()();
  TextColumn get description => text()();
  BoolColumn get achieved => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completed => dateTime().nullable()(); // date the milestone was achieved
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
