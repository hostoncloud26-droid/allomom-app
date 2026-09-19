import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/me/pregnancy` and its ANC, vaccination and report-checklist sub-resources.
class PregnancyApi {
  static Future<APIResponse> list() => ApiBase.get('/me/pregnancy');

  static Future<APIResponse> active() => ApiBase.get('/me/pregnancy/active');

  /// Creating a pregnancy seeds the whole calendar server-side — ANC visits,
  /// maternal vaccinations and the report checklist — all derived from the LMP.
  static Future<APIResponse> create(Map<String, dynamic> body) =>
      ApiBase.post('/me/pregnancy', body);

  static Future<APIResponse> get(String id) => ApiBase.get('/me/pregnancy/$id');

  /// Moving `lmp_date` re-derives the EDD and reschedules every visit, vaccine
  /// and test that has not been completed yet.
  static Future<APIResponse> patch(String id, Map<String, dynamic> changes) =>
      ApiBase.patch('/me/pregnancy/$id', changes);

  static Future<APIResponse> remove(String id) =>
      ApiBase.delete('/me/pregnancy/$id');

  // ── ANC ────────────────────────────────────────────────────────────────────

  static Future<APIResponse> listAnc(String pregnancyId) =>
      ApiBase.get('/me/pregnancy/$pregnancyId/anc');

  static Future<APIResponse> createAnc(
    String pregnancyId,
    Map<String, dynamic> body,
  ) => ApiBase.post('/me/pregnancy/$pregnancyId/anc', body);

  static Future<APIResponse> patchAnc(
    String pregnancyId,
    String ancId,
    Map<String, dynamic> changes,
  ) => ApiBase.patch('/me/pregnancy/$pregnancyId/anc/$ancId', changes);

  static Future<APIResponse> removeAnc(String pregnancyId, String ancId) =>
      ApiBase.delete('/me/pregnancy/$pregnancyId/anc/$ancId');

  // ── Vaccination ────────────────────────────────────────────────────────────

  static Future<APIResponse> listVaccination(String pregnancyId) =>
      ApiBase.get('/me/pregnancy/$pregnancyId/vaccination');

  static Future<APIResponse> createVaccination(
    String pregnancyId,
    Map<String, dynamic> body,
  ) => ApiBase.post('/me/pregnancy/$pregnancyId/vaccination', body);

  static Future<APIResponse> patchVaccination(
    String pregnancyId,
    String vaccinationId,
    Map<String, dynamic> changes,
  ) => ApiBase.patch(
    '/me/pregnancy/$pregnancyId/vaccination/$vaccinationId',
    changes,
  );

  static Future<APIResponse> removeVaccination(
    String pregnancyId,
    String vaccinationId,
  ) => ApiBase.delete('/me/pregnancy/$pregnancyId/vaccination/$vaccinationId');

  // ── Report checklist ───────────────────────────────────────────────────────

  static Future<APIResponse> listReportChecklist(String pregnancyId) =>
      ApiBase.get('/me/pregnancy/$pregnancyId/report-checklist');

  static Future<APIResponse> createReportChecklist(
    String pregnancyId,
    Map<String, dynamic> body,
  ) => ApiBase.post('/me/pregnancy/$pregnancyId/report-checklist', body);

  static Future<APIResponse> patchReportChecklist(
    String pregnancyId,
    String checklistId,
    Map<String, dynamic> changes,
  ) => ApiBase.patch(
    '/me/pregnancy/$pregnancyId/report-checklist/$checklistId',
    changes,
  );

  static Future<APIResponse> removeReportChecklist(
    String pregnancyId,
    String checklistId,
  ) => ApiBase.delete(
    '/me/pregnancy/$pregnancyId/report-checklist/$checklistId',
  );
}
