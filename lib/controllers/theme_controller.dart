import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the light / dark / system choice, following AlloConnect's
/// `ConfigController` theme handling.
///
/// The choice is stored as a plain string so it reads the same on every
/// platform, and is loaded before the first frame so the app never opens in
/// the wrong mode and then flips.
class ThemeController extends GetxController {
  static ThemeController get instance => Get.isRegistered<ThemeController>()
      ? Get.find<ThemeController>()
      : Get.put(ThemeController._(), permanent: true);

  ThemeController._();

  static const String _prefsKey = 'theme_mode';

  /// One of `system`, `light`, `dark`. Follows the phone until she picks one.
  final RxString themeMode = 'system'.obs;

  ThemeMode get resolvedThemeMode {
    switch (themeMode.value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  String get themeModeLabel {
    switch (themeMode.value) {
      case 'dark':
        return 'Dark';
      case 'light':
        return 'Light';
      default:
        return 'System';
    }
  }

  IconData get themeModeIcon {
    switch (themeMode.value) {
      case 'dark':
        return Icons.dark_mode_rounded;
      case 'light':
        return Icons.light_mode_rounded;
      default:
        return Icons.brightness_auto_rounded;
    }
  }

  String _normalize(String? value) {
    switch (value) {
      case 'dark':
      case 'light':
      case 'system':
        return value!;
      default:
        return 'system';
    }
  }

  /// Reads the saved choice. Call once before `runApp`.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      themeMode.value = _normalize(prefs.getString(_prefsKey));
    } catch (e) {
      debugPrint('Theme preference load failed: $e');
    }
  }

  Future<void> setThemeMode(String value) async {
    themeMode.value = _normalize(value);
    Get.changeThemeMode(resolvedThemeMode);
    update();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, themeMode.value);
    } catch (e) {
      debugPrint('Theme preference save failed: $e');
    }
  }

  void cycleThemeMode() {
    switch (themeMode.value) {
      case 'light':
        setThemeMode('dark');
        break;
      case 'dark':
        setThemeMode('system');
        break;
      default:
        setThemeMode('light');
        break;
    }
  }

  /// Status bar icons that stay readable on the current background.
  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    );
  }
}
