import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/features/background_audio/data/narration_catalog.dart';
import 'package:allomom/features/background_audio/model/narration_audio.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/tts_service.dart';

/// The baby's voice, played behind whatever screen the mother is on.
///
/// Same flow as AlloBaby's controller of the same name — a screen asks for a
/// keyword, the matching clip plays, and the text of that clip is pushed to the
/// speech bubble so she can read it with the sound off. The one difference is
/// where the clips come from: AlloBaby fetches them per language from the
/// backend and caches the list, AlloMom ships them in `assets/audio/<lang>/`,
/// so there is no network step and nothing to wait for on a cold start.
///
/// Registered permanently in `main()`, so the same player survives navigation
/// and only ever has one clip in the air.
///
/// It is the app-wide voice for any key, not only the bundled ones: a key with
/// no bundled clip is played from the AlloBot audio library
/// (`audio.savemom.app/allomom/<lang>/<key>.mp3`), and read aloud from its text
/// when the library has no recording either. Keys that are not in the local
/// catalogue — the weekly baby talk, for one — hand their text over with
/// [registerText].
class BackgroundAudioController extends GetxController {
  static BackgroundAudioController get to => Get.find();

  /// True once `main()` has registered the controller. Screens guard on this
  /// so a widget test that pumps them in isolation does not blow up.
  static bool get isReady => Get.isRegistered<BackgroundAudioController>();

  static const String _voicePrefKey = 'babyVoiceInstruction';

  final AudioPlayer _player = AudioPlayer();

  /// Completes when the clip in the air finishes, errors, or is interrupted by
  /// the next one. [playByKey] awaits it, which is what lets a screen chain
  /// lines together with [playSequence].
  Completer<void>? _clipCompleter;

  /// Keys already spoken since launch. The baby says each line once — coming
  /// back to a screen should not replay its greeting — but the speaker button
  /// bypasses this, so a line is never unreachable.
  final Set<String> _playedKeysThisSession = {};

  /// Text for keys the local catalogue does not know, from [registerText].
  final Map<String, String> _registeredText = {};

  /// The clip a registered key should play, when its caller already knows it
  /// — a step of an AlloBot flow, say, whose clip the engine resolved.
  final Map<String, String> _registeredAudio = {};

  /// True while a line is being voiced through [TtsService] — a library clip
  /// or the text read aloud — rather than this controller's own player.
  bool _speakingViaTts = false;

  /// Bumped on every request. A request that waited for the clip in front of
  /// it checks this before starting: if something newer came along while it
  /// waited, it drops out rather than talking over the screen the mother is
  /// actually looking at.
  int _generation = 0;

  /// Audio assets actually bundled, so a missing localised clip can fall back
  /// to English instead of throwing at play time.
  Set<String> _bundledAudio = const {};
  Completer<void>? _manifestCompleter;

  final RxBool isPlaying = false.obs;
  final RxString currentKey = ''.obs;
  final RxString currentText = ''.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Duration> position = Duration.zero.obs;

  /// Whether the baby is allowed to speak at all. Persisted, so a mother who
  /// turns the voice off keeps it off across launches.
  final RxBool isVoiceEnabled = true.obs;

  /// The language the clips are picked from. Follows the language picker.
  final RxString languageCode = NarrationCatalog.fallbackLanguage.obs;

