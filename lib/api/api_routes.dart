import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class Apiroutes extends GetxController {
  static Apiroutes get instance =>
      Get.isRegistered<Apiroutes>()
          ? Get.find<Apiroutes>()
          : Get.put(Apiroutes(), permanent: true);

  // String baseUrl = "http://10.0.2.2:8000";

  // String baseUrl = "http://192.168.0.141:8000";

  String baseUrl = "https://api.allomom.savemom.app";

  @override
  void onInit() {
    super.onInit();

    if (kReleaseMode) {
      baseUrl = "https://api.allomom.savemom.app";
      update();
    }
  }

  static bool checkUser() {
    return UserSessionManager.instance.isAuthenticated;
  }

  int version = 1;

  void setBaseUrl(String url) {
    baseUrl = url;
    update();
  }
}

typedef ApiRoutes = Apiroutes;
