import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:allomom/config/colors.dart';
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
import 'package:allomom/repositories/user_session_manager.dart';

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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  Get.put(Apiroutes());
  await ApiBase.init();
  await SqLiteService.init();
  await UserSessionManager.instance.init();
  await ConnectionController.instance.init();
  HealthVitalSyncService.instance.init();

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

  runApp(const AllomomApp());
}

class AllomomApp extends StatelessWidget {
  const AllomomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserSessionManager.instance,
      builder: (context, _) {
        final isAuthenticated = UserSessionManager.instance.isAuthenticated;

        return GetMaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'Allomom',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: textDark),
              titleTextStyle: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            useMaterial3: true,
          ),
          home: isAuthenticated
              ? const MainLayout()
              : const LanguageSelectionPage(),
        );
      },
    );
  }
}
