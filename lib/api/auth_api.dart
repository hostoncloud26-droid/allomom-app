import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// The outcome of a successful OTP verification.
class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.loginId,
    required this.isRegistered,
    required this.isNewUser,
    this.name,
    this.phone,
    this.userName,
    this.joinedFamily,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String loginId;

  /// False until the registration flow completes. The app routes on this:
  /// false goes to the registration flow, true to the main screen.
  final bool isRegistered;

  /// True when this phone had no account and one was just created.
  final bool isNewUser;

  final String? name;
  final String? phone;
  final String? userName;

  /// Set when this sign-in claimed an account a partner had already created
  /// for this phone. The server marks such an account registered, so there is
  /// no registration flow to go through.
  final JoinedFamily? joinedFamily;

  static AuthResult? fromItem(dynamic item) {
    if (item is! Map) return null;
    final access = item['access_token'];
    final refresh = item['refresh_token'];
    if (access is! String || refresh is! String) return null;
    return AuthResult(
      accessToken: access,
      refreshToken: refresh,
      userId: item['user_id']?.toString() ?? '',
      loginId: item['login_id']?.toString() ?? '',
      isRegistered: item['is_registered'] == true,
      isNewUser: item['is_new_user'] == true,
      name: item['name'] as String?,
      phone: item['phone'] as String?,
      userName: item['user_name'] as String?,
      joinedFamily: JoinedFamily.fromItem(item['joined_family']),
    );
  }
}

/// The household a partner was added to before they ever signed in.
class JoinedFamily {
  const JoinedFamily({this.familyName, this.addedByName, this.addedByRelation});

  final String? familyName;
  final String? addedByName;

  /// What the person who added them is to them, e.g. "wife" / "husband".
  final String? addedByRelation;

  static JoinedFamily? fromItem(dynamic item) {
    if (item is! Map) return null;
    return JoinedFamily(
      familyName: item['family_name'] as String?,
      addedByName: item['added_by_name'] as String?,
      addedByRelation: item['added_by_relation'] as String?,
    );
  }

  /// "Your wife Priya has already added you to Priya's Family."
  String get welcomeMessage {
    final relation = (addedByRelation ?? '').trim();
    final name = (addedByName ?? '').trim();
    final who = [
      if (relation.isNotEmpty) 'Your $relation' else 'Your partner',
      if (name.isNotEmpty) name,
    ].join(' ');
    final family = (familyName ?? '').trim();
    return family.isEmpty
        ? '$who has already added you to the family.'
        : '$who has already added you to $family.';
  }
}

/// `/auth` — phone + OTP sign-in.
class AuthApi {
  /// Sends a one-time code to [phone]. Unauthenticated by definition.
  ///
  /// [channel] is `whatsapp` or `sms`; omitted, the server sends over both.
  static Future<APIResponse> sendOtp(
    String phone, {
    String countryCode = '+91',
    String? channel,
  }) {
    return ApiBase.post('/auth/send-otp', {
      'phone': phone,
      'country_code': countryCode,
      if (channel != null) 'channel': channel,
    }, withAuth: false);
  }

  static Future<APIResponse> resendOtp(
    String phone, {
    String countryCode = '+91',
    String? channel,
  }) {
    return ApiBase.post('/auth/resend-otp', {
      'phone': phone,
      'country_code': countryCode,
      if (channel != null) 'channel': channel,
    }, withAuth: false);
  }

  /// Verifies [otp] and signs in, creating the account if the phone is new.
  ///
  /// [deviceType] and [fcmToken] are recorded against the `user_logins` row the
  /// server creates, which is the session the returned tokens are bound to.
  static Future<APIResponse> verifyOtp({
    required String phone,
    required String otp,
    String countryCode = '+91',
    String? deviceType,
    String? fcmToken,
  }) {
    return ApiBase.post('/auth/verify-otp', {
      'phone': phone,
      'otp': otp,
      'country_code': countryCode,
      'device': {'device_type': deviceType, 'fcm_token': fcmToken},
    }, withAuth: false);
  }

  static Future<APIResponse> refresh(String refreshToken) {
    return ApiBase.post('/auth/refresh', {
      'refresh_token': refreshToken,
    }, withAuth: false);
  }

  static Future<APIResponse> logout({bool allDevices = false}) {
    return ApiBase.post('/auth/logout', {'all_devices': allDevices});
  }
}
