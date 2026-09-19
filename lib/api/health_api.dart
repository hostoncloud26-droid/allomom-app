import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/me/healthdata` and its vitals stream.
class HealthApi {
  static Future<APIResponse> get() => ApiBase.get('/me/healthdata');

  static Future<APIResponse> patch(Map<String, dynamic> changes) =>
      ApiBase.patch('/me/healthdata', changes);

  static Future<APIResponse> listVitals({String? key, int limit = 500}) =>
      ApiBase.get(
        '/me/healthdata/vitals',
        query: {if (key != null) 'key': key, 'limit': limit},
      );

  /// Writes a batch — the app flushes its whole offline queue in one request.
  static Future<APIResponse> addVitals(List<Map<String, dynamic>> readings) =>
      ApiBase.post('/me/healthdata/vitals', readings);
}
