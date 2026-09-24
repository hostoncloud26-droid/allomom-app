import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// Short-lived tokens that let someone else open one of her records — the
/// health profile QR — without signing in as her. Same contract as
/// AlloConnect's `/stokens/create`.
class SecureTokenApi {
  static const String _prefix = '/stokens';

  /// Creates a token of [type] (e.g. `health-profile`) that expires after
  /// [expiryInSeconds].
  static Future<APIResponse> create({
    required String type,
    int expiryInSeconds = 15 * 60,
  }) {
    var expiresAt = DateTime.now()
        .add(Duration(seconds: expiryInSeconds))
        .toUtc()
        .toIso8601String();
    if (expiresAt.endsWith('Z')) {
      expiresAt = expiresAt.substring(0, expiresAt.length - 1);
    }
    return ApiBase.post('$_prefix/create', {
      'type': type,
      'expires_at': expiresAt,
    });
  }
}
