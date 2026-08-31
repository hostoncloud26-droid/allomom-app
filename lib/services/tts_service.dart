import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
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

      final cleanText = text
          .replaceAll(RegExp(r'[*_`#~]'), ' ')
          .replaceAll(RegExp(r"[^\w\s,.!?'-]"), '')
          .trim();

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
