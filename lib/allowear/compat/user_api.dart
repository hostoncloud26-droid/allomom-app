import 'package:allomom/api/response.dart';
import 'package:allomom/controllers/main_controller.dart';

/// AlloConnect's `Userapi`, for the calls its AlloWear module makes, so that
/// module runs here unchanged.
///
/// Allomom's server has no `/me/allowear/connect` or `/disconnect` route, so
/// the band's link stays on this phone (the MAC is kept on the session, and
/// each synced reading carries it).
class Userapi {
  Userapi._();

  static String? getUserID() {
    final id = MainController.instance.userId;
    return id.isEmpty ? null : id;
  }

  static Future<APIResponse> connectAllowear(String macAddress) async {
    await MainController.instance.setAllowearMacAddress(macAddress);
    return APIResponse(success: true, map: const {});
  }

  static Future<APIResponse> disconnectAllowear() async {
    await MainController.instance.setAllowearMacAddress(null);
    return APIResponse(success: true, map: const {});
  }
}
