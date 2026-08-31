part of '../drift_database.dart';

class UserRelations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get relatedUserId => text().named('related_user_id')();
  TextColumn get relationType => text().named('relation_type')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();
}
