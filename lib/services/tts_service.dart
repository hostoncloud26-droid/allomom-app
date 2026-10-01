import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:allomom/api/chatbot_api.dart';
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
  int _flutterTtsGeneration = 0;
  VoidCallback? _flutterTtsOnComplete;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGeneratingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentSpeakingText = ValueNotifier<String?>(null);

  /// Opens when the line being spoken stops sounding, however it stopped.
  /// Held here rather than passed around so [stop] can release it too — a
  /// cancelled utterance reports nothing through its completion handler.
  Completer<void>? _speechGate;
  bool _isInitialized = false;
  bool _isPluginAvailable = true;

  /// How long a recorded clip (a step's `audio_url` / `audio_key`) has to
  /// start playing before the line is spoken by TTS instead.
  static const Duration recordedClipTimeout = Duration(seconds: 2);

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
        if (_flutterTtsGeneration == _speakGeneration) {
          isSpeakingNotifier.value = true;
        }
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint(
          'TtsService: FlutterTTS completion (gen: $_flutterTtsGeneration, current: $_speakGeneration)',
        );
        if (_flutterTtsGeneration == _speakGeneration) {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          final cb = _flutterTtsOnComplete;
          _flutterTtsOnComplete = null;
          cb?.call();
        }
      });

      _flutterTts.setCancelHandler(() {
        debugPrint(
          'TtsService: FlutterTTS cancel (gen: $_flutterTtsGeneration, current: $_speakGeneration)',
        );
        if (_flutterTtsGeneration == _speakGeneration) {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          _flutterTtsOnComplete = null;
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint(
          'TtsService: FlutterTTS Error: $msg (gen: $_flutterTtsGeneration, current: $_speakGeneration)',
        );
        if (_flutterTtsGeneration == _speakGeneration) {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          final cb = _flutterTtsOnComplete;
          _flutterTtsOnComplete = null;
          cb?.call();
        }
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
  /// Reads it with the language's speech tag from the Builder ("ta-IN"), then
  /// the bare language ("ta") for a phone whose voice is filed under another
  /// region, and English only when the phone has neither.
  Future<void> setLanguage(String language) async {
    final locale = AppLanguage.ttsLocale(language);
    final bare = locale.split(RegExp('[-_]')).first;
    try {
      for (final candidate in {locale, bare}) {
        if (await _flutterTts.isLanguageAvailable(candidate) == true) {
          await _flutterTts.setLanguage(candidate);
          return;
        }
      }
      debugPrint(
        'TtsService: no device voice for $locale — install it under '
        'Settings › Text-to-speech; reading with en-IN instead',
      );
      await _flutterTts.setLanguage('en-IN');
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
  ///
  /// The recording gets [recordedClipTimeout] to start; one that has not by
  /// then is dropped and the line is spoken by 2 or 3 instead.
  ///
  /// [recordedOnly] keeps voices 2 and 3 out of it when there is no recording
  /// at all: a line without a clip stays silent. For the replies that arrive
  /// without the mother having asked for them — the flow the page opens on.
  /// A line that does name a clip is still read aloud if the clip fails.
  ///
  /// [designedVoiceOnly] replaces 2 and 3 with AlloBaby's designed voice from
  /// the server's `/chatbot/ai/tts`. Nothing else stands in for it: when that
  /// voice cannot be had, the line is left unspoken rather than read by a
  /// voice that does not sound like the baby.
  Future<void> speak(
    String text, {
    VoidCallback? onComplete,
    String? language,
    String? audioUrl,
    bool recordedOnly = false,
    bool designedVoiceOnly = false,
  }) async {
    await _speak(
      text,
      onComplete: onComplete,
      language: language,
      audioUrl: audioUrl,
      recordedOnly: recordedOnly,
      designedVoiceOnly: designedVoiceOnly,
    );
  }

  /// Speaks [text] and returns only once the voice has actually stopped —
  /// because it reached the end of the line, or because something stopped it.
  ///
  /// The gate a conversation advances on. [speak] returns as soon as playback
  /// *starts*, which is right for a one-off line but wrong for a flow: the
  /// next step would print and start speaking over the step before it, and
  /// since every [speak] begins by stopping the last one, only the final
  /// bubble of a multi-step turn was ever heard.
  ///
  /// A manual [stop] opens the gate too, so tapping "stop talking" moves the
  /// flow on rather than stranding it behind a voice nobody is listening to.
  Future<void> speakAndWait(
    String text, {
    VoidCallback? onComplete,
    String? language,
    String? audioUrl,
    bool recordedOnly = false,
    bool designedVoiceOnly = false,
  }) async {
    final Completer<void> gate;
    try {
      gate = await _speak(
        text,
        onComplete: onComplete,
        language: language,
        audioUrl: audioUrl,
        recordedOnly: recordedOnly,
        designedVoiceOnly: designedVoiceOnly,
      );
    } catch (e) {
      // Nothing is sounding, so there is nothing to wait for.
      debugPrint('TtsService: could not start speaking: $e');
      return;
    }
    if (gate.isCompleted) return;

    // A backstop, not the mechanism: every voice here reports its own end, but
    // a player that neither completes nor errors would otherwise hold the
    // whole conversation open. Scaled to the line, since a long paragraph read
    // slowly is minutes rather than seconds.
    final limit = Duration(
      seconds: (text.length / 5).clamp(30, 300).round(),
    );
    await gate.future.timeout(
      limit,
      onTimeout: () => debugPrint(
        'TtsService: narration did not report its end within '
        '${limit.inSeconds}s — moving on',
      ),
    );
  }

  /// Starts the voice and hands back the gate that opens when it stops.
  ///
  /// A [Completer] rather than its future, because Dart flattens a returned
  /// `Future<Future<void>>` and the gate would be indistinguishable from this
  /// method's own completion.
  Future<Completer<void>> _speak(
    String text, {
    VoidCallback? onComplete,
    String? language,
    String? audioUrl,
    bool recordedOnly = false,
    bool designedVoiceOnly = false,
  }) async {
    // stop() bumps _speakGeneration, so the token for this call has to be
    // taken *after* it. Taking it first made every later `generation ==
    // _speakGeneration` check fail, and speak() bailed out between
    // synthesising the clip and playing it.
    await stop();
    final generation = ++_speakGeneration;

    // The gate for this line. `stop()` above already released the previous
    // one, so nothing is left waiting on a voice that has been superseded.
    final gate = Completer<void>();
    _speechGate = gate;

    void done() {
      if (identical(_speechGate, gate)) _speechGate = null;
      if (!gate.isCompleted) gate.complete();
      onComplete?.call();
    }

    final cleanText = cleanForSpeech(text);
    final recordedUrl = audioUrl?.trim() ?? '';

    // The words decide the voice: Tamil read by an English voice is noise,
    // and most callers pass no language at all. Text the script does not
    // settle keeps whatever was asked for, else English.
    final requested = language?.trim().toLowerCase() ?? '';
    language = AppLanguage.fromScript(cleanText, hint: requested) ??
        ((requested.isEmpty || requested == 'all') ? 'en' : requested);
    if (recordedUrl.isEmpty && (cleanText.isEmpty || recordedOnly)) {
      done();
      return gate;
    }

    currentSpeakingText.value = text;
    isGeneratingNotifier.value = true;

    // 1. The recorded clip the answer came with. It gets [recordedClipTimeout]
    // to start sounding; past that the line is read by a synthesised voice
    // instead, so a slow or missing clip never holds the conversation up.
    // That holds for [recordedOnly] too: the line was meant to be heard.
    if (recordedUrl.isNotEmpty) {
      final started = await _playAudio(
        UrlSource(recordedUrl),
        generation,
        done,
        startTimeout: recordedClipTimeout,
        deviceFallback: !designedVoiceOnly,
      );
      if (started) return gate;
      if (generation != _speakGeneration) return gate;
      debugPrint('Intent audio unplayable, falling back to TTS: $recordedUrl');
    }

    if (designedVoiceOnly) {
      if (cleanText.isNotEmpty) {
        final clip = await _synthesiseDesignedVoice(cleanText, language);
        if (generation != _speakGeneration) return gate;
        if (clip != null) {
          final started = await _playAudio(
            DeviceFileSource(clip, mimeType: 'audio/wav'),
            generation,
            done,
            deviceFallback: false,
          );
          if (started) return gate;
          if (generation != _speakGeneration) return gate;
        }
      }
      debugPrint('TtsService: designed voice unavailable — line left unspoken');
      isGeneratingNotifier.value = false;
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      done();
      return gate;
    }

    // 2. The online voice, only when it has been switched on and pointed
    // somewhere — asking an unconfigured server would cost every reply a
    // timeout before the phone's own voice got its turn.
    if (cleanText.isNotEmpty) {
      final online = await _synthesiseOnline(cleanText, language);
      if (generation != _speakGeneration) return gate;

      if (online != null && online.isNotEmpty) {
        final started = await _playAudio(UrlSource(online), generation, done);
        if (started) return gate;
        if (generation != _speakGeneration) return gate;
      }
    }

    // 3. The engine on the phone.
    isGeneratingNotifier.value = false;
    if (cleanText.isEmpty) {
      isSpeakingNotifier.value = false;
      currentSpeakingText.value = null;
      done();
      return gate;
    }
    await _speakWithDeviceTts(cleanText, generation, language, done);
    return gate;
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

  /// Fetches [cleanText] in AlloBaby's designed voice and saves it to a file
  /// the player can open, or returns null when the server could not voice it.
  ///
  /// A file rather than [BytesSource], which iOS does not support.
  Future<String?> _synthesiseDesignedVoice(
    String cleanText,
    String? language,
  ) async {
    try {
      final res = await ChatbotApi.synthesizeSpeech(
        text: cleanText,
        langCode: language,
      );
      final item = res.item;
      final audio = item is Map ? item['audio'] : null;
      if (!res.success || audio is! String || audio.isEmpty) {
        debugPrint('Designed voice TTS failed: ${res.detail}');
        return null;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/allobot_tts.wav');
      await file.writeAsBytes(base64Decode(audio), flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Designed voice TTS failed: $e');
      return null;
    }
  }

  /// Plays [source], returning whether playback actually began.
  ///
  /// `setSourceUrl` + `resume` rather than `play` so a prepare failure (404,
  /// unreachable host, unsupported codec) throws here and the caller can fall
  /// back, instead of leaving the UI stuck on a clip that never sounds.
  ///
  /// [startTimeout] is how long the clip has, from this call, to be heard:
  /// loading it past that throws here, and a clip loaded but still not
  /// playing by then is handed to the device voice.
  ///
  /// [deviceFallback] off, a clip that stalls ends the line in silence instead
  /// of handing it to the phone's voice.
  Future<bool> _playAudio(
    Source source,
    int generation,
    VoidCallback? onComplete, {
    Duration startTimeout = const Duration(seconds: 5),
    bool deviceFallback = true,
  }) async {
    final started = Stopwatch()..start();
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

      debugPrint('TtsService playing audio: $source');

      // release(), not stop(): handed the URL it already holds, the Android
      // player skips preparing and reports it ready at once — even when the
      // last attempt at that URL never finished loading. Resuming then shows
      // "playing" while nothing sounds, and the stall check below is fooled.
      await _audioPlayer.release();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setAudioContext(_speechAudioContext);
      await _audioPlayer.setVolume(1.0);
      final load = _audioPlayer.setSource(source);
      // Past the timeout nobody awaits the load any more, but it still fails
      // eventually (a 404 takes the player ~30s to give up on); that late
      // error must not surface as an unhandled exception.
      unawaited(load.catchError((_) {}));
      await load.timeout(startTimeout - started.elapsed);

      if (generation != _speakGeneration) {
        await _audioPlayer.stop();
        return false;
      }

      await _audioPlayer.resume();

      _isPlayingAudioPlayer = true;
      isGeneratingNotifier.value = false;
      isSpeakingNotifier.value = true;

      // Anything not actually sounding by [startTimeout] is stalled rather
      // than slow. The player's state is no evidence — resume() sets it to
      // "playing" before a single sample is heard — so the check is whether
      // the position has moved. A little grace past the deadline, so a clip
      // that loaded just in time is not cut off before its first frame.
      var remaining = startTimeout - started.elapsed;
      const grace = Duration(milliseconds: 400);
      if (remaining < grace) remaining = grace;
      unawaited(
        Future<void>.delayed(remaining).then((_) async {
          if (generation != _speakGeneration || !_isPlayingAudioPlayer) return;
          final state = _audioPlayer.state;
          if (state == PlayerState.completed) return;
          Duration? position;
          try {
            position = await _audioPlayer.getCurrentPosition();
          } catch (_) {}
          if (state == PlayerState.playing &&
              position != null &&
              position > Duration.zero) {
            return;
          }
          if (generation != _speakGeneration || !_isPlayingAudioPlayer) return;
          debugPrint(
            'Clip not sounding after ${started.elapsed.inMilliseconds}ms '
            '($state, position $position)'
            '${deviceFallback ? ', using device TTS' : ''}',
          );
          _isPlayingAudioPlayer = false;
          // The abandoned clip may still "complete" once it gives up; that
          // must not end the line the device voice is now reading.
          await _playerCompleteSub?.cancel();
          _playerCompleteSub = null;
          try {
            await _audioPlayer.release();
          } catch (_) {}
          if (generation != _speakGeneration) return;
          isSpeakingNotifier.value = false;
          if (!deviceFallback) {
            currentSpeakingText.value = null;
            onComplete?.call();
            return;
          }
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
      await _playerCompleteSub?.cancel();
      _playerCompleteSub = null;
      try {
        await _audioPlayer.release();
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

      _flutterTtsGeneration = generation;
      _flutterTtsOnComplete = onComplete;
      isSpeakingNotifier.value = true;

      _flutterTts.setCompletionHandler(() {
        debugPrint(
          'TtsService: device TTS completed (gen: $generation, current: $_speakGeneration)',
        );
        if (generation == _speakGeneration) {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          final cb = _flutterTtsOnComplete;
          _flutterTtsOnComplete = null;
          cb?.call();
        }
      });

      _flutterTts.setCancelHandler(() {
        debugPrint(
          'TtsService: device TTS cancelled (gen: $generation, current: $_speakGeneration)',
        );
        if (generation == _speakGeneration) {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          _flutterTtsOnComplete = null;
        }
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint(
          'TtsService: device TTS error: $msg (gen: $generation, current: $_speakGeneration)',
        );
        if (generation == _speakGeneration) {
          isSpeakingNotifier.value = false;
          currentSpeakingText.value = null;
          final cb = _flutterTtsOnComplete;
          _flutterTtsOnComplete = null;
          cb?.call();
        }
      });

      final durationSec = (cleanText.length / 8).clamp(8.0, 90.0).toInt();
      unawaited(
        Future<void>.delayed(Duration(seconds: durationSec)).then((_) {
          if (generation == _speakGeneration && isSpeakingNotifier.value) {
            debugPrint(
              'TtsService: safety timeout reached for device TTS ($durationSec s)',
            );
            isSpeakingNotifier.value = false;
            currentSpeakingText.value = null;
            final cb = _flutterTtsOnComplete;
            _flutterTtsOnComplete = null;
            cb?.call();
          }
        }),
      );

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

  /// Opens the gate [speakAndWait] is holding, if one is held.
  void _releaseSpeechGate() {
    final gate = _speechGate;
    _speechGate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  Future<void> stop() async {
    _speakGeneration++;
    _flutterTtsOnComplete = null;
    isGeneratingNotifier.value = false;
    // Whatever was waiting on this voice is released: stopping is an ending,
    // and a flow gated on narration would otherwise wait for a line that is
    // never going to finish.
    _releaseSpeechGate();
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
