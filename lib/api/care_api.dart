import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

class CareApi {
  /// Fetches today's scheduled care tasks with completion summary for the logged-in user
  static Future<APIResponse> getTodayCareTasks({int? pregnancyDay}) async {
    final params = <String, dynamic>{};
    if (pregnancyDay != null) {
      params['pregnancy_day'] = pregnancyDay;
    }
    return await ApiBase.newGetRequest(
      "/care/user-tasks/today",
      params.isNotEmpty ? params : null,
    );
  }

  /// Lists user care tasks with optional query filters (status, date, week, day)
  static Future<APIResponse> getUserCareTasks({
    String? status,
    String? scheduledDate,
    String? fromDate,
    String? toDate,
    int? week,
    int? day,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (scheduledDate != null) params['scheduled_date'] = scheduledDate;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (week != null) params['week'] = week;
    if (day != null) params['day'] = day;

    return await ApiBase.newGetRequest("/care/user-tasks", params.isEmpty ? null : params);
  }

  /// Toggles or sets task completion status with timestamp
  static Future<APIResponse> markCareTaskCompleted(
    String taskId,
    bool isCompleted, {
    DateTime? completedAt,
  }) async {
    final timestamp = isCompleted
        ? (completedAt ?? DateTime.now()).toUtc().toIso8601String()
        : null;

    return await ApiBase.newPatchRequest(
      "/care/user-tasks/$taskId/complete",
      {
        "mark_as_completed": isCompleted,
        "completed_at": timestamp,
      },
    );
  }

  /// Updates a user care task
  static Future<APIResponse> updateCareTask(String taskId, Map<String, dynamic> data) async {
    return await ApiBase.newPutRequest("/care/user-tasks/$taskId", data);
  }

  /// Deletes a user care task
  static Future<APIResponse> deleteCareTask(String taskId) async {
    return await ApiBase.newDeleteRequest("/care/user-tasks/$taskId");
  }
}
