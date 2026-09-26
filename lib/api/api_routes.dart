import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:allomom/controllers/main_controller.dart';

class Apiroutes extends GetxController {
  static Apiroutes get instance => Get.isRegistered<Apiroutes>()
      ? Get.find<Apiroutes>()
      : Get.put(Apiroutes(), permanent: true);

  // Physical device over USB debugging: run `adb reverse tcp:8000 tcp:8000`
  // once per USB reconnect, tunneling this port straight to the backend
  // running on your machine.
  //String baseUrl = "http://127.0.0.1:8000";

  // Emulator (10.0.2.2 is the special alias for the host machine's localhost
  // — only resolves inside the emulator, never on a real device):
  // String baseUrl = "http://10.0.2.2:8000";

  // String baseUrl = "http://192.168.0.18:8000";

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
    return MainController.instance.isAuthenticated;
  }

  int version = 1;

  void setBaseUrl(String url) {
    baseUrl = url;
    update();
  }
}

typedef ApiRoutes = Apiroutes;
