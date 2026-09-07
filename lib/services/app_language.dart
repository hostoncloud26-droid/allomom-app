/// The language the mother chose on the language picker.
///
/// The picker used to thread its choice through the auth flow as a constructor
/// argument and then drop it — nothing outside registration could read it. This
/// persists it, so features that need to speak her language (AlloBot's answers
/// and its voice) can ask for it directly.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  AppLanguage._();

  static const String _storageKey = 'app_language';

  /// Fallback when nothing has been chosen yet.
  static const String fallback = 'en';

  /// Codes the language picker offers.
  static const List<String> supported = ['en', 'hi', 'ta', 'kn', 'te', 'mr', 'gu'];

  /// BCP-47 tags for `flutter_tts`, per picker code.
  static const Map<String, String> _ttsLocales = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'kn': 'kn-IN',
    'te': 'te-IN',
    'mr': 'mr-IN',
    'gu': 'gu-IN',
  };

  /// Cached so the chat does not hit SharedPreferences on every reply.
  static String? _cached;

  /// The chosen language code, or [fallback].
  static Future<String> current() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      _cached = normalize(stored);
    } catch (e) {
      debugPrint('AppLanguage: could not read stored language: $e');
      _cached = fallback;
    }
    return _cached!;
  }

  /// The chosen language without waiting, for synchronous call sites. Returns
  /// [fallback] until [current] has run once.
  static String get cachedOrFallback => _cached ?? fallback;

  /// Stores [code] as the app language.
  static Future<void> save(String code) async {
    final normalized = normalize(code);
    _cached = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, normalized);
    } catch (e) {
      debugPrint('AppLanguage: could not persist language: $e');
    }
  }

  /// Maps a stored or picked value onto a supported code.
  ///
  /// The picker offers an "other" option, which is not a language — it falls
  /// back to English rather than being stored as-is.
  static String normalize(String? code) {
    final trimmed = code?.trim().toLowerCase();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return supported.contains(trimmed) ? trimmed : fallback;
  }

  /// The TTS locale tag for [code].
  static String ttsLocale(String code) =>
      _ttsLocales[normalize(code)] ?? 'en-IN';

  @visibleForTesting
  static void resetCache() => _cached = null;
}
