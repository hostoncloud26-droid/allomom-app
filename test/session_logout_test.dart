import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/user_db_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// The bug being guarded: `getActiveUser` used to fall back to the first
/// stored profile *and* mark it active, so after logging out the leftover row
/// re-established the session and the old user was signed back in on restart.
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

  Future<void> signIn(String id) async {
    await UserDbService.instance.saveUser(
      UsersCompanion.insert(id: id, name: const Value('Meera')),
    );
    await UserDbService.instance.setActiveUser(id);
  }

  test('a signed-in user is the active user', () async {
    await signIn('usr-1');

    expect(await UserDbService.instance.hasActiveSession(), isTrue);
    expect(
      await UserDbService.instance.getActiveUser(),
      isA<User>().having((u) => u.id, 'id', 'usr-1'),
    );
  });

  test(
    'logout leaves no active session even though the profile remains',
    () async {
      await signIn('usr-1');
      await UserDbService.instance.logout();

      expect(await UserDbService.instance.getActiveUser(), isNull);
      expect(await UserDbService.instance.hasActiveSession(), isFalse);

      // The profile row is kept on purpose so signing back in is cheap.
      expect(await UserDbService.instance.getUserById('usr-1'), isNotNull);
    },
  );

  test('a second call after logout does not resurrect the session', () async {
    await signIn('usr-1');
    await UserDbService.instance.logout();

    // The old fallback re-activated the first stored user on read, so the
    // second call would have returned a user again.
    expect(await UserDbService.instance.getActiveUser(), isNull);
    expect(await UserDbService.instance.getActiveUser(), isNull);
    expect(await UserDbService.instance.hasActiveSession(), isFalse);
  });

  test(
    'logout with several stored profiles still clears the session',
    () async {
      await signIn('usr-1');
      await UserDbService.instance.saveUser(
        UsersCompanion.insert(id: 'usr-2', name: const Value('Asha')),
      );

      await UserDbService.instance.logout();

      expect(await UserDbService.instance.getActiveUser(), isNull);
      expect(await UserDbService.instance.getAllUsers(), hasLength(2));
    },
  );

  test(
    'getFirstStoredUser finds a profile without starting a session',
    () async {
      await signIn('usr-1');
      await UserDbService.instance.logout();

      final stored = await UserDbService.instance.getFirstStoredUser();
      expect(stored, isNotNull);
      expect(stored!.id, 'usr-1');

      // Reading it must not have signed anyone in.
      expect(await UserDbService.instance.getActiveUser(), isNull);
    },
  );

  test('signing back in after logout restores the session', () async {
    await signIn('usr-1');
    await UserDbService.instance.logout();
    await UserDbService.instance.setActiveUser('usr-1');

    expect(await UserDbService.instance.hasActiveSession(), isTrue);
  });

  test('switching users replaces the active one', () async {
    await signIn('usr-1');
    await UserDbService.instance.saveUser(
      UsersCompanion.insert(id: 'usr-2', name: const Value('Asha')),
    );
    await UserDbService.instance.setActiveUser('usr-2');

    expect((await UserDbService.instance.getActiveUser())!.id, 'usr-2');
  });

  test('an active id pointing at a deleted row yields no session', () async {
    await signIn('usr-1');
    await UserDbService.instance.deleteUser('usr-1');

    // Soft-deleted, so the row is still there but must not be a session.
    final active = await UserDbService.instance.getActiveUser();
    expect(active?.isDeleted, isTrue);
    expect(await UserDbService.instance.getFirstStoredUser(), isNull);
  });
}
