import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sync/sync_mappers.dart';

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
  ///
  /// A user can end up with more than one membership row: a family made
  /// offline via the People screen's "Create Family" (local-only — nothing
  /// pushes it to the server) sitting alongside the real, server-known family
  /// that `refreshFromServer` mirrors in on login. Without a deterministic
  /// pick here, which one shows up flips on every reload. The server-confirmed
  /// family always wins, since it is the one other devices can see too.
  Future<Family?> getMyFamily(String userId) async {
    final db = await SqLiteService().database;
    final memberships = await (db.select(db.familyMembersTable)
          ..where((t) => t.userid.equals(userId)))
        .get();

    Family? fallback;
    for (final membership in memberships) {
      final familyId = membership.familyid;
      if (familyId == null || familyId.isEmpty) continue;
      final family = await getFamilyById(familyId);
      if (family == null) continue;
      if (family.synced == 1) return family;
      fallback ??= family;
    }
    return fallback;
  }

  Future<void> updateFamily(FamiliesCompanion family) async {
    final db = await SqLiteService().database;
    await (db.update(db.families)..where((t) => t.id.equals(family.id.value)))
        .write(family.copyWith(synced: const Value(0)));
  }

  // ---------------------- MEMBERS ----------------------

  /// The placeholder name the backend gives a scrubbed account
  /// (`account_deletion.py`'s `user.name = "Deleted user"`). The API's
  /// `UserOut` never sends `deleted_at` for a member's user, so this literal
  /// string is the only signal the app has that a cached member row belongs
  /// to a deleted account — used to hide it even if the membership row
  /// itself is stale (e.g. a failed `refreshFromServer` left it behind, or
  /// it predates the server tombstoning removed members).
  static const String _deletedUserPlaceholderName = 'Deleted user';

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
      if (user != null &&
          (user.deletedAt != null || user.name == _deletedUserPlaceholderName)) {
        continue;
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
              userType: const Value('FamilyMember'),
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

  /// Removes [userId] from [familyId].
  ///
  /// Only the membership row goes. The `users` row is left untouched, on
  /// purpose — matching the server's own `detach_member`: leaving a family is
  /// not leaving the app, and `users` is one of the generically-synced
  /// tables, so soft-deleting it here would dirty that person's whole cached
  /// profile for the next push.
  Future<void> removeFamilyMember({
    required String familyId,
    required String userId,
  }) async {
    final db = await SqLiteService().database;
    await (db.delete(db.familyMembersTable)
          ..where((t) => t.familyid.equals(familyId) & t.userid.equals(userId)))
        .go();
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
    });

    return family;
  }

  /// Leaves the current family. Returns false when the user had none.
  ///
  /// Mirrors the server's own `exit_family_controller`: when the leaver was
  /// the last member — counting placeholders added from the People screen
  /// the same way the server's `live_member_count` does — the family row
  /// goes too, rather than sitting in SQLite as an orphan nothing ever reads
  /// again.
  Future<bool> exitFamily(String userId) async {
    final family = await getMyFamily(userId);
    if (family == null) return false;
    final db = await SqLiteService().database;
    await db.transaction(() async {
      await (db.delete(db.familyMembersTable)
            ..where((t) => t.userid.equals(userId)))
          .go();

      final remaining = await (db.select(db.familyMembersTable)
            ..where((t) => t.familyid.equals(family.id)))
          .get();
      if (remaining.isEmpty) {
        await (db.delete(db.families)..where((t) => t.id.equals(family.id)))
            .go();
      }
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

  // ---------------------- SERVER MIRROR ----------------------

  /// Writes a `/family` payload into the local tables, replacing what is there.
  ///
  /// The server owns the ids here — it mints the family, the membership rows
  /// and the partner's user id — so this overwrites rather than merges, and
  /// marks everything `synced = 1`. [viewerId] is whose view the payload was
  /// built for: `relation_to_me` and `nick_name` are that user's own record of
  /// each member, so they are stored as rows owned by them.
  ///
  /// Members that vanished from the payload are dropped, which is how a
  /// replaced partner disappears locally without needing a tombstone.
  Future<void> mirrorServerFamily(
    Map<String, dynamic> payload, {
    required String viewerId,
  }) async {
    final db = await SqLiteService().database;
    final familyId = payload['id']?.toString();
    if (familyId == null || familyId.isEmpty) return;

    final members = (payload['members'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    // The local families table keeps the two parents denormalised, so the
    // People screen can name them without walking the membership rows.
    String? parentId(String relation) {
      for (final m in members) {
        if (m['relation']?.toString().toLowerCase() == relation) {
          return m['user_id']?.toString();
        }
      }
      return null;
    }

    await db.transaction(() async {
      await db.into(db.families).insertOnConflictUpdate(
            FamiliesCompanion(
              id: Value(familyId),
              name: Value(SyncCodec.text(payload['name'])),
              code: Value(SyncCodec.text(payload['code'])),
              motherId: Value(parentId('mother')),
              fatherId: Value(parentId('father')),
              createdBy: Value(SyncCodec.text(payload['created_by'])),
              profileImage: Value(SyncCodec.text(payload['profile_image'])),
              bannerImage: Value(SyncCodec.text(payload['banner_image'])),
              createdAt: Value(
                SyncCodec.date(payload['created_at']) ?? DateTime.now(),
              ),
              synced: const Value(1),
            ),
          );

      final keptMemberIds = <String>[];

      for (final member in members) {
        final memberId = member['id']?.toString();
        final memberUserId = member['user_id']?.toString();
        if (memberId == null || memberUserId == null) continue;
        keptMemberIds.add(memberId);

        final user = member['user'];
        if (user is Map) {
          await const UserMapper()
              .applyServerRow(db, Map<String, dynamic>.from(user));
        }

        await db.into(db.familyMembersTable).insertOnConflictUpdate(
              FamilyMembersTableCompanion(
                id: Value(memberId),
                userid: Value(memberUserId),
                familyid: Value(familyId),
                relation: Value(SyncCodec.text(member['relation'])),
                accessLevel: Value(
                  jsonEncode(
                    member['is_me'] == true
                        ? const ['owner']
                        : const ['view'],
                  ),
                ),
                synced: const Value(1),
              ),
            );

        if (memberUserId == viewerId) continue;

        await _mirrorRelation(
          db,
          viewerId: viewerId,
          relatedUserId: memberUserId,
          relationType: SyncCodec.text(member['relation_to_me']),
        );
        await _mirrorNickname(
          db,
          viewerId: viewerId,
          relatedUserId: memberUserId,
          nickName: SyncCodec.text(member['nick_name']),
        );
      }

      // Anyone the server no longer lists has left, or was replaced.
      await (db.delete(db.familyMembersTable)
            ..where(
              (t) =>
                  t.familyid.equals(familyId) &
                  t.id.isNotIn(keptMemberIds),
            ))
          .go();
    });
  }

  /// Upserts the viewer's relation row for one member, clearing it when the
  /// server reports none.
  Future<void> _mirrorRelation(
    AppDriftDatabase db, {
    required String viewerId,
    required String relatedUserId,
    String? relationType,
  }) async {
    Expression<bool> where(UserRelations t) =>
        t.userId.equals(viewerId) & t.relatedUserId.equals(relatedUserId);

    if (relationType == null || relationType.isEmpty) {
      await (db.delete(db.userRelations)..where(where)).go();
      return;
    }

    final existing =
        await (db.select(db.userRelations)..where(where)).getSingleOrNull();

    if (existing == null) {
      await db.into(db.userRelations).insert(
            UserRelationsCompanion.insert(
              userId: viewerId,
              relatedUserId: relatedUserId,
              relationType: relationType,
              synced: const Value(1),
            ),
          );
    } else {
      await (db.update(db.userRelations)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        UserRelationsCompanion(
          relationType: Value(relationType),
          synced: const Value(1),
        ),
      );
    }
  }

  /// Upserts the viewer's nickname for one member, clearing it when the server
  /// reports none.
  Future<void> _mirrorNickname(
    AppDriftDatabase db, {
    required String viewerId,
    required String relatedUserId,
    String? nickName,
  }) async {
    Expression<bool> where(UserNickNames t) =>
        t.userId.equals(viewerId) & t.relatedUserId.equals(relatedUserId);

    if (nickName == null || nickName.isEmpty) {
      await (db.delete(db.userNickNames)..where(where)).go();
      return;
    }

    final existing =
        await (db.select(db.userNickNames)..where(where)).getSingleOrNull();

    if (existing == null) {
      await db.into(db.userNickNames).insert(
            UserNickNamesCompanion.insert(
              userId: viewerId,
              relatedUserId: relatedUserId,
              nickName: nickName,
              synced: const Value(1),
            ),
          );
    } else {
      await (db.update(db.userNickNames)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        UserNickNamesCompanion(
          nickName: Value(nickName),
          synced: const Value(1),
        ),
      );
    }
  }

  /// What [viewerId] calls [relatedUserId], if anything.
  Future<String?> nicknameFor({
    required String viewerId,
    required String relatedUserId,
  }) async {
    final db = await SqLiteService().database;
    final row = await (db.select(db.userNickNames)
          ..where((t) =>
              t.userId.equals(viewerId) &
              t.relatedUserId.equals(relatedUserId)))
        .getSingleOrNull();
    return row?.nickName;
  }

  /// What [relatedUserId] is to [viewerId] — "wife", "husband" — if recorded.
  Future<String?> relationFor({
    required String viewerId,
    required String relatedUserId,
  }) async {
    final db = await SqLiteService().database;
    final row = await (db.select(db.userRelations)
          ..where((t) =>
              t.userId.equals(viewerId) &
              t.relatedUserId.equals(relatedUserId)))
        .getSingleOrNull();
    return row?.relationType;
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
  String? get image => user?.profilePicture;

  List<String> get accessLevel {
    try {
      final decoded = jsonDecode(member.accessLevel);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return const [];
  }
}
