import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

class PrescriptionApi {
  static Future<APIResponse> getPrescriptions({int skip = 0, int limit = 20}) async {
    return await ApiBase.newGetRequest('/me/prescription?skip=$skip&limit=$limit');
  }

  static Future<APIResponse> addPrescription(dynamic data) async {
    return await ApiBase.newPostRequest('/me/prescription', data);
  }

  static Future<APIResponse> addPrescriptionOneShot(dynamic data) async {
    return await ApiBase.newPostRequest('/prescriptions/one-shot/create', data);
  }

  static Future<APIResponse> updatePrescription(dynamic data) async {
    return await ApiBase.newPutRequest('/me/prescription', data);
  }

  static Future<bool> deletePrescription(String id) async {
    final res = await ApiBase.newDeleteRequest('/me/prescription/$id');
    return res.success;
  }

  static Future<APIResponse> getPrescriptionById(String prescriptionId) async {
    return await ApiBase.newGetRequest('/prescriptions/$prescriptionId');
  }

  static Future<APIResponse> updatePrescriptionById(
    String prescriptionId,
    Map<String, dynamic> data,
  ) async {
    return await ApiBase.newPatchRequest('/prescriptions/$prescriptionId', data);
  }

  static Future<APIResponse> deletePrescriptionById(String prescriptionId) async {
    return await ApiBase.newDeleteRequest('/prescriptions/$prescriptionId');
  }

  static Future<APIResponse> addMedication(Map<String, dynamic> data) async {
    return await ApiBase.newPostRequest('/prescriptions/medications', data);
  }

  static Future<APIResponse> updateMedicationById(
    String medicineId,
    Map<String, dynamic> data,
  ) async {
    return await ApiBase.newPatchRequest('/prescriptions/medications/$medicineId', data);
  }

  static Future<APIResponse> deleteMedicationById(String medicineId) async {
    return await ApiBase.newDeleteRequest('/prescriptions/medications/$medicineId');
  }

  static Future<APIResponse> addMedicationTiming(
    String medicineId,
    Map<String, dynamic> data,
  ) async {
    return await ApiBase.newPostRequest('/prescriptions/medications/$medicineId/timings', data);
  }

  static Future<APIResponse> getUserTimings(
    DateTime from,
    DateTime to, [
    String? userId,
  ]) async {
    String url = '/prescriptions/my?from_date=${from.toIso8601String()}&to_date=${to.toIso8601String()}';
    if (userId != null && userId.isNotEmpty) {
      url += '&user_id=$userId';
    }
    return await ApiBase.newGetRequest(url);
  }

  static Future<APIResponse> updateMedicationTiming(
    String medicineId,
    String timingId,
    Map<String, dynamic> data,
  ) async {
    return await ApiBase.newPatchRequest(
      '/prescriptions/medications/$medicineId/timings/$timingId',
      data,
    );
  }

  static Future<APIResponse> deleteMedicationTiming(
    String medicineId,
    String timingId,
  ) async {
    return await ApiBase.newDeleteRequest(
      '/prescriptions/medications/$medicineId/timings/$timingId',
    );
  }

  static Future<APIResponse> getMedicationTimingDetails(String timingId) async {
    return await ApiBase.newGetRequest('/prescription/timing/$timingId');
  }

  static Future<APIResponse> markMedicationTimingTaken(String timingId) async {
    return await ApiBase.newPostRequest('/prescription/timing/$timingId/taken', {});
  }

  static Future<APIResponse> snoozeMedicationTiming(String timingId, int minutes) async {
    return await ApiBase.newPostRequest('/prescription/timing/$timingId/snooze?snooze_minutes=$minutes', {});
  }
}
