import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/me/content` — the Feeds tab: active system content plus content from
/// the communities she belongs to, newest first — and her likes and
/// comments on it.
class ContentApi {
  static Future<APIResponse> getMyContent({
    int page = 1,
    int size = 10,
    String? viewType,
    String? entityId,
  }) async {
    return await ApiBase.get(
      "/me/content",
      query: {
        "page": "$page",
        "size": "$size",
        if (viewType != null) "view_type": viewType,
        if (entityId != null) "entity_id": entityId,
      },
    );
  }

  /// Idempotent. The response `item` carries `is_liked` and `like_count`.
  static Future<APIResponse> like(int contentId) async {
    return await ApiBase.post("/me/content/$contentId/like", {});
  }

  static Future<APIResponse> unlike(int contentId) async {
    return await ApiBase.delete("/me/content/$contentId/like");
  }

  /// Newest first.
  static Future<APIResponse> getComments(
    int contentId, {
    int page = 1,
    int size = 20,
  }) async {
    return await ApiBase.get(
      "/me/content/$contentId/comments",
      query: {"page": "$page", "size": "$size"},
    );
  }

  /// `itemCount` in the response is the item's new comment total.
  static Future<APIResponse> addComment(int contentId, String comment) async {
    return await ApiBase.post(
      "/me/content/$contentId/comments",
      {"comment": comment},
    );
  }

  /// Her own comments only. `itemCount` is the new comment total.
  static Future<APIResponse> deleteComment(int contentId, int commentId) async {
    return await ApiBase.delete("/me/content/$contentId/comments/$commentId");
  }
}
