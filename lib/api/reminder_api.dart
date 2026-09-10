import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

class ReminderApi {
  static Future<APIResponse> getReminders(String userId) async {
    return await ApiBase.newGetRequest('/reminder/get/$userId');
  }

  static Future<APIResponse> updateReminder(String reminderId, dynamic data) async {
    return await ApiBase.newPutRequest('/reminder/update/$reminderId', data);
  }

  static Future<APIResponse> createReminder(dynamic data) async {
    return await ApiBase.newPostRequest('/reminder/create', data);
  }

  static Future<APIResponse> deleteReminder(String reminderId) async {
    return await ApiBase.newDeleteRequest('/reminder/delete/$reminderId');
  }
}
