import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/services/api/response.dart';

class PregnancyApi {
  /// Fetches pregnancy calculation & active status for the logged-in user under /user/me/pregnancy
  static Future<APIResponse> getMyPregnancy() async {
    return await ApiBase.newGetRequest("/user/me/pregnancy");
  }

  /// Fetches calculated pregnancy info (gestational age, trimester, EDD, risk status)
  static Future<APIResponse> getPregnancyInfo() async {
    return await ApiBase.newGetRequest("/user/me/pregnancy");
  }

  /// Fetches active pregnancy record
  static Future<APIResponse> getActivePregnancy() async {
    return await ApiBase.newGetRequest("/pregnancy/active");
  }

  /// Fetches all pregnancy history records for the current user
  static Future<APIResponse> getPregnancyRecords() async {
    return await ApiBase.newGetRequest("/pregnancy/records");
  }

  /// Fetches pregnancy summary (active and total pregnancy counts)
  static Future<APIResponse> getPregnancySummary() async {
    return await ApiBase.newGetRequest("/pregnancy/summary");
  }

  /// Creates a new pregnancy record (or updates active pregnancy)
  static Future<APIResponse> createPregnancy(Map<String, dynamic> data) async {
    return await ApiBase.newPostRequest("/pregnancy", data);
  }

  /// Updates an existing pregnancy record by ID
  static Future<APIResponse> updatePregnancy(String pregnancyId, Map<String, dynamic> data) async {
    return await ApiBase.newPutRequest("/pregnancy/$pregnancyId", data);
  }

  /// Deletes a pregnancy record by ID
  static Future<APIResponse> deletePregnancy(String pregnancyId) async {
    return await ApiBase.newDeleteRequest("/pregnancy/$pregnancyId");
  }

  /// Retrieves a single pregnancy record by ID
  static Future<APIResponse> getPregnancyById(String pregnancyId) async {
    return await ApiBase.newGetRequest("/pregnancy/$pregnancyId");
  }
}
