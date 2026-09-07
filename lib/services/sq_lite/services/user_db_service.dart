import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

class UserDbService {
  static const String _activeUserIdKey = 'active_user_id';
  static final UserDbService instance = UserDbService._internal();
  UserDbService._internal();

  /// Retrieve the currently active logged-in user
  /// The user the `active_user_id` setting points at, or null when nobody is
  /// signed in.
  ///
  /// Deliberately has **no** "fall back to the first user" behaviour. That
  /// fallback also called [setActiveUser], so after logging out the leftover
  /// profile row silently re-established the session and the old user was
  /// signed straight back in on the next launch.
  Future<User?> getActiveUser() async {
    final database = await SqLiteService().database;
    final setting = await (database.select(
      database.initialSetup,
    )..where((tbl) => tbl.key.equals(_activeUserIdKey))).getSingleOrNull();

    if (setting == null || setting.value.isEmpty) return null;

    return (database.select(
      database.users,
    )..where((tbl) => tbl.id.equals(setting.value))).getSingleOrNull();
  }

  /// First profile still stored on the device, ignoring the active session.
  ///
  /// Only for flows that explicitly want "any local profile" (seeding, user
  /// switching) — never for deciding whether someone is signed in.
  Future<User?> getFirstStoredUser() async {
    final database = await SqLiteService().database;
    return (database.select(database.users)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Set the active user ID in local configuration
  Future<void> setActiveUser(String userId) async {
    final database = await SqLiteService().database;
    final existing = await (database.select(
      database.initialSetup,
    )..where((tbl) => tbl.key.equals(_activeUserIdKey))).getSingleOrNull();

    if (existing != null) {
      await (database.update(database.initialSetup)
            ..where((tbl) => tbl.id.equals(existing.id)))
          .write(InitialSetupCompanion(value: Value(userId)));
    } else {
      await database
          .into(database.initialSetup)
          .insert(
            InitialSetupCompanion(
              key: const Value(_activeUserIdKey),
              value: Value(userId),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  /// Get user by UUID
  Future<User?> getUserById(String id) async {
    final database = await SqLiteService().database;
    return (database.select(
      database.users,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get user by phone number
  Future<User?> getUserByPhone(String phone) async {
    final database = await SqLiteService().database;
    return (database.select(
      database.users,
    )..where((tbl) => tbl.phone.equals(phone))).getSingleOrNull();
  }

  /// Get all active users
  Future<List<User>> getAllUsers() async {
    final database = await SqLiteService().database;
    return (database.select(database.users)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Insert or update a user record
  Future<User> saveUser(UsersCompanion user) async {
    final database = await SqLiteService().database;
    await database.into(database.users).insertOnConflictUpdate(user);
    final saved = await getUserById(user.id.value);
    return saved!;
  }

  /// Soft delete user
  Future<void> deleteUser(String id) async {
    final database = await SqLiteService().database;
    await (database.update(database.users)..where((tbl) => tbl.id.equals(id)))
        .write(const UsersCompanion(isDeleted: Value(true)));
  }

  /// Logout — clears the active user session.
  ///
  /// The profile rows are left in place so signing back in does not have to
  /// re-download everything; [getActiveUser] returning null is what makes the
  /// session gone.
  Future<void> logout() async {
    final database = await SqLiteService().database;
    await (database.delete(
      database.initialSetup,
    )..where((tbl) => tbl.key.equals(_activeUserIdKey))).go();
  }

  /// True when a session is currently active.
  Future<bool> hasActiveSession() async => (await getActiveUser()) != null;

  /// Seed initial default profile if database is fresh
  Future<User> seedInitialDefaultUserIfEmpty() async {
    final database = await SqLiteService().database;
    final existing = await (database.select(database.users)..limit(1)).get();
    if (existing.isNotEmpty) {
      final active = await getActiveUser();
      return active ?? await getFirstStoredUser() ?? existing.first;
    }

    const defaultUserId = 'usr_meera_001';
    const defaultHealthId = 'hd_meera_2026';

    final defaultUser = UsersCompanion(
      id: const Value(defaultUserId),
      name: const Value('Meera Sharma'),
      email: const Value('meera.sharma@example.com'),
      phone: const Value('+91 9876543210'),
      countryCode: const Value('+91'),
      gender: const Value('Female'),
      userType: const Value('User'),
      city: const Value('Bengaluru'),
      pincode: const Value('560001'),
      adline1: const Value('123 Palm Avenue, Indiranagar'),
      userName: const Value('meera_mom'),
      active: const Value(true),
      healthDataID: const Value(defaultHealthId),
      allowearMacAddress: const Value('AA:BB:CC:DD:EE:01'),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
      synced: const Value(0),
    );

    await database.into(database.users).insert(defaultUser);

    // Also seed default health data & active pregnancy
    final defaultHealthData = HealthDataTableCompanion(
      id: const Value(defaultHealthId),
      userId: const Value(defaultUserId),
      height: const Value(162.5),
      weight: const Value(64.0),
      bloodGroup: const Value('B+'),
      allergies: Value(jsonEncode(['Peanuts'])),
      medicalConditions: Value(jsonEncode(['Mild Gestational Anemia'])),
      rchId: const Value('RCH-2026-BLR-8842'),
      pregnancyStatus: const Value('pregnant'),
      lmpDate: Value(
        DateTime.now().subtract(const Duration(days: 168)),
      ), // ~24 weeks
      edDate: Value(DateTime.now().add(const Duration(days: 112))),
      allowFamilyAccess: const Value(true),
      createdAt: Value(DateTime.now()),
      synced: const Value(0),
    );

    await database.into(database.healthDataTable).insert(defaultHealthData);

    final defaultPregnancy = PregnanciesCompanion(
      id: Value(const Uuid().v4()),
      healthId: const Value(defaultHealthId),
      status: const Value('active'),
      lmpDate: Value(DateTime.now().subtract(const Duration(days: 168))),
      edDate: Value(DateTime.now().add(const Duration(days: 112))),
      rchId: const Value('RCH-2026-BLR-8842'),
      registerWithin12Weeks: const Value(true),
      riskStatus: const Value('Low Risk'),
      highestRiskStatus: const Value('Low Risk'),
      gravidity: const Value(1),
      parity: const Value(0),
      livingChildren: const Value(0),
      motherAge: const Value(27),
      createdAt: Value(DateTime.now()),
      synced: const Value(0),
    );

    await database.into(database.pregnancies).insert(defaultPregnancy);
    await setActiveUser(defaultUserId);

    return (await getUserById(defaultUserId))!;
  }
}
