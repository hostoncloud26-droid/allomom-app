import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/user_db_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Signing out has to leave nothing behind.
///
/// The bug this guards: `getActiveUser` used to fall back to the first stored
/// profile *and* mark it active, so a leftover row re-established the session
/// and the previous user was signed back in on restart. The session is now the
/// token in secure storage, and `clearAccountData` is what has to empty the
/// device — if a row survives it, the same bug comes back through the fallback
/// in [UserDbService.getFirstStoredUser].
void main() {
  late AppDriftDatabase db;

  setUp(() {
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });

  Future<void> seedAccount(String id) async {
    await UserDbService.instance.saveUser(
      UsersCompanion.insert(id: id, name: const Value('Meera')),
    );
    await db
        .into(db.healthDataTable)
        .insertOnConflictUpdate(
          HealthDataTableCompanion.insert(id: 'hd-$id', userId: id),
        );
    await db
        .into(db.pregnancies)
        .insertOnConflictUpdate(
          PregnanciesCompanion.insert(
            id: 'preg-$id',
            healthId: Value('hd-$id'),
          ),
        );
    await db
        .into(db.syncStates)
        .insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            module: 'user',
            syncedAt: Value(DateTime.now()),
          ),
        );
  }

  test('clearAccountData removes every trace of the account', () async {
    await seedAccount('usr-1');

    expect(await UserDbService.instance.getUserById('usr-1'), isNotNull);

    await db.clearAccountData();

    expect(await db.select(db.users).get(), isEmpty);
    expect(await db.select(db.healthDataTable).get(), isEmpty);
    expect(await db.select(db.pregnancies).get(), isEmpty);
  });

  test('no stored user can re-establish a session after a wipe', () async {
    await seedAccount('usr-1');
    await db.clearAccountData();

    // The fallback that caused the original bug now has nothing to find.
    expect(await UserDbService.instance.getFirstStoredUser(), isNull);
    expect(await UserDbService.instance.getActiveUser(), isNull);
  });

  test('sync watermarks are cleared, so the next sign-in re-seeds', () async {
    await seedAccount('usr-1');

    expect(await db.select(db.syncStates).get(), hasLength(1));

    await db.clearAccountData();

    // A stale watermark would make the next account's first sync ask for
    // "changes since" a moment that has nothing to do with it, and silently
    // skip everything written before then.
    expect(await db.select(db.syncStates).get(), isEmpty);
  });

  test('a different user signing in does not inherit the old rows', () async {
    await seedAccount('usr-1');
    await db.clearAccountData();
    await seedAccount('usr-2');

    final users = await db.select(db.users).get();
    expect(users, hasLength(1));
    expect(users.single.id, 'usr-2');
  });
}
