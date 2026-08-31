import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await ApiBase.init();
  await SqLiteService.init();
  await UserSessionManager.instance.init();
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

        return MaterialApp(
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
          home: isAuthenticated ? const MainLayout() : const LanguageSelectionPage(),
        );
      },
    );
  }
}
