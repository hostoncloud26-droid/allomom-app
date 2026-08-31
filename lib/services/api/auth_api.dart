import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/services/api/response.dart';

class AuthApi {
  static Future<APIResponse> login(String phoneOrEmail, [String? password]) async {
    return await ApiBase.newPostRequest("/auth/login", {
      "phone_or_email": phoneOrEmail,
      "password": password,
    });
  }

  static Future<APIResponse> loginPhone(String phone, String password) async {
    return await ApiBase.newPostRequest("/auth/login/phone", {
      "phone": phone,
      "password": password,
    });
  }

  static Future<APIResponse> registerMother(Map<String, dynamic> data) async {
    return await ApiBase.newPostRequest("/register/user", data);
  }

  static Future<APIResponse> getMe() async {
    return await ApiBase.newGetRequest("/me");
  }

  static Future<APIResponse> refreshToken() async {
    final refresh = await ApiBase.getRefreshToken();
    return await ApiBase.newPostRequest("/auth/refresh", {
      "refresh": refresh,
    });
  }

  static Future<APIResponse> logout([String? fcmToken]) async {
    final res = await ApiBase.newPostRequest("/auth/logout", {
      "fcm_token": fcmToken,
    });
    await ApiBase.clearTokens();
    return res;
  }

  static Future<APIResponse> authGoogle(String idToken) async {
    return await ApiBase.newPostRequest("/auth/google", {
      "id_token": idToken,
      "app_id": "com.savemom.allomom",
    });
  }

  static Future<APIResponse> updateProfile(Map<String, dynamic> data) async {
    return await ApiBase.newPutRequest("/user/profile", data);
  }

  static Future<APIResponse> resetPassword(String oldPassword, String newPassword) async {
    return await ApiBase.newPostRequest("/user/reset-password", {
      "old_password": oldPassword,
      "new_password": newPassword,
    });
  }
}
