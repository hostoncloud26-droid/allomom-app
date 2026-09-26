import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/me/hospital` — hospitals the mother added herself from Google Maps
/// (user_entity of type "hospital").
class HospitalApi {
  /// Current hospitals first, then the ones she has left.
  static Future<APIResponse> getMyHospitals() async {
    return await ApiBase.get("/me/hospital");
  }

  /// Searches hospitals on Google Maps via the backend.
  static Future<APIResponse> searchHospitals(String query) async {
    return await ApiBase.get(
      "/me/hospital/search",
      query: {"q": query.trim()},
    );
  }

  /// Links the caller to a Google Maps [place] (the raw search result).
  static Future<APIResponse> addHospital(Map<String, dynamic> place) async {
    return await ApiBase.post("/me/hospital", {"place": place});
  }

  static Future<APIResponse> removeHospital(int userEntityId) async {
    return await ApiBase.delete("/me/hospital/$userEntityId");
  }
}
