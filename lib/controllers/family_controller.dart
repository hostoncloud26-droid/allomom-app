import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:allomom/api/family_api.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/family_db_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// The caller's partner as a screen needs to show them.
///
/// [displayName] is the nickname — what the caller calls their partner — which
/// is deliberately not the partner's own `users.name`. The two are separate
/// records and editing this screen changes only the first.
class PartnerLink {
  const PartnerLink({
    required this.userId,
    required this.displayName,
    this.phone,
    this.countryCode,
    this.relationToMe,
    this.familyRelation,
    this.familyName,
    this.familyCode,
    this.profilePicture,
    this.isRegistered = false,
  });

  final String userId;
  final String displayName;
  final String? phone;
  final String? countryCode;

  /// "wife" / "husband" — what they are to the caller.
  final String? relationToMe;

  /// "mother" / "father" — what they are to the household.
  final String? familyRelation;

  final String? familyName;
  final String? familyCode;
  final String? profilePicture;

  /// True once the partner has signed in and claimed the account. Their phone
  /// stops being editable from here at that point — it is their credential.
  final bool isRegistered;
}

/// The household, and the partner link the registration flow builds.
///
/// Writes go to the server first rather than to sqlite. Creating a partner is
/// not one row: it is a family, two membership rows, a user record, a relation
/// in each direction and a nickname, and the server does all six in one
/// transaction and mints the ids. The response is then mirrored into the local
/// tables so the People screen and every offline read see the same thing.
class FamilyController extends GetxController {
  static FamilyController get instance => Get.isRegistered<FamilyController>()
      ? Get.find<FamilyController>()
      : Get.put(FamilyController._(), permanent: true);

  FamilyController._();

  PartnerLink? _partner;
  PartnerLink? get partner => _partner;
  bool get hasPartner => _partner != null;

  String get _meId => MainController.instance.userId;

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Rebuilds [partner] from the local tables. Safe offline, and what the
  /// screen shows before any network call returns.
  Future<void> loadFromLocal() async {
    final me = _meId;
    if (me.isEmpty) {
      _partner = null;
      update();
      return;
    }

    final db = await _db;
    final family = await FamilyDbService.instance.getMyFamily(me);
    if (family == null) {
      _partner = null;
      update();
      return;
    }

    // The other *parent*, not simply the other member: a household can also
    // hold a grandmother or an aunt added from the People screen, and picking
    // whoever happens to come back first would show the wrong person here.
    final members = await FamilyDbService.instance.getFamilyMembers(family.id);
    FamilyMemberWithUser? other;
    for (final m in members) {
      if (m.userId.isEmpty || m.userId == me) continue;
      final relation = (m.member.relation ?? '').trim().toLowerCase();
      if (relation == 'mother' || relation == 'father') {
        other = m;
        break;
      }
    }

    if (other == null) {
      _partner = null;
      update();
      return;
    }

    final nickname = await FamilyDbService.instance.nicknameFor(
      viewerId: me,
      relatedUserId: other.userId,
    );
    final relation = await FamilyDbService.instance.relationFor(
      viewerId: me,
      relatedUserId: other.userId,
    );

    final user = await (db.select(db.users)
          ..where((u) => u.id.equals(other!.userId)))
        .getSingleOrNull();

    _partner = PartnerLink(
      userId: other.userId,
      // The nickname is the point of this screen; the partner's own name is
      // only a fallback for a member who was added some other way.
      displayName: nickname ?? other.name,
      phone: user?.phone,
      countryCode: user?.countryCode,
      relationToMe: relation,
      familyRelation: other.member.relation,
      familyName: family.name,
      familyCode: family.code,
      profilePicture: user?.profilePicture,
      isRegistered: user?.isRegistered ?? false,
    );
    update();
  }

  /// Pulls the family from the server and mirrors it locally.
  Future<void> refreshFromServer() async {
    final response = await FamilyApi.getMyFamily();
    if (!response.success) return;
    await _mirror(response.item);
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Registers [name] as the caller's partner.
  ///
  /// Returns null on success, or a message to show. The whole link is built
  /// server-side in one transaction, so a failure leaves nothing half-created
  /// and the screen can simply report it.
  Future<String?> linkPartner({
    required String name,
    String? phone,
    String countryCode = '+91',
    String role = 'Mom',
    String? familyName,
  }) async {
    final response = await FamilyApi.linkPartner(
      name: name,
      phone: phone,
      countryCode: countryCode,
      role: role,
      familyName: familyName,
    );

    if (!response.success) {
      debugPrint('⚠️ [FamilyController] linkPartner failed: ${response.detail}');
      return response.networkError
          ? 'No connection — your partner will be saved when you are back online.'
          : response.detail;
    }

    await _mirror(response.item);
    return null;
  }

  /// Applies an edit to the existing link.
  ///
  /// The split matters: [name] rewrites the caller's nickname for their
  /// partner, while [phone] rewrites the partner's own user row. Passing null
  /// for either leaves it untouched.
  Future<String?> updatePartner({String? name, String? phone}) async {
    if (name == null && phone == null) return null;

    final response = await FamilyApi.updatePartner(name: name, phone: phone);

    if (!response.success) {
      debugPrint('⚠️ [FamilyController] updatePartner failed: ${response.detail}');
      return response.networkError
          ? 'No connection — this change will be saved when you are back online.'
          : response.detail;
    }

    await _mirror(response.item);
    return null;
  }

  Future<void> _mirror(dynamic item) async {
    if (item is! Map) {
      // A caller with no family yet answers `item: null`, which is an ordinary
      // state rather than a failure.
      _partner = null;
      update();
      return;
    }
    final me = _meId;
    if (me.isEmpty) return;

    await FamilyDbService.instance.mirrorServerFamily(
      Map<String, dynamic>.from(item),
      viewerId: me,
    );
    await loadFromLocal();
  }

  /// Forgets the in-memory link. The local tables are cleared by
  /// `clearAccountData` on sign-out.
  void clear() {
    _partner = null;
    update();
  }
}
