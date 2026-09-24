import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/theme_controller.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/api_routes.dart';

import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/local_notification/services/local_reminder_scheduler.dart';
import 'package:allomom/features/prescriptions/prescription_reminder_page.dart';
import 'package:allomom/features/reminders/reminders_page.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/services/health_vital_sync_service.dart';
import 'package:allomom/controllers/auth_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/auth/role_selection_page.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/speech/allobot_speech_controller.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }
  // Loaded before the first frame so a dark-mode user never sees a white flash.
  await ThemeController.instance.load();

  Get.put(Apiroutes());
  // Secure storage first: the token it loads decides whether the bootstrap
  // below has a session to restore at all.
  await ApiBase.init();
  await SqLiteService.init();
  AuthController.instance.init();
  await MainController.instance.bootstrap();
  await ConnectionController.instance.init();
  HealthVitalSyncService.instance.init();

  // The baby's voice. Permanent so one player is shared by every screen —
  // navigating away from a card must not leave a second clip talking over the
  // next one.
  Get.put(BackgroundAudioController(), permanent: true);

  // Initialize Local Notifications & Health Reminder Scheduler
  try {
    LocalReminderScheduler.onNotificationAction = (data) {
      final screen = data['screen'];
      if (screen == 'prescription_reminder') {
        final timingId = data['timing_id']?.toString() ?? '';
        final medName = data['medicine_name']?.toString();
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => PrescriptionReminderPage(
              timingId: timingId,
              medicineName: medName,
            ),
          ),
        );
      } else if (screen == 'local_reminder') {
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const RemindersPage()),
        );
      }
    };

    await LocalReminderScheduler.init();
    LocalReminderScheduler.scheduleAllReminders();
  } catch (e) {
    debugPrint('Local notifications init notice: $e');
  }

  // AlloBot's two on-device pieces, started here rather than when the screen
  // is first opened: the intent catalogue refreshes itself and the Whisper
  // model loads — or downloads, once — so the microphone is ready the first
  // time it is tapped instead of after a wait she did not expect.
  //
  // Neither is awaited. A 75MB model download must never hold up the first
  // frame, and both work from what is already on the phone until they finish.
  AlloBotSpeechController.instance;
  OfflineChatbotController.instance;

  runApp(const AllomomApp());
}

class AllomomApp extends StatelessWidget {
  const AllomomApp({super.key});

  /// Where a launch lands.
  ///
  /// Three states, not two: no session goes to the language picker, a session
  /// whose registration was never finished resumes the registration flow rather
  /// than dropping her into a main screen with no profile behind it, and a
  /// complete account goes straight in.
  Widget _home() {
    final main = MainController.instance;
    if (!main.isAuthenticated) return const LanguageSelectionPage();
    if (!main.isRegistered) {
      return RoleSelectionPage(phone: main.userPhone);
    }
    return const MainLayout();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      init: MainController.instance,
      builder: (_) {
        return GetMaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'Allomom',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.resolvedThemeMode,
          // Status bar icons follow whichever theme is actually showing,
          // including when "System" hands the choice to the phone.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: ThemeController.overlayFor(Theme.of(context).brightness),
            child: child ?? const SizedBox.shrink(),
          ),
          home: _home(),
        );
      },
    );
  }
}
