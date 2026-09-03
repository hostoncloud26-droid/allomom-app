import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/services/api/response.dart';

class VitalsApi {
  static Future<APIResponse> addVital(
    String key,
    double value,
    String unit,
    DateTime createdAt, {
    String? userId,
    Map<String, dynamic>? data,
    String? id,
  }) async {
    return await ApiBase.newPostRequest("/allowear/add-vital", {
      if (id != null) "id": id,
      "key": key,
      "value": value,
      "unit": unit,
      "createdAt": createdAt.toIso8601String(),
      if (userId != null) "user_id": userId,
      if (data != null) "data": data,
    });
  }

  static Future<APIResponse> addVitalDailyData(
    String key,
    double value,
    String unit,
    DateTime createdAt,
    Map<String, dynamic>? additionalData,
    String? userId,
  ) async {
    return await ApiBase.newPostRequest("/allowear/add-vitals-daily-data", {
      "key": key,
      "value": value,
      "unit": unit,
      "data": additionalData ?? {},
      "createdAt": createdAt.toIso8601String(),
      if (userId != null) "user_id": userId,
    });
  }

  static Future<APIResponse> addVitalStream(
    String key,
    double value,
    String unit,
    DateTime createdAt, {
    Map<String, dynamic>? data,
  }) async {
    return await ApiBase.newPostRequest("/vital-stream", {
      "key": key,
      "value": value,
      "unit": unit,
      "timestamp": createdAt.toIso8601String(),
      if (data != null) "data": data,
    });
  }

  static Future<APIResponse> getLatestVitals(String userId) async {
    return await ApiBase.newGetRequest("/allowear/vitals/$userId");
  }

  static Future<APIResponse> getVitalsHistory(
    String userId,
    String type, {
    DateTime? fromDate,
    DateTime? toDate,
    double? valueFrom,
    double? valueTo,
  }) async {
    String endpoint = "/allowear/vitals-history/$userId?type=$type";

    if (fromDate != null) {
      endpoint += "&from_date=${fromDate.toIso8601String()}";
    }
    if (toDate != null) {
      endpoint += "&to_date=${toDate.toIso8601String()}";
    }
    if (valueFrom != null) {
      endpoint += "&value_from=$valueFrom";
    }
    if (valueTo != null) {
      endpoint += "&value_to=$valueTo";
    }

    return await ApiBase.newGetRequest(endpoint);
  }

  static Future<APIResponse> getUserVitalsHistory(
    String userId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    String endpoint = "/allowear/vitals-history/$userId";

    if (fromDate != null) {
      endpoint += "?from_date=${fromDate.toIso8601String()}";
    }

    if (toDate != null) {
      if (fromDate != null) {
        endpoint += "&to_date=${toDate.toIso8601String()}";
      } else {
        endpoint += "?to_date=${toDate.toIso8601String()}";
      }
    }

    return await ApiBase.newGetRequest(endpoint);
  }

  static Future<APIResponse> updateVital(
    String vitalId,
    String key,
    double value,
    String unit,
    DateTime createdAt, {
    Map<String, dynamic>? data,
  }) async {
    return await ApiBase.newPutRequest("/allowear/vitals/$vitalId", {
      "key": key,
      "value": value,
      "unit": unit,
      "createdAt": createdAt.toIso8601String(),
      if (data != null) "data": data,
    });
  }

  static Future<APIResponse> addVitalsBulk(
    String bluetoothMac,
    List<Map<String, dynamic>> vitals,
  ) async {
    return await ApiBase.newPostRequest("/allowear/add-vitals-bulk", {
      "bluetooth_mac": bluetoothMac,
      "vitals": vitals,
    });
  }

  static Future<APIResponse> syncDataBulk(
    String bluetoothMac,
    List<Map<String, dynamic>> vitals,
  ) async {
    return await ApiBase.newPostRequest("/allowear/sync-data-bulk", {
      "bluetooth_mac": bluetoothMac,
      "vitals": vitals,
    });
  }
}
