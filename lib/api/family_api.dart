import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/family` — the household and the partner registration links into it.
class FamilyApi {
  /// The caller's family with its members. `item` is null before one exists,
  /// which is an ordinary state during registration rather than an error.
  static Future<APIResponse> getMyFamily() async {
    return await ApiBase.get("/family/my");
  }

  /// Registers [name] as the caller's partner, in one server-side transaction:
  /// the family, both parents' membership rows, the partner's user record, the
  /// relation in both directions, and the caller's nickname for them.
  ///
  /// Idempotent — sending it again updates the existing link rather than
  /// building a second one, which is what happens when the user steps back a
  /// screen and taps Next again.
  static Future<APIResponse> linkPartner({
    required String name,
    String? phone,
    String countryCode = '+91',
    String role = 'Mom',
    String? familyName,
  }) async {
    return await ApiBase.post("/family/partner", {
      "name": name.trim(),
      if (phone != null && phone.trim().isNotEmpty) "phone": phone.trim(),
      "country_code": countryCode,
      "role": role,
      if (familyName != null && familyName.trim().isNotEmpty)
        "family_name": familyName.trim(),
    });
  }

  /// Edits an existing link. [name] rewrites the caller's nickname for their
  /// partner; [phone] rewrites the partner's own user row. Omitted fields are
  /// left alone.
  static Future<APIResponse> updatePartner({
    String? name,
    String? phone,
    String? countryCode,
  }) async {
    return await ApiBase.patch("/family/partner", {
      if (name != null) "name": name.trim(),
      if (phone != null) "phone": phone.trim(),
      if (countryCode != null) "country_code": countryCode,
    });
  }

  static Future<APIResponse> joinFamily(String code) async {
    return await ApiBase.newPostRequest("/family/join", {
      "code": code.trim().toUpperCase(),
    });
  }

  static Future<APIResponse> checkFamilyCode(String code) async {
    return await ApiBase.newPostRequest("/family/info/bycode?code=${code.trim().toUpperCase()}", {
      "code": code.trim().toUpperCase(),
    });
  }

  static Future<APIResponse> createFamily({
    String? name,
    String? profileImage,
    String? bannerImage,
  }) async {
    return await ApiBase.newPostRequest("/family/create", {
      if (name != null) "name": name,
      if (profileImage != null) "profileImage": profileImage,
      if (bannerImage != null) "bannerImage": bannerImage,
    });
  }

  static Future<APIResponse> updateFamily({
    String? name,
    String? profileImage,
    String? bannerImage,
  }) async {
    return await ApiBase.newPutRequest("/family/update", {
      if (name != null) "name": name,
      if (profileImage != null) "profileImage": profileImage,
      if (bannerImage != null) "bannerImage": bannerImage,
    });
  }

  static Future<APIResponse> createFamilyMember({
    required String name,
    required String phone,
    required dynamic age,
    required String gender,
    required String relationship,
    String? familyID,
    String? profilePic,
    DateTime? lmpDate,
  }) async {
    final intAge = int.tryParse(age.toString()) ?? 25;
    return await ApiBase.newPostRequest("/family/create_member", {
      "name": name.trim(),
      "phone": phone.trim(),
      "age": intAge,
      "gender": gender.toLowerCase(),
      "relationship": relationship,
      if (familyID != null) "familyID": familyID,
      if (profilePic != null) "profile_pic": profilePic,
      if (lmpDate != null) "lmp_date": lmpDate.toIso8601String(),
    });
  }

  static Future<APIResponse> removeFamilyMember(String userId) async {
    return await ApiBase.newDeleteRequest("/family/remove_member/$userId");
  }

  static Future<APIResponse> exitFamily() async {
    return await ApiBase.newPostRequest("/family/exit", {});
  }
}
