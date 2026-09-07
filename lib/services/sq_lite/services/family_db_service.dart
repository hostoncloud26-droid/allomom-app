import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// CRUD for the family tables: families, family members and join requests.
///
/// Local-only. Every write resets `synced` to 0 so a future sync worker can
/// push the row to allomom-api.
class FamilyDbService {
  static final FamilyDbService instance = FamilyDbService._internal();
  FamilyDbService._internal();

  final _uuid = const Uuid();

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Six-character human-friendly invite code, e.g. `H7K2QP`.
  String _generateFamilyCode() {
    final rnd = Random.secure();
    return List.generate(
      6,
      (_) => _codeAlphabet[rnd.nextInt(_codeAlphabet.length)],
    ).join();
  }

  // ---------------------- FAMILIES ----------------------

  /// Creates a family and enrolls [creatorUserId] as its first member.
  /// Returns the stored family row.
  Future<Family> createFamily({
    required String creatorUserId,
    String? name,
    String? relation,
    String? profileImage,
    String? bannerImage,
  }) async {
    final db = await SqLiteService().database;
    final familyId = _uuid.v4();
    final code = await _uniqueFamilyCode();

    await db.transaction(() async {
      await db.into(db.families).insertOnConflictUpdate(
            FamiliesCompanion(
              id: Value(familyId),
              name: Value(name ?? 'My Family'),
              code: Value(code),
              motherId: Value(creatorUserId),
              createdBy: Value(creatorUserId),
              profileImage: Value(profileImage),
              bannerImage: Value(bannerImage),
              createdAt: Value(DateTime.now()),
              synced: const Value(0),
            ),
          );

      await db.into(db.familyMembersTable).insertOnConflictUpdate(
            FamilyMembersTableCompanion(
              id: Value(_uuid.v4()),
              userid: Value(creatorUserId),
              familyid: Value(familyId),
              relation: Value(relation ?? 'Mother'),
              accessLevel: Value(jsonEncode(const ['owner'])),
              synced: const Value(0),
            ),
          );

      await (db.update(db.users)..where((t) => t.id.equals(creatorUserId)))
          .write(UsersCompanion(
        familyID: Value(familyId),
        synced: const Value(0),
      ));
    });

    return (await getFamilyById(familyId))!;
  }

