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

  /// The language AlloBot listens and answers in, which she can set apart
  /// from the app's own language.
  static const String _voiceStorageKey = 'voice_language';

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
  static String? _voiceCached;

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

  /// The language AlloBot speaks in. Until one has been picked on its own it
  /// follows the app language.
  static Future<String> voice() async {
    final cached = _voiceCached;
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_voiceStorageKey);
      _voiceCached = (stored == null || stored.trim().isEmpty)
          ? await current()
          : normalize(stored);
    } catch (e) {
      debugPrint('AppLanguage: could not read stored voice language: $e');
      _voiceCached = await current();
    }
    return _voiceCached!;
  }

  /// The voice language without waiting. Falls back to [cachedOrFallback]
  /// until [voice] has run once.
  static String get voiceCachedOrFallback => _voiceCached ?? cachedOrFallback;

  /// Stores [code] as AlloBot's voice language.
  static Future<void> saveVoice(String code) async {
    final normalized = normalize(code);
    _voiceCached = normalized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_voiceStorageKey, normalized);
    } catch (e) {
      debugPrint('AppLanguage: could not persist voice language: $e');
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

  /// The language [text] is written in, read off its script, or null for
  /// Latin text and anything else the script does not settle.
  ///
  /// Devanagari is shared by Hindi and Marathi, so it keeps [hint] when that
  /// is one of the two and reads as Hindi otherwise.
  static String? fromScript(String text, {String? hint}) {
    for (final rune in text.runes) {
      if (rune >= 0x0B80 && rune <= 0x0BFF) return 'ta';
      if (rune >= 0x0C00 && rune <= 0x0C7F) return 'te';
      if (rune >= 0x0C80 && rune <= 0x0CFF) return 'kn';
      if (rune >= 0x0A80 && rune <= 0x0AFF) return 'gu';
      if (rune >= 0x0900 && rune <= 0x097F) {
        return (hint == 'hi' || hint == 'mr') ? hint : 'hi';
      }
    }
    return null;
  }

  /// Speech tags set on each language in the Builder, by code. They arrive
  /// with the catalogue and win over [_ttsLocales], which only covers a phone
  /// that has not downloaded one yet.
  static final Map<String, String> _speechTags = {};

  /// Replaces the speech tags with [tags], language code to BCP-47 tag.
  static void useSpeechTags(Map<String, String> tags) {
    _speechTags.clear();
    tags.forEach((code, tag) {
      final cleanCode = code.trim().toLowerCase();
      final cleanTag = tag.trim();
      if (cleanCode.isNotEmpty && cleanTag.isNotEmpty) {
        _speechTags[cleanCode] = cleanTag;
      }
    });
  }

  /// The TTS locale tag for [code]: the Builder's speech tag when there is
  /// one, else the built-in default.
  static String ttsLocale(String code) {
    final clean = code.trim().toLowerCase();
    return _speechTags[clean] ?? _ttsLocales[normalize(clean)] ?? 'en-IN';
  }

  /// Drops the remembered choice, once the stored one has been wiped — the
  /// next [current] reads the preferences afresh and finds nothing.
  static void forget() {
    _cached = null;
    _voiceCached = null;
  }

  @visibleForTesting
  static void resetCache() => forget();
}
