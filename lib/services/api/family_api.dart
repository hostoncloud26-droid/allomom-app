import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/services/api/response.dart';

class FamilyApi {
  static Future<APIResponse> getMyFamily() async {
    return await ApiBase.newGetRequest("/family/my");
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
