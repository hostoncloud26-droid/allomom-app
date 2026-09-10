import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

class ReportApi {
  static Future<APIResponse> getReportData(String id) async {
    return await ApiBase.newGetRequest('/report/$id');
  }

  static Future<APIResponse> addReport(dynamic data) async {
    return await ApiBase.newPostRequest('/me/reports', data);
  }

  static Future<APIResponse> getReports({int skip = 0, int limit = 10}) async {
    return await ApiBase.newGetRequest('/me/reports?skip=$skip&limit=$limit');
  }

  static Future<bool> deleteReport(String id) async {
    final d = await ApiBase.newDeleteRequest('/report/$id');
    return d.success;
  }

  static Future<APIResponse> updateReport(dynamic data) async {
    return await ApiBase.newPutRequest('/report/', data);
  }

  static Future<APIResponse> getReportsSummary() async {
    return await ApiBase.newGetRequest('/me/reports/summary');
  }
}
