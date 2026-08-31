import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/services/api/response.dart';

class OtpApi {
  static Future<APIResponse> sendOtp(String phone, [String countryCode = "+91"]) async {
    return await ApiBase.newPostRequest("/otp/generate-otp", {
      "phone": phone,
      "country_code": countryCode,
    });
  }

  static Future<APIResponse> verifyOtp(
    String otpCode,
    dynamic otpId, [
    String appType = "com.savemom.allomom",
  ]) async {
    return await ApiBase.newPostRequest("/otp/verify-otp", {
      "otp_id": otpId,
      "otp_code": otpCode,
      "type": appType,
    });
  }

  static Future<APIResponse> verifyAndOnboard({
    required String phone,
    String countryCode = "+91",
    required String otpCode,
  }) async {
    return await ApiBase.newPostRequest("/otp/verify", {
      "phone": phone,
      "country_code": countryCode,
      "otp_code": otpCode,
    });
  }
}