  Future<String> _uniqueFamilyCode() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = _generateFamilyCode();
      if (await getFamilyByCode(code) == null) return code;
    }
    // Extremely unlikely; fall back to a code that cannot collide.
    return _uuid.v4().substring(0, 8).toUpperCase();
  }

  Future<Family?> getFamilyById(String familyId) async {
    final db = await SqLiteService().database;
    return (db.select(db.families)..where((t) => t.id.equals(familyId)))
        .getSingleOrNull();
  }

  Future<Family?> getFamilyByCode(String code) async {
    final db = await SqLiteService().database;
    return (db.select(db.families)
          ..where((t) => t.code.equals(code.toUpperCase())))
        .getSingleOrNull();
  }

  /// The family [userId] belongs to, resolved through their membership row.
  Future<Family?> getMyFamily(String userId) async {
    final db = await SqLiteService().database;
    final membership = await (db.select(db.familyMembersTable)
          ..where((t) => t.userid.equals(userId))
          ..limit(1))
        .getSingleOrNull();

    final familyId = membership?.familyid;
    if (familyId != null && familyId.isNotEmpty) {
      return getFamilyById(familyId);
    }

    final user = await (db.select(db.users)..where((t) => t.id.equals(userId)))
        .getSingleOrNull();
    final linked = user?.familyID;
    if (linked != null && linked.isNotEmpty) return getFamilyById(linked);
    return null;
  }

  Future<void> updateFamily(FamiliesCompanion family) async {
    final db = await SqLiteService().database;
    await (db.update(db.families)..where((t) => t.id.equals(family.id.value)))
        .write(family.copyWith(synced: const Value(0)));
  }

  // ---------------------- MEMBERS ----------------------

  /// Members of [familyId] paired with their user row when one exists locally.
  Future<List<FamilyMemberWithUser>> getFamilyMembers(String familyId) async {
    final db = await SqLiteService().database;
    final members = await (db.select(db.familyMembersTable)
          ..where((t) => t.familyid.equals(familyId)))
        .get();

    final result = <FamilyMemberWithUser>[];
    for (final member in members) {
      User? user;
      final uid = member.userid;
      if (uid != null && uid.isNotEmpty) {
        user = await (db.select(db.users)..where((t) => t.id.equals(uid)))
            .getSingleOrNull();
      }
      result.add(FamilyMemberWithUser(member: member, user: user));
    }
    return result;
  }

  /// Adds a member to [familyId], creating a placeholder user row so the
  /// member shows up with a name and phone even before they sign up.
  ///
  /// When [lmpDate] is given a health-data row is created for the member too,
  /// so a pregnant family member carries their own dates.
  Future<String> createFamilyMember({
    required String familyId,
    required String name,
    String? phone,
    String? email,
    String? relation,
    String? gender,
    DateTime? dob,
    int? age,
    DateTime? lmpDate,
    List<String> accessLevel = const ['view'],
  }) async {
    final db = await SqLiteService().database;
    final memberUserId = _uuid.v4();
    final memberId = _uuid.v4();

    // Derive an approximate birth date when only an age was captured.
    final resolvedDob = dob ??
        (age != null && age > 0
            ? DateTime(DateTime.now().year - age, 1, 1)
            : null);

    await db.transaction(() async {
      String? healthDataId;

      if (lmpDate != null) {
        healthDataId = _uuid.v4();
        await db.into(db.healthDataTable).insertOnConflictUpdate(
              HealthDataTableCompanion(
                id: Value(healthDataId),
                userId: Value(memberUserId),
                lmpDate: Value(lmpDate),
                edDate: Value(lmpDate.add(const Duration(days: 280))),
                pregnancyStatus: const Value('pregnant'),
                createdAt: Value(DateTime.now()),
                synced: const Value(0),
              ),
            );
      }

      await db.into(db.users).insertOnConflictUpdate(
            UsersCompanion(
              id: Value(memberUserId),
              name: Value(name),
              phone: Value(phone),
              email: Value(email),
              gender: Value(gender),
              dob: Value(resolvedDob),
              familyID: Value(familyId),
              healthDataID: Value(healthDataId),
              userType: const Value('FamilyMember'),
              isDeleted: const Value(false),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
              synced: const Value(0),
            ),
          );

      await db.into(db.familyMembersTable).insertOnConflictUpdate(
            FamilyMembersTableCompanion(
              id: Value(memberId),
              userid: Value(memberUserId),
              familyid: Value(familyId),
              relation: Value(relation),
              accessLevel: Value(jsonEncode(accessLevel)),
              synced: const Value(0),
            ),
          );
    });

    return memberUserId;
  }

  /// Removes [userId] from [familyId]. The placeholder user row is soft
  /// deleted so nothing else that references it breaks.
  Future<void> removeFamilyMember({
    required String familyId,
    required String userId,
  }) async {
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await (db.delete(db.familyMembersTable)
            ..where((t) => t.familyid.equals(familyId) & t.userid.equals(userId)))
          .go();
      await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
        UsersCompanion(
          familyID: const Value(null),
          isDeleted: const Value(true),
          synced: const Value(0),
        ),
      );
    });
  }

  /// Joins the family that owns [code]. Returns the family, or null when the
  /// code does not match any locally-known family.
  Future<Family?> joinFamilyByCode({
    required String code,
    required String userId,
    String? relation,
  }) async {
    final family = await getFamilyByCode(code);
    if (family == null) return null;

    final db = await SqLiteService().database;
    final existing = await (db.select(db.familyMembersTable)
          ..where((t) => t.familyid.equals(family.id) & t.userid.equals(userId)))
        .getSingleOrNull();

    await db.transaction(() async {
      if (existing == null) {
        await db.into(db.familyMembersTable).insertOnConflictUpdate(
              FamilyMembersTableCompanion(
                id: Value(_uuid.v4()),
                userid: Value(userId),
                familyid: Value(family.id),
                relation: Value(relation ?? 'Member'),
                accessLevel: Value(jsonEncode(const ['view'])),
                synced: const Value(0),
              ),
            );
      }
      await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
        UsersCompanion(
          familyID: Value(family.id),
          synced: const Value(0),
        ),
      );
    });

    return family;
  }

  /// Leaves the current family. Returns false when the user had none.
  Future<bool> exitFamily(String userId) async {
    final family = await getMyFamily(userId);
    if (family == null) return false;
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await (db.delete(db.familyMembersTable)
            ..where((t) => t.userid.equals(userId)))
          .go();
      await (db.update(db.users)..where((t) => t.id.equals(userId))).write(
        UsersCompanion(
          familyID: const Value(null),
          synced: const Value(0),
        ),
      );
    });
    return true;
  }

  // ---------------------- REQUESTS ----------------------

  Future<String> createFamilyRequest({
    required String userId,
    required String familyId,
    Duration validFor = const Duration(days: 7),
  }) async {
    final db = await SqLiteService().database;
    final id = _uuid.v4();
    await db.into(db.familyRequestsTable).insertOnConflictUpdate(
          FamilyRequestsTableCompanion(
            id: Value(id),
            userId: Value(userId),
            familyId: Value(familyId),
            status: const Value('pending'),
            createdAt: Value(DateTime.now()),
            expiresAt: Value(DateTime.now().add(validFor)),
            synced: const Value(0),
          ),
        );
    return id;
  }

  Future<List<FamilyRequestsTableData>> getFamilyRequests(
      String familyId) async {
    final db = await SqLiteService().database;
    return (db.select(db.familyRequestsTable)
          ..where((t) => t.familyId.equals(familyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> setFamilyRequestStatus(String requestId, String status) async {
    final db = await SqLiteService().database;
    await (db.update(db.familyRequestsTable)
          ..where((t) => t.id.equals(requestId)))
        .write(FamilyRequestsTableCompanion(
      status: Value(status),
      synced: const Value(0),
    ));
  }

  // ---------------------- SYNC HELPERS ----------------------

  Future<List<Family>> unsyncedFamilies() async {
    final db = await SqLiteService().database;
    return (db.select(db.families)..where((t) => t.synced.equals(0))).get();
  }

  Future<List<FamilyMembersTableData>> unsyncedFamilyMembers() async {
    final db = await SqLiteService().database;
    return (db.select(db.familyMembersTable)..where((t) => t.synced.equals(0)))
        .get();
  }
}

/// A membership row joined with the user it points at.
class FamilyMemberWithUser {
  const FamilyMemberWithUser({required this.member, this.user});

  final FamilyMembersTableData member;
  final User? user;

  String get userId => member.userid ?? '';
  String get name => user?.name ?? 'Family Member';
  String get relation => member.relation ?? 'Member';
  String? get phone => user?.phone;
  String? get image => user?.image;

  List<String> get accessLevel {
    try {
      final decoded = jsonDecode(member.accessLevel);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return const [];
  }
}
