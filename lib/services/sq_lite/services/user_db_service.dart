import 'package:drift/drift.dart';

import 'package:allomom/services/auth/secure_token_store.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Local reads and writes for the `users` table.
///
/// The signed-in user is whoever [SecureTokenStore] holds a token for, so there
/// is no separate "active user" preference to drift out of step with the
/// session. [MainController] is the usual entry point; this is the storage
/// layer beneath it.
class UserDbService {
  static final UserDbService instance = UserDbService._internal();
  UserDbService._internal();

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  /// The signed-in user, or null when there is no session or no seeded row yet.
  Future<User?> getActiveUser() async {
    final id = SecureTokenStore.instance.userId;
    if (id == null || id.isEmpty) return getFirstStoredUser();
    return getUserById(id);
  }

  /// Any stored user. Used only as a fallback before the token store has been
  /// read, and on a device that has exactly one account.
  Future<User?> getFirstStoredUser() async {
    final db = await _db;
    return (db.select(db.users)
          ..where((u) => u.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
  }

  Future<User?> getUserById(String id) async {
    final db = await _db;
    return (db.select(db.users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
  }

  Future<User?> getUserByPhone(String phone) async {
    final db = await _db;
    return (db.select(db.users)..where((u) => u.phone.equals(phone)))
        .getSingleOrNull();
  }

  Future<List<User>> getAllUsers() async {
    final db = await _db;
    return (db.select(db.users)..where((u) => u.deletedAt.isNull())).get();
  }

  Future<User> saveUser(UsersCompanion user) async {
    final db = await _db;
    await db.into(db.users).insertOnConflictUpdate(user);
    final saved = await getUserById(user.id.value);
    return saved!;
  }

  /// Applies a local edit and queues it for the next sync.
  Future<void> updateUser(UsersCompanion user) async {
    final db = await _db;
    await (db.update(db.users)..where((u) => u.id.equals(user.id.value))).write(
      user.copyWith(updatedAt: Value(DateTime.now()), synced: const Value(0)),
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await _db;
    await (db.delete(db.users)..where((u) => u.id.equals(id))).go();
  }

  Future<bool> hasActiveSession() async =>
      SecureTokenStore.instance.hasSession && (await getActiveUser()) != null;
}
