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


/// One person in the household, as the family screens list them.
class FamilyMemberInfo {
  const FamilyMemberInfo({
    required this.userId,
    required this.name,
    this.relation,
    this.relationToMe,
    this.phone,
    this.countryCode,
    this.profilePicture,
    this.isMe = false,
    this.isRegistered = false,
  });

  final String userId;

  /// What the viewer calls them — their nickname when one is set, their own
  /// name otherwise.
  final String name;

  /// "mother" / "father" — what they are to the household.
  final String? relation;

  /// "wife" / "husband" — what they are to the viewer.
  final String? relationToMe;

  final String? phone;
  final String? countryCode;
  final String? profilePicture;

  /// True for the viewer's own row.
  final bool isMe;

  /// True once they have signed in and claimed the account, rather than being
  /// a placeholder their partner created for them.
  final bool isRegistered;

  bool get isParent {
    final r = (relation ?? '').toLowerCase();
    return r == 'mother' || r == 'father';
  }

  String get displayRelation {
    final r = (relationToMe ?? relation ?? '').trim();
    if (r.isEmpty) return 'Member';
    return r[0].toUpperCase() + r.substring(1);
  }
}

/// The household itself: the name, the invite code and who is in it.
class FamilyGroup {
  const FamilyGroup({
    required this.id,
    this.name,
    this.code,
    this.members = const [],
  });

  final String id;
  final String? name;
  final String? code;
  final List<FamilyMemberInfo> members;

  String get displayName => (name ?? '').trim().isEmpty ? 'My Family' : name!.trim();

  int get memberCount => members.length;

  FamilyMemberInfo? get me {
    for (final m in members) {
      if (m.isMe) return m;
    }
    return null;
  }

  /// The other parent, if the household has one. Not simply "the other
  /// member": a grandmother added from the People screen is a member too.
  FamilyMemberInfo? get otherParent {
    for (final m in members) {
      if (!m.isMe && m.isParent) return m;
    }
    return null;
  }

  bool get hasOtherParent => otherParent != null;
}

/// One member of a family being previewed from its invite code.
///
/// Thinner than [FamilyMemberInfo] because the server keeps it that way: a
/// six-character code is guessable, so a preview carries a name and a face but
/// no phone number or id.
class FamilyPreviewMember {
  const FamilyPreviewMember({
    this.name,
    this.relation,
    this.profilePicture,
    this.isRegistered = false,
  });

  final String? name;
  final String? relation;
  final String? profilePicture;
  final bool isRegistered;
}

/// What an invite code resolves to, and what joining it would mean for the
/// caller.
class FamilyCodePreview {
  const FamilyCodePreview({
    required this.id,
    this.name,
    this.code,
    this.memberCount = 0,
    this.members = const [],
    this.isMember = false,
    this.hasOtherFamily = false,
  });

  final String id;
  final String? name;
  final String? code;
  final int memberCount;
  final List<FamilyPreviewMember> members;

  /// True when the caller is already in this family — joining is a no-op.
  final bool isMember;

  /// True when the caller belongs to a different family and has to leave it
  /// first.
  final bool hasOtherFamily;

  String get displayName =>
      (name ?? '').trim().isEmpty ? 'Family' : name!.trim();

  FamilyPreviewMember? parent(String relation) {
    for (final m in members) {
      if ((m.relation ?? '').toLowerCase() == relation) return m;
    }
    return null;
  }

  FamilyPreviewMember? get mother => parent('mother');
  FamilyPreviewMember? get father => parent('father');

