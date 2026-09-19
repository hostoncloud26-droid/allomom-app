import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/me/baby` and its vaccination and milestone sub-resources.
class BabyApi {
  static Future<APIResponse> list() => ApiBase.get('/me/baby');

  /// Adding a baby seeds its immunization schedule and milestone checklist
  /// server-side from the delivery date. `pregnancy_id` may be omitted — the
  /// server resolves it, which is what lets the registration flow add previous
  /// children before any pregnancy record exists.
  static Future<APIResponse> create(Map<String, dynamic> body) =>
      ApiBase.post('/me/baby', body);

  static Future<APIResponse> get(String id) => ApiBase.get('/me/baby/$id');

  static Future<APIResponse> patch(String id, Map<String, dynamic> changes) =>
      ApiBase.patch('/me/baby/$id', changes);

  static Future<APIResponse> remove(String id) =>
      ApiBase.delete('/me/baby/$id');

  // ── Vaccination ────────────────────────────────────────────────────────────

  static Future<APIResponse> listVaccination(String babyId) =>
      ApiBase.get('/me/baby/$babyId/vaccination');

  static Future<APIResponse> createVaccination(
    String babyId,
    Map<String, dynamic> body,
  ) => ApiBase.post('/me/baby/$babyId/vaccination', body);

  static Future<APIResponse> patchVaccination(
    String babyId,
    String vaccinationId,
    Map<String, dynamic> changes,
  ) => ApiBase.patch('/me/baby/$babyId/vaccination/$vaccinationId', changes);

  static Future<APIResponse> removeVaccination(
    String babyId,
    String vaccinationId,
  ) => ApiBase.delete('/me/baby/$babyId/vaccination/$vaccinationId');

  // ── Milestones ─────────────────────────────────────────────────────────────

  static Future<APIResponse> listMilestones(String babyId) =>
      ApiBase.get('/me/baby/$babyId/milestones');

  static Future<APIResponse> createMilestone(
    String babyId,
    Map<String, dynamic> body,
  ) => ApiBase.post('/me/baby/$babyId/milestones', body);

  static Future<APIResponse> patchMilestone(
    String babyId,
    int milestoneId,
    Map<String, dynamic> changes,
  ) => ApiBase.patch('/me/baby/$babyId/milestones/$milestoneId', changes);

  static Future<APIResponse> removeMilestone(String babyId, int milestoneId) =>
      ApiBase.delete('/me/baby/$babyId/milestones/$milestoneId');
}
