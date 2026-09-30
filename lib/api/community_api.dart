import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/communities` and `/me/communities` — communities (entities of type
/// "community") the mother can join as a follower.
class CommunityApi {
  /// The 5 most recently created communities.
  static Future<APIResponse> getFeatured() async {
    return await ApiBase.get("/communities/featured");
  }

  /// All communities, newest first; [query] narrows by name.
  static Future<APIResponse> search({
    String? query,
    int page = 1,
    int size = 20,
  }) async {
    return await ApiBase.get(
      "/communities/search",
      query: {
        if (query != null && query.trim().isNotEmpty) "q": query.trim(),
        "page": "$page",
        "size": "$size",
      },
    );
  }

  static Future<APIResponse> getCommunity(String entityId) async {
    return await ApiBase.get("/communities/$entityId");
  }

  /// Communities she currently belongs to, most recently joined first.
  static Future<APIResponse> getMyCommunities() async {
    return await ApiBase.get("/me/communities");
  }

  static Future<APIResponse> join(String entityId) async {
    return await ApiBase.post("/me/communities/$entityId/join", {});
  }

  /// Keeps her membership record and stamps when she left.
  static Future<APIResponse> leave(String entityId) async {
    return await ApiBase.post("/me/communities/$entityId/leave", {});
  }
}
