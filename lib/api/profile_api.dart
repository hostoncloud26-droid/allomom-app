import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/me/profile` — the signed-in user's own record.
class ProfileApi {
  static Future<APIResponse> get() => ApiBase.get('/me/profile');

  /// Partial update. Only the keys present in [changes] are touched server-side.
  static Future<APIResponse> patch(Map<String, dynamic> changes) =>
      ApiBase.patch('/me/profile', changes);

  /// The whole account in one call: user, health record, pregnancies with their
  /// schedules, babies with theirs, and the vitals stream. Used to seed the
  /// local database after sign-in, and its `server_time` becomes the first
  /// sync watermark.
  static Future<APIResponse> getAll() => ApiBase.get('/me/profile/get_all');

  /// Deletes the caller's account for good: personal details scrubbed, every
  /// session revoked, family left, pregnancies and babies removed. The token
  /// that made the call stops working once it returns.
  static Future<APIResponse> deleteAccount() => ApiBase.delete('/me/account');
}
