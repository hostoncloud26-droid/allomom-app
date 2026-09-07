import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:allomom/services/app_language.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentSpeakingText = ValueNotifier<String?>(null);
  bool _isInitialized = false;
  bool _isPluginAvailable = true;

  bool get isSpeaking => isSpeakingNotifier.value;
  bool get isPluginAvailable => _isPluginAvailable;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.05); // Warm, maternal tone
      await _flutterTts.setSpeechRate(0.48); // Gentle, calm speaking rate
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        isSpeakingNotifier.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeakingNotifier.value = false;
        currentSpeakingText.value = null;
      });

      _flutterTts.setCancelHandler(() {
        isSpeakingNotifier.value = false;
        currentSpeakingText.value = null;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('FlutterTTS Error: $msg');
        isSpeakingNotifier.value = false;
        currentSpeakingText.value = null;
      });

      _isInitialized = true;
      _isPluginAvailable = true;
    } on MissingPluginException catch (e) {
      debugPrint('TtsService: Plugin not registered yet (requires full app restart): $e');
      _isInitialized = true;
      _isPluginAvailable = false;
    } catch (e) {
      debugPrint('Error initializing TtsService: $e');
      _isInitialized = true;
      _isPluginAvailable = false;
    }
  }

  /// Strips markdown and emoji while keeping the letters of every script.
  ///
  /// The previous cleaning used `[^\w\s,.!?'-]`, and Dart's `\w` is ASCII
  /// only — so a Tamil, Hindi, Marathi or Gujarati answer was reduced to
  /// punctuation and the engine was handed an empty string. Unicode letter and
  /// number classes keep those scripts intact; the explicit emoji ranges are
  /// what actually needs removing, because a speech engine reads a heart emoji
  /// aloud as "red heart".
  static String cleanForSpeech(String text) => text
      .replaceAll(RegExp(r'[*_`#~]'), ' ')
      .replaceAll(
        RegExp(
          r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2190}-\u{21FF}'
          r'\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}\u{20E3}]',
          unicode: true,
        ),
        '',
      )
      .replaceAll(
        RegExp(r"[^\p{L}\p{N}\s,.!?'-]", unicode: true),
        ' ',
      )
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  /// Points the engine at [language] (an app picker code).
  ///
  /// A device with no voice for that locale throws or silently refuses, so a
  /// failure falls back to English rather than leaving the engine unset.
  Future<void> setLanguage(String language) async {
    final locale = AppLanguage.ttsLocale(language);
    try {
      final available = await _flutterTts.isLanguageAvailable(locale);
      await _flutterTts.setLanguage(available == true ? locale : 'en-IN');
    } catch (e) {
      debugPrint('TtsService: could not set language $locale: $e');
      try {
        await _flutterTts.setLanguage('en-IN');
      } catch (_) {
        // Leave whatever the engine already had.
      }
    }
  }

  /// Speaks [text], optionally in a specific app language code ('ta', 'hi'…).
  ///
  /// [language] is a picker code, not a BCP-47 tag; [AppLanguage.ttsLocale]
  /// maps it. The engine keeps whatever language was last set, so this is
  /// reapplied on every call rather than once at init.
  Future<void> speak(
    String text, {
    VoidCallback? onComplete,
    String? language,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      if (!_isPluginAvailable) {
        // If native plugin is not compiled yet, simulate completion so UI proceeds
        currentSpeakingText.value = text;
        isSpeakingNotifier.value = true;
        Future.delayed(const Duration(milliseconds: 1600), () {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          onComplete?.call();
        });
        return;
      }

      await stop();

      if (language != null) await setLanguage(language);

      final cleanText = cleanForSpeech(text);

      if (cleanText.isEmpty) {
        onComplete?.call();
        return;
      }

      currentSpeakingText.value = text;
      isSpeakingNotifier.value = true;

      if (onComplete != null) {
        _flutterTts.setCompletionHandler(() {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          onComplete();
        });
      }

      await _flutterTts.speak(cleanText);
    } on MissingPluginException catch (_) {
      _isPluginAvailable = false;
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      onComplete?.call();
    } catch (e) {
      debugPrint('Error in TtsService.speak: $e');
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      onComplete?.call();
    }
  }

  Future<void> stop() async {
    if (!_isPluginAvailable) {
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      return;
    }
    try {
      await _flutterTts.stop();
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  void dispose() {
    stop();
  }
}
