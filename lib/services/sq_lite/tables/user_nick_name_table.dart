part of '../drift_database.dart';

/// What one user calls another.
///
/// Distinct from `users.name`, which is the person's own name. The partner
/// screen writes here: the name typed there is the caller's word for their
/// partner, so editing it must not rewrite the partner's own profile.
class UserNickNames extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get relatedUserId => text().named('related_user_id')();
  TextColumn get nickName => text().named('nick_name')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get synced => integer().withDefault(const Constant(0))();
}
