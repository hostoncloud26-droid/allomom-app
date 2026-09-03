import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allomom/local_notification/models/local_reminder.dart';

class LocalReminderStorage {
  static const String _storageKeyPrefix = 'local_reminder_';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Initialize and load SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save a single reminder configuration
  static Future<void> save(LocalReminderConfig config) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      '$_storageKeyPrefix${config.type.key}',
      jsonEncode(config.toJson()),
    );
  }

  /// Load a single reminder configuration
  static LocalReminderConfig load(LocalReminderType type) {
    if (_prefs == null) {
      return LocalReminderConfig(type: type);
    }
    final raw = _prefs!.getString('$_storageKeyPrefix${type.key}');
    if (raw == null) {
      return LocalReminderConfig(type: type);
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LocalReminderConfig.fromJson(json);
    } catch (_) {
      return LocalReminderConfig(type: type);
    }
  }

  /// Load all reminder configurations
  static List<LocalReminderConfig> loadAll() {
    return LocalReminderType.values.map((type) => load(type)).toList();
  }

  /// Check if a reminder type is enabled
  static bool isEnabled(LocalReminderType type) {
    return load(type).enabled;
  }
}
