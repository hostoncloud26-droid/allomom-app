import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages screen voice introduction vs subsequent hint flows.
///
/// Rules:
/// - If a screen has a defined hint key (from the Google Sheet specification):
///   - On first visit to that screen, the introductory audio flow (`screen_<name>_info`) plays.
///   - On all subsequent visits, the concise hint flow (`screen_<name>_hint`) plays instead.
///   - The visit history is persisted locally via [SharedPreferences] with fast in-memory caching.
/// - If a screen DOES NOT have a hint key:
///   - No local storage handling is applied; the intro key plays normally without switching.
class ScreenVoiceHintService {
  static const String _storagePrefix = 'screen_voice_intro_played_';

  /// Persistent set of intro keys that have ever been played across app launches.
  static final Set<String> _inMemoryPlayed = <String>{};

  /// In-memory set of keys that have already played in the current app session.
  /// Cleared automatically whenever the app process restarts.
  static final Set<String> _sessionPlayedKeys = <String>{};

  static bool _initialized = false;

  /// Official mapping of introductory keys to their corresponding hint keys
  /// (as defined in the Google Sheet / NarrationKeys).
  static const Map<String, String> registeredHints = {
    'screen_allocry_info': 'screen_allocry_hint',
    'screen_baby_milestones_info': 'screen_baby_milestones_hint',
    'screen_baby_vaccines_info': 'screen_baby_vaccines_hint',
    'screen_baby_profile_info': 'screen_baby_profile_hint',
    'screen_daily_activity_info': 'screen_daily_activity_hint',
    'screen_ask_allo_info': 'screen_ask_allo_hint',
    'screen_agents_info': 'screen_agents_hint',
    'screen_allobot_chat_info': 'screen_allobot_chat_hint',
    'screen_allobot_settings_info': 'screen_allobot_settings_hint',
    'screen_feeding_tracker_info': 'screen_feeding_tracker_hint',
    'screen_feeds_info': 'screen_feeds_hint',
    'screen_home_care_info': 'screen_home_care_hint',
    'screen_home_nutrition_info': 'screen_home_nutrition_hint',
    'screen_home_vitals_info': 'screen_home_vitals_hint',
    'screen_kick_counter_info': 'screen_kick_counter_hint',
    'screen_my_cycle_phase_info': 'screen_my_cycle_phase_hint',
    'screen_my_cycle_tracker_info': 'screen_my_cycle_tracker_hint',
    'screen_my_health_info': 'screen_my_health_hint',
    'screen_my_prescriptions_info': 'screen_my_prescriptions_hint',
    'screen_my_profile_info': 'screen_my_profile_hint',
    'screen_my_reports_info': 'screen_my_reports_hint',
    'screen_my_vitals_info': 'screen_my_vitals_hint',
    'screen_people_community_info': 'screen_people_community_hint',
    'screen_people_family_info': 'screen_people_family_hint',
    'screen_pregnancy_journey_info': 'screen_pregnancy_journey_hint',
    'screen_register_pregnancy_info': 'screen_register_pregnancy_hint',
    'screen_settings_info': 'screen_settings_hint',
  };

  /// Preloads visited keys into memory for zero latency.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_storagePrefix) && prefs.getBool(key) == true) {
          _inMemoryPlayed.add(key.substring(_storagePrefix.length));
        }
      }
      _initialized = true;
    } catch (_) {
      // Fallback gracefully to in-memory set if SharedPreferences encounters an issue
    }
  }

  /// Whether an audio key has already been played in the current app session.
  static bool hasPlayedInSession(String key) {
    return _sessionPlayedKeys.contains(key);
  }

  /// Marks an audio key as played in the current app session.
  static void markPlayedInSession(String key) {
    _sessionPlayedKeys.add(key);
  }

  /// Clears in-memory session tracking (e.g. on manual logout or testing).
  static void clearSession() {
    _sessionPlayedKeys.clear();
  }

  /// Returns the hint key for a given [introKey] if one exists, otherwise null.
  static String? getHintKeyFor(String introKey, [String? explicitHintKey]) {
    if (explicitHintKey != null && explicitHintKey.isNotEmpty) {
      return explicitHintKey;
    }
    return registeredHints[introKey];
  }

  /// Whether a screen/intent has a hint key defined.
  static bool hasHintKey(String introKey, [String? explicitHintKey]) {
    return getHintKeyFor(introKey, explicitHintKey) != null;
  }

  /// Resolves which intent key to play:
  /// - If NO hint key exists: returns [introKey] directly without any local handling.
  /// - If a hint key exists:
  ///   - First visit ever: returns [introKey] and records in persistent storage that intro played.
  ///   - Subsequent visits (across app runs): returns the corresponding hint key.
  /// If [markSession] is true (default), also marks [introKey] as played in this session.
  static Future<String> resolveIntentKey({
    required String introKey,
    String? hintKey,
    bool markSession = true,
  }) async {
    if (markSession) {
      markPlayedInSession(introKey);
    }

    final resolvedHintKey = getHintKeyFor(introKey, hintKey);

    // If this screen has no hint key, return introKey directly
    if (resolvedHintKey == null) {
      return introKey;
    }

    if (!_initialized) {
      await init();
    }

    if (_inMemoryPlayed.contains(introKey)) {
      return resolvedHintKey;
    }

    // First time visit ever for a screen with a hint key
    _inMemoryPlayed.add(introKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_storagePrefix$introKey', true);
    } catch (_) {}

    return introKey;
  }

  /// Synchronous resolution using in-memory cache.
  static String resolveKeySync({
    required String introKey,
    String? hintKey,
    bool markSession = true,
  }) {
    if (markSession) {
      markPlayedInSession(introKey);
    }

    final resolvedHintKey = getHintKeyFor(introKey, hintKey);

    // If this screen has no hint key, return introKey directly
    if (resolvedHintKey == null) {
      return introKey;
    }

    if (_inMemoryPlayed.contains(introKey)) {
      return resolvedHintKey;
    }

    // Mark as played and persist asynchronously in background
    _inMemoryPlayed.add(introKey);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('$_storagePrefix$introKey', true);
    }).catchError((_) {});

    return introKey;
  }

  /// Checks whether the intro for a key has already been played in persistent storage.
  static bool hasIntroPlayed(String introKey) {
    return _inMemoryPlayed.contains(introKey);
  }

  /// Resets visited screen state (for testing or profile reset).
  static Future<void> resetAll() async {
    _inMemoryPlayed.clear();
    _sessionPlayedKeys.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(_storagePrefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