  static FamilyCodePreview? fromJson(dynamic item) {
    if (item is! Map) return null;
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return FamilyCodePreview(
      id: id,
      name: item['name']?.toString(),
      code: item['code']?.toString(),
      memberCount: (item['member_count'] as num?)?.toInt() ?? 0,
      members: (item['members'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (m) => FamilyPreviewMember(
              name: m['name']?.toString(),
              relation: m['relation']?.toString(),
              profilePicture: m['profile_picture']?.toString(),
              isRegistered: m['is_registered'] == true,
            ),
          )
          .toList(),
      isMember: item['is_member'] == true,
      hasOtherFamily: item['has_other_family'] == true,
    );
  }
}

/// The answer to "what is behind this code?" — one of the two fields is set.
class FamilyCodeLookup {
  const FamilyCodeLookup({this.preview, this.error});

  final FamilyCodePreview? preview;

  /// A message to show. Set when the code matched nothing, or the lookup could
  /// not be made at all.
  final String? error;

  bool get found => preview != null;
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

  FamilyGroup? _family;

  /// The household the user belongs to, or null while they have none — which
  /// is an ordinary state during registration, not an error.
  FamilyGroup? get family => _family;
  bool get hasFamily => _family != null;

  String get _meId => MainController.instance.userId;

  /// The role to send when a screen has not stated one, read off the profile.
  String get _myRole =>
      MainController.instance.gender.trim().toLowerCase() == 'male'
          ? 'Dad'
          : 'Mom';

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Rebuilds [family] and [partner] from the local tables. Safe offline, and
  /// what the screens show before any network call returns.
  Future<void> loadFromLocal() async {
    final me = _meId;
    if (me.isEmpty) {
      _family = null;
      _partner = null;
      update();
      return;
    }

    final db = await _db;
    final family = await FamilyDbService.instance.getMyFamily(me);
    if (family == null) {
      _family = null;
      _partner = null;
      update();
      return;
    }

    final members = await FamilyDbService.instance.getFamilyMembers(family.id);
    final people = <FamilyMemberInfo>[];

    for (final member in members) {
      if (member.userId.isEmpty) continue;
      final isMe = member.userId == me;

      final user = await (db.select(db.users)
            ..where((u) => u.id.equals(member.userId)))
          .getSingleOrNull();

      // The nickname is the caller's own record of this person, so it only
      // exists for other people — nobody has a nickname for themselves.
      final nickname = isMe
          ? null
          : await FamilyDbService.instance.nicknameFor(
              viewerId: me,
              relatedUserId: member.userId,
            );
      final relationToMe = isMe
          ? null
          : await FamilyDbService.instance.relationFor(
              viewerId: me,
              relatedUserId: member.userId,
            );

      people.add(
        FamilyMemberInfo(
          userId: member.userId,
          name: nickname ?? member.name,
          relation: member.member.relation,
          relationToMe: relationToMe,
          phone: user?.phone,
          countryCode: user?.countryCode,
          profilePicture: user?.profilePicture,
          isMe: isMe,
          isRegistered: user?.isRegistered ?? false,
        ),
      );
    }

    _family = FamilyGroup(
      id: family.id,
      name: family.name,
      code: family.code,
      members: people,
    );

    // The other *parent*, not simply the other member: a household can also
    // hold a grandmother or an aunt added from the People screen, and picking
    // whoever happens to come back first would show the wrong person here.
    final other = _family!.otherParent;
    _partner = other == null
        ? null
        : PartnerLink(
            userId: other.userId,
            displayName: other.name,
            phone: other.phone,
            countryCode: other.countryCode,
            relationToMe: other.relationToMe,
            familyRelation: other.relation,
            familyName: family.name,
            familyCode: family.code,
            profilePicture: other.profilePicture,
            isRegistered: other.isRegistered,
          );
    update();
  }

