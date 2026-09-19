import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/sync` — the offline reconciliation endpoints.
///
/// These return the raw envelope rather than an [APIResponse]-shaped body, so
/// the callers read `item`/`items` off the decoded map directly.
class SyncApi {
  /// Push the rows changed locally for one module and pull what the server
  /// changed since [syncedAt]. The response's own `synced_at` is the watermark
  /// to store for next time.
  static Future<APIResponse> syncModule(
    String module, {
    DateTime? syncedAt,
    List<Map<String, dynamic>> changes = const [],
    List<String> deletedIds = const [],
  }) {
    return ApiBase.post('/sync/$module', {
      'synced_at': syncedAt?.toUtc().toIso8601String(),
      'changes': changes,
      'deleted_ids': deletedIds,
    });
  }

  /// Pull-only sweep of every module under one watermark, for app start and
  /// after reconnecting.
  static Future<APIResponse> syncAll({
    DateTime? syncedAt,
    List<String>? modules,
  }) {
    return ApiBase.post('/sync/all', {
      'synced_at': syncedAt?.toUtc().toIso8601String(),
      if (modules != null) 'modules': modules,
    });
  }

  static Future<APIResponse> modules() => ApiBase.get('/sync/modules');
}