  @override
  void onInit() {
    super.onInit();

    _loadVoicePreference();
    _loadLanguage();
    _loadManifest();

    // Media-channel playback: the clip ducks other audio rather than fighting
    // it, and keeps playing when the screen is tapped around.
    _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.assistanceAccessibility,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.duckOthers},
        ),
      ),
    );

    _player.onPlayerStateChanged.listen((state) {
      // The idle player reporting "stopped" must not end a line that
      // [TtsService] is voicing.
      if (_speakingViaTts) return;
      isPlaying.value = state == PlayerState.playing;
    });

    _player.onDurationChanged.listen((value) => duration.value = value);
    _player.onPositionChanged.listen((value) => position.value = value);

    _player.onPlayerComplete.listen((_) {
      isPlaying.value = false;
      position.value = Duration.zero;
      _completeClip();
    });
  }

  Future<void> _loadVoicePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isVoiceEnabled.value = prefs.getBool(_voicePrefKey) ?? true;
    } catch (e) {
      debugPrint('BackgroundAudio: could not read voice preference: $e');
      isVoiceEnabled.value = true;
    }
  }

  Future<void> _loadLanguage() async {
    try {
      languageCode.value = await AppLanguage.current();
    } catch (e) {
      debugPrint('BackgroundAudio: could not read language: $e');
      languageCode.value = NarrationCatalog.fallbackLanguage;
    }
  }

  /// Reads the asset manifest once so [resolve] can tell a bundled clip from a
  /// missing one without a failed play attempt.
  Future<void> _loadManifest() {
    final pending = _manifestCompleter;
    if (pending != null) return pending.future;

    final completer = Completer<void>();
    _manifestCompleter = completer;

    () async {
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        _bundledAudio = manifest
            .listAssets()
            .where((path) => path.startsWith('assets/audio/'))
            .toSet();
      } catch (e) {
        debugPrint('BackgroundAudio: could not read asset manifest: $e');
        _bundledAudio = const {};
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    }();

    return completer.future;
  }

  /// Call after the language picker saves a new choice, so the rest of
  /// onboarding is spoken in it.
  Future<void> setLanguage(String code) async {
    final normalised = AppLanguage.normalize(code);
    if (normalised == languageCode.value) return;
    languageCode.value = normalised;
    await stop();
  }

  Future<void> setVoiceEnabled(bool value) async {
    isVoiceEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_voicePrefKey, value);
    } catch (e) {
      debugPrint('BackgroundAudio: could not persist voice preference: $e');
    }
    if (!value) await stop();
  }

  Future<void> toggleVoice() => setVoiceEnabled(!isVoiceEnabled.value);

  /// The text the baby head card should show for [key], regardless of whether
  /// its clip is bundled or the voice is switched off.
  String textFor(String key) =>
      NarrationCatalog.textFor(key, languageCode: languageCode.value) ??
      _registeredText[key.trim()] ??
      '';

  /// Gives a key outside the local catalogue its words, so the bubble can show
  /// them and the line can be read aloud when no recording exists.
  ///
  /// [audioUrl] names the recording, when the caller already has it; without
  /// one the key is looked up in the audio library.
  void registerText(String key, String text, {String? audioUrl}) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    _registeredText[trimmed] = text.trim();
    final url = audioUrl?.trim() ?? '';
    if (url.isEmpty) {
      _registeredAudio.remove(trimmed);
    } else {
      _registeredAudio[trimmed] = url;
    }
  }

  /// True while [key] is the line currently being spoken.
  bool isSpeaking(String key) => isPlaying.value && currentKey.value == key;

  /// Resolves [key] to the clip that should voice it.
  ///
  /// Prefers the chosen language and falls back to English, so a language whose
  /// recordings have not landed yet still gets a voice rather than silence.
  Future<NarrationAudio> resolve(String key) async {
    await _loadManifest();

    final text = textFor(key);
    final candidates = <String>{
      NarrationCatalog.assetPath(languageCode.value, key),
      NarrationCatalog.assetPath(NarrationCatalog.fallbackLanguage, key),
    };

    for (final path in candidates) {
      // An empty manifest means the read failed; assume a catalogue key's
      // asset is there rather than muting the whole flow over it.
      if (_bundledAudio.contains(path) ||
          (_bundledAudio.isEmpty && NarrationCatalog.contains(key))) {
        return NarrationAudio(key: key, asset: path, text: text);
      }
    }

    return NarrationAudio(key: key, asset: null, text: text);
  }

  /// Speaks the line for [key].
  ///
  /// Returns when the clip finishes, so lines can be chained. A key already
  /// spoken this session is skipped unless [force] is set — which is what the
  /// speaker button on the baby head card passes.
  ///
  /// With [queue], the line waits for whatever is playing to finish instead of
  /// cutting it off. Screens autoplay this way: a line started as one screen
  /// hands over to the next ("We're in!") gets to finish before the new screen
  /// greets her.
  Future<void> playByKey(
    String key, {
    bool force = false,
    bool queue = false,
  }) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;

    if (!isVoiceEnabled.value) {
      // Still surface the line: the card reads it out in text even when the
      // baby has been told to keep quiet.
      currentKey.value = trimmed;
      currentText.value = textFor(trimmed);
      return;
    }

    if (!force && _playedKeysThisSession.contains(trimmed)) {
      // Already said once. Leave the text on the card so the bubble does not
      // fall back to a different line on a revisit.
      currentKey.value = trimmed;
      currentText.value = textFor(trimmed);
      return;
    }
    _playedKeysThisSession.add(trimmed);

    final generation = ++_generation;

    if (queue && isPlaying.value) {
      await _clipCompleter?.future;
      // Superseded while waiting, or the screen that asked has gone. Give the
      // key back: it was never actually spoken, and marking it as heard would
      // mean the card it belongs to stays silent for the rest of the session.
      if (generation != _generation) {
        _playedKeysThisSession.remove(trimmed);
        return;
      }
    }

    final clip = await resolve(trimmed);
    if (generation != _generation) {
      _playedKeysThisSession.remove(trimmed);
      return;
    }

    currentKey.value = trimmed;
    currentText.value = clip.text;

    final path = clip.playerPath;
    if (path == null) {
      await _speakFromLibrary(trimmed, clip.text, generation);
      return;
    }

    await _play(AssetSource(path));
    await _clipCompleter?.future;
  }

  /// Speaks [keys] one after another, stopping early if the voice is turned off
  /// or another screen takes the player over.
  Future<void> playSequence(
    List<String> keys, {
    bool force = false,
    Duration gap = const Duration(milliseconds: 250),
  }) async {
    for (var i = 0; i < keys.length; i++) {
      if (!isVoiceEnabled.value) return;
      await playByKey(keys[i], force: force);
      if (i < keys.length - 1 && gap > Duration.zero) {
        await Future<void>.delayed(gap);
      }
    }
  }

  /// Replays [key] from the start — what the speaker button on the card calls.
  /// Tapping it while that same line is playing stops it instead.
  Future<void> replay(String key) async {
    if (isSpeaking(key)) {
      await stop();
      return;
    }
    await playByKey(key, force: true);
  }

  /// Voices a key that has no bundled clip: its recording in the AlloBot
  /// audio library, or — when there is none in her language — its text read
  /// aloud. [TtsService] makes that choice; this keeps [isPlaying] and the
  /// clip completer in step so the card animates and sequences still chain.
  Future<void> _speakFromLibrary(
    String key,
    String text,
    int generation,
  ) async {
    // The clip the library files under this key, else where the library
    // would keep it by convention.
    final url =
        _registeredAudio[key] ??
        OfflineChatbotController.instance.libraryAudioUrl(
          key,
          languageCode.value,
        ) ??
        OfflineChatbotEngine.audioUrlForKey(key, languageCode.value);
    _completeClip();
    final completer = Completer<void>();
    _clipCompleter = completer;

    try {
      await _player.stop();
    } catch (_) {}
    if (generation != _generation) {
      if (!completer.isCompleted) completer.complete();
      return;
    }

    _speakingViaTts = true;
    isPlaying.value = true;
    try {
      await TtsService().speakAndWait(
        text,
        language: languageCode.value,
        audioUrl: url,
        // No words to fall back on: the recording plays or nothing does.
        recordedOnly: text.trim().isEmpty,
      );
    } catch (e) {
      debugPrint('BackgroundAudio: could not voice "$key": $e');
    } finally {
      if (generation == _generation) {
        _speakingViaTts = false;
        isPlaying.value = false;
        position.value = Duration.zero;
      }
      if (!completer.isCompleted) completer.complete();
      if (identical(_clipCompleter, completer)) _clipCompleter = null;
    }
  }

  Future<void> _stopTts() async {
    if (!_speakingViaTts) return;
    _speakingViaTts = false;
    try {
      await TtsService().stop();
    } catch (e) {
      debugPrint('BackgroundAudio: could not stop speech: $e');
    }
  }

  Future<void> _play(Source source) async {
    await _stopTts();
    _completeClip();
    _clipCompleter = Completer<void>();
    try {
      await _player.stop();
      await _player.setSource(source);
      await _player.setVolume(1.0);
      await _player.resume();
    } catch (e) {
      debugPrint('BackgroundAudio: could not play $source: $e');
      _completeClip();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() async {
    if (!isVoiceEnabled.value) return;
    await _player.resume();
  }

  /// Stops whatever is playing and clears the card.
  Future<void> stop() async {
    // Anything waiting its turn behind this clip is cancelled too: an explicit
    // stop means silence, not "play the next one early".
    _generation++;
    await _stopTts();
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('BackgroundAudio: could not stop player: $e');
    }
    isPlaying.value = false;
    position.value = Duration.zero;
    currentKey.value = '';
    _completeClip();
  }

  /// Stops only if [key] is what is playing.
  ///
  /// Screens call this when they are disposed: without the guard, a screen
  /// being popped would cut off the line the screen it pushed just started.
  Future<void> stopKey(String key) async {
    if (currentKey.value != key.trim()) return;
    await stop();
  }

  Future<void> seek(Duration to) => _player.seek(to);

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// Whether [key] has already been spoken since launch.
  bool hasSpoken(String key) => _playedKeysThisSession.contains(key.trim());

  /// Lets a line be heard again later in the same session.
  void forget(String key) => _playedKeysThisSession.remove(key.trim());

  @visibleForTesting
  void resetSession() => _playedKeysThisSession.clear();

  void _completeClip() {
    final completer = _clipCompleter;
    if (completer != null && !completer.isCompleted) completer.complete();
    _clipCompleter = null;
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