  /// Local first so the screen has something to draw, then the server.
  ///
  /// Named `reload` rather than `refresh` because GetxController already owns
  /// that name for "rebuild the widgets".
  Future<void> reload() async {
    await loadFromLocal();
    await refreshFromServer();
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

  /// Adds someone who isn't going to install the app and register themselves
  /// — the People screen's manual "Add member" flow. Returns null on success,
  /// or a message to show.
  Future<String?> addMember({
    required String name,
    required String phone,
    required dynamic age,
    required String gender,
    required String relationship,
    String? profilePic,
    DateTime? lmpDate,
  }) async {
    final response = await FamilyApi.createFamilyMember(
      name: name,
      phone: phone,
      age: age,
      gender: gender,
      relationship: relationship,
      profilePic: profilePic,
      lmpDate: lmpDate,
    );

    if (!response.success) {
      debugPrint('⚠️ [FamilyController] addMember failed: ${response.detail}');
      return response.networkError
          ? 'No connection — adding a member needs you to be online.'
          : response.detail;
    }

    await _mirror(response.item);
    return null;
  }

  // ── Joining and leaving ────────────────────────────────────────────────────

  /// What [code] resolves to, without joining anything.
  ///
  /// Server-side on purpose: the family being joined lives on somebody else's
  /// phone, so a lookup against this device's tables would only ever find a
  /// household this user already knows about.
  Future<FamilyCodeLookup> previewCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.length < 4) {
      return const FamilyCodeLookup(error: 'Enter the full family code.');
    }

    final response = await FamilyApi.checkFamilyCode(trimmed);
    if (!response.success) {
      return FamilyCodeLookup(
        error: response.networkError
            ? 'No connection — checking a family code needs you to be online.'
            : (response.detail.isEmpty
                  ? "That family code doesn't match any family."
                  : response.detail),
      );
    }

    final preview = FamilyCodePreview.fromJson(response.item);
    if (preview == null) {
      return const FamilyCodeLookup(
        error: "That family code doesn't match any family.",
      );
    }
    return FamilyCodeLookup(preview: preview);
  }

  /// Joins the family behind [code]. Returns null on success, or a message.
  ///
  /// [role] is the caller's own role — "Mom" or "Dad" — which decides the
  /// relation their membership row gets; it defaults to what their profile
  /// says. The server refuses this for someone already in another family, so
  /// the message it returns is what the screen shows.
  Future<String?> joinByCode(String code, {String? role}) async {
    final response = await FamilyApi.joinFamily(code, role: role ?? _myRole);

    if (!response.success) {
      debugPrint('⚠️ [FamilyController] joinFamily failed: ${response.detail}');
      return response.networkError
          ? 'No connection — joining a family needs you to be online.'
          : response.detail;
    }

    await _mirror(response.item);
    return null;
  }

  /// Removes [userId] — another member, never the caller — from the current
  /// family. Returns null on success, or a message.
  Future<String?> removeMember(String userId) async {
    final response = await FamilyApi.removeFamilyMember(userId);

    if (!response.success) {
      debugPrint('⚠️ [FamilyController] removeMember failed: ${response.detail}');
      return response.networkError
          ? 'No connection — removing a member needs you to be online.'
          : response.detail;
    }

    await _mirror(response.item);
    return null;
  }

  /// Leaves the current family. Returns null on success, or a message.
  ///
  /// The local membership rows go with it, so the screens stop showing a
  /// household this user is no longer part of even before the next sync.
  Future<String?> exitFamily() async {
    final response = await FamilyApi.exitFamily();

    if (!response.success) {
      debugPrint('⚠️ [FamilyController] exitFamily failed: ${response.detail}');
      return response.networkError
          ? 'No connection — leaving a family needs you to be online.'
          : response.detail;
    }

    final me = _meId;
    if (me.isNotEmpty) {
      await FamilyDbService.instance.exitFamily(me);
    }
    _family = null;
    _partner = null;
    update();
    return null;
  }

  Future<void> _mirror(dynamic item) async {
    if (item is! Map) {
      // A caller with no family yet answers `item: null`, which is an ordinary
      // state rather than a failure. Re-reading the local tables rather than
      // blanking them keeps a family created offline — the People screen can
      // do that — from being thrown away by a server that has not seen it yet.
      await loadFromLocal();
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
    _family = null;
    update();
  }
}
