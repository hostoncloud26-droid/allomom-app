import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/omnivoice_service.dart';
import 'package:allomom/services/online_tts_settings.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerErrorSub;
  bool _isPlayingAudioPlayer = false;
  int _speakGeneration = 0;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGeneratingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentSpeakingText = ValueNotifier<String?>(null);
  bool _isInitialized = false;
  bool _isPluginAvailable = true;

  bool get isSpeaking => isSpeakingNotifier.value;
  bool get isGenerating => isGeneratingNotifier.value;
  bool get isPluginAvailable => _isPluginAvailable;

  /// Playback context shared by init() and every clip.
  ///
  /// `media` usage rather than `assistanceAccessibility`: the accessibility
  /// usage is routed to the accessibility stream, which is silent on devices
  /// where that stream is muted or where no accessibility service is running.
  static final AudioContext _speechAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.speech,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.duckOthers},
    ),
  );

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _audioPlayer.setAudioContext(_speechAudioContext);

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

  /// Speaks [text], optionally in a specific app language code ('ta', 'hi'...).
  ///
  /// [language] is a picker code, not a BCP-47 tag; [AppLanguage.ttsLocale]
  /// maps it.
  ///
  /// Three voices, in order of how close each is to a real one:
  ///
  /// 1. [audioUrl] — the clip the intent itself carries. Someone recorded
  ///    this line for this answer, so nothing synthesised can beat it.
  /// 2. The online voice, when the AlloBot settings have it switched on and
  ///    pointed at a server.
  /// 3. The phone's own engine, which is also where 1 and 2 land if the
  ///    server is unreachable or the clip refuses to play.
  Future<void> speak(
    String text, {
    VoidCallback? onComplete,
    String? language,
    String? audioUrl,
  }) async {
    // stop() bumps _speakGeneration, so the token for this call has to be
    // taken *after* it. Taking it first made every later `generation ==
    // _speakGeneration` check fail, and speak() bailed out between
    // synthesising the clip and playing it.
    await stop();
    final generation = ++_speakGeneration;

    final cleanText = cleanForSpeech(text);
    final recordedUrl = audioUrl?.trim() ?? '';
    if (cleanText.isEmpty && recordedUrl.isEmpty) {
      onComplete?.call();
      return;
    }

    currentSpeakingText.value = text;
    isGeneratingNotifier.value = true;

    // 1. The recorded clip the answer came with.
    if (recordedUrl.isNotEmpty) {
      final started = await _playNetworkAudio(recordedUrl, generation, onComplete);
      if (started) return;
      if (generation != _speakGeneration) return;
      debugPrint('Intent audio unplayable, falling back: $recordedUrl');
    }

    // 2. The online voice, only when it has been switched on and pointed
    // somewhere — asking an unconfigured server would cost every reply a
    // timeout before the phone's own voice got its turn.
    if (cleanText.isNotEmpty) {
      final online = await _synthesiseOnline(cleanText, language);
      if (generation != _speakGeneration) return;

      if (online != null && online.isNotEmpty) {
        final started = await _playNetworkAudio(online, generation, onComplete);
        if (started) return;
        if (generation != _speakGeneration) return;
      }
    }

    // 3. The engine on the phone.
    isGeneratingNotifier.value = false;
    if (cleanText.isEmpty) {
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      onComplete?.call();
      return;
    }
    await _speakWithDeviceTts(cleanText, generation, language, onComplete);
  }

  /// Asks the configured server for a clip, or returns null when the online
  /// voice is switched off, unconfigured, or simply did not answer.
  Future<String?> _synthesiseOnline(String cleanText, String? language) async {
    try {
      final settings = OnlineTtsSettings.instance;
      await settings.load();
      if (!settings.isUsable) {
        debugPrint(
          'Online TTS skipped (enabled=${settings.isEnabled.value}, '
          'url="${settings.resolvedBaseUrl}") — using the phone\'s voice',
        );
        return null;
      }

      debugPrint('Online TTS via ${settings.resolvedBaseUrl}');
      OmniVoiceService.instance.setBaseUrl(settings.resolvedBaseUrl);
      final url = await OmniVoiceService.instance.generateBabySpeech(
        text: cleanText,
        langCode: language ?? 'en',
      );
      if (url == null || url.isEmpty) {
        debugPrint('Online TTS returned no clip — using the phone\'s voice');
      }
      return url;
    } catch (e) {
      debugPrint('Online TTS generation failed: $e');
      return null;
    }
  }

  /// Streams the synthesised clip, returning whether playback actually began.
  ///
  /// `setSourceUrl` + `resume` rather than `play` so a prepare failure (404,
  /// unreachable host, unsupported codec) throws here and the caller can fall
  /// back, instead of leaving the UI stuck on a clip that never sounds.
  Future<bool> _playNetworkAudio(
    String audioUrl,
    int generation,
    VoidCallback? onComplete,
  ) async {
    try {
      await _playerCompleteSub?.cancel();
      _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
        debugPrint('OmniVoice network audio playback complete');
        if (generation != _speakGeneration) return;
        _isPlayingAudioPlayer = false;
        isSpeakingNotifier.value = false;
        currentSpeakingText.value = null;
        onComplete?.call();
      });

      await _playerErrorSub?.cancel();
      _playerErrorSub = _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('AudioPlayer state: $state');
      });

      debugPrint('TtsService streaming audio URL: $audioUrl');

      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setAudioContext(_speechAudioContext);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setSourceUrl(audioUrl);

      if (generation != _speakGeneration) {
        await _audioPlayer.stop();
        return false;
      }

      await _audioPlayer.resume();

      _isPlayingAudioPlayer = true;
      isGeneratingNotifier.value = false;
      isSpeakingNotifier.value = true;

      // The clip is served off a local box, so anything that has not reached
      // the playing state within a few seconds is stalled rather than slow.
      // Without this the notifier would stay true forever and no voice would
      // ever be heard.
      unawaited(
        Future<void>.delayed(const Duration(seconds: 5)).then((_) async {
          if (generation != _speakGeneration || !_isPlayingAudioPlayer) return;
          final state = _audioPlayer.state;
          if (state == PlayerState.playing || state == PlayerState.completed) {
            return;
          }
          debugPrint('OmniVoice playback stalled ($state), using device TTS');
          _isPlayingAudioPlayer = false;
          try {
            await _audioPlayer.stop();
          } catch (_) {}
          if (generation != _speakGeneration) return;
          isSpeakingNotifier.value = false;
          await _speakWithDeviceTts(
            cleanForSpeech(currentSpeakingText.value ?? ''),
            generation,
            null,
            onComplete,
          );
        }),
      );

      return true;
    } catch (e) {
      debugPrint('OmniVoice playback failed: $e, falling back to flutter_tts');
      _isPlayingAudioPlayer = false;
      try {
        await _audioPlayer.stop();
      } catch (_) {}
      return false;
    }
  }

  Future<void> _speakWithDeviceTts(
    String cleanText,
    int generation,
    String? language,
    VoidCallback? onComplete,
  ) async {
    if (cleanText.isEmpty || generation != _speakGeneration) return;

    try {
      if (!_isInitialized) {
        await init();
      }

      if (!_isPluginAvailable) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (generation == _speakGeneration) {
            isSpeakingNotifier.value = false;
            currentSpeakingText.value = null;
            onComplete?.call();
          }
        });
        return;
      }

      if (language != null) await setLanguage(language);

      isSpeakingNotifier.value = true;
      if (onComplete != null) {
        _flutterTts.setCompletionHandler(() {
          if (generation == _speakGeneration) {
            isSpeakingNotifier.value = false;
            currentSpeakingText.value = null;
            onComplete();
          }
        });
      }

      await _flutterTts.speak(cleanText);
    } on MissingPluginException catch (_) {
      _isPluginAvailable = false;
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      onComplete?.call();
    } catch (e) {
      debugPrint('Error in TtsService.speak fallback: $e');
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      onComplete?.call();
    }
  }

  Future<void> stop() async {
    _speakGeneration++;
    isGeneratingNotifier.value = false;
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    _playerErrorSub?.cancel();
    _playerErrorSub = null;

    if (_isPlayingAudioPlayer) {
      _isPlayingAudioPlayer = false;
      try {
        await _audioPlayer.stop();
      } catch (_) {}
    }

    if (_isPluginAvailable) {
      try {
        await _flutterTts.stop();
      } catch (e) {
        debugPrint('Error stopping TTS: $e');
      }
    }

    isSpeakingNotifier.value = false;
    currentSpeakingText.value = null;
  }

  void dispose() {
    stop();
    _playerCompleteSub?.cancel();
    _playerErrorSub?.cancel();
    _audioPlayer.dispose();
  }
}
