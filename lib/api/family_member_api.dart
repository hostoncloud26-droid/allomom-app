import 'dart:typed_data';

import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/family/members/{userId}` — another family member's health, as seen by
/// the signed-in user (a father opening his partner, say).
///
/// Straight to the API, never the local database: the device only ever holds
/// its own user's record. The server checks both people share a family.
class FamilyMemberApi {
  static String _base(String userId) => '/family/members/$userId';

  /// Her health record, vitals, pregnancies (with ANC, vaccinations and the
  /// report checklist) and babies (with vaccinations and milestones) — the
  /// same bundle as `/me/profile/get_all`.
  static Future<APIResponse> getProfile(String userId) =>
      ApiBase.get('${_base(userId)}/profile');

  static Future<APIResponse> getVitals(
    String userId, {
    String? key,
    int limit = 500,
  }) => ApiBase.get(
    '${_base(userId)}/vitals',
    query: {'limit': limit, 'key': ?key},
  );

  /// Logs readings on her record. The one write this view allows.
  static Future<APIResponse> addVitals(
    String userId,
    List<Map<String, dynamic>> readings,
  ) => ApiBase.post('${_base(userId)}/vitals', readings);

  static Future<APIResponse> getReports(
    String userId, {
    int skip = 0,
    int limit = 50,
  }) => ApiBase.get(
    '${_base(userId)}/reports',
    query: {'skip': skip, 'limit': limit},
  );

  /// One of her report files, relayed from her Google Drive.
  static Future<Uint8List?> downloadAttachment(
    String userId,
    String attachmentId,
  ) => ApiBase.getBytes(
    '${_base(userId)}/reports/attachments/$attachmentId/content',
  );
}
