import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:flutter_voice_engine/flutter_voice_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:allomom/services/speech_activity.dart';

/// AlloBaby's "Talk to Your Baby" Gemini Live call, without its page.
///
/// The same model, prompt, microphone and playback as AlloBaby's
/// `GeminiLivePage`, run behind whichever card asked for it: Talk2Baby hands a
/// question the offline catalogue could not answer to this, and the card the
/// question was asked in shows the call — thinking while it connects, then the
/// baby's words as she says them.
///
/// One call at a time, since there is one microphone. Whoever [start]s it owns
/// it; anything that silences the baby ([SpeechActivity.stopAll], the docked
/// mic) or the app going to the background ends it.
class AlloBabyLiveSession extends ChangeNotifier with WidgetsBindingObserver {
  AlloBabyLiveSession._() {
    WidgetsBinding.instance.addObserver(this);
    SpeechActivity.instance.stopRequests.addListener(_onStopRequested);
  }

  static final AlloBabyLiveSession instance = AlloBabyLiveSession._();

  static const int _micSampleRate = 16000;
  static const int _pcmPlaybackSampleRate = 24000;

  final FlutterVoiceEngine _voiceEngine = FlutterVoiceEngine();

  LiveSession? _session;
  StreamSubscription<LiveServerResponse>? _responseSubscription;
  StreamSubscription<Uint8List>? _audioChunkSubscription;
  bool _isVoiceEngineReady = false;
  bool _isPcmAudioReady = false;

  Object? _owner;
  void Function(String userText, String babyText)? _onTurn;

  /// Bumped by every [start] and [stop], so a connect that finishes after the
  /// call was abandoned closes itself instead of taking over.
  int _generation = 0;

  /// From [start] until the call is live — the baby is "thinking".
  bool isConnecting = false;

  /// The call is live and listening.
  bool isActive = false;

  /// What the baby is saying this turn, as she says it.
  String babyText = '';

  /// What the mother is saying, as Gemini hears it.
  String userText = '';

  /// When the audio queued so far finishes playing. Gemini sends a reply
  /// faster than it is spoken, so "speaking" follows the playback, not the
  /// stream.
  DateTime _playbackEndsAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _speakingTimer;

  bool get isOn => isConnecting || isActive;

  /// The baby's voice is sounding.
  bool get isBabySpeaking => DateTime.now().isBefore(_playbackEndsAt);

  bool isOwnedBy(Object who) => isOn && identical(_owner, who);

  /// The line a card shows: the baby's words while she has any this turn,
  /// otherwise what the mother is saying, otherwise that the baby is
  /// listening.
  String get line {
    if (babyText.trim().isNotEmpty) return babyText.trim();
    if (userText.trim().isNotEmpty) return userText.trim();
    return 'Listening…';
  }

  /// Opens a call for [owner] and asks [question] in it. True once the call
  /// is live; false if it could not connect, or was stopped first.
  ///
  /// [onTurn] gets each finished exchange — what she said (empty for the
  /// opening question, which was typed) and the baby's answer.
  Future<bool> start({
    required Object owner,
    required String question,
    void Function(String userText, String babyText)? onTurn,
  }) async {
    await stop();
    final generation = ++_generation;
    _owner = owner;
    _onTurn = onTurn;
    isConnecting = true;
    babyText = '';
    userText = '';
    _babyTurnComplete = false;
    notifyListeners();

    try {
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        throw Exception('Microphone permission not granted.');
      }
      if (generation != _generation) return false;

      await _ensureVoiceEngineInitialized();
      if (generation != _generation) return false;
      _startAudioChunkStream();

      await _preparePcmAudio();
      if (generation != _generation) return false;

      final liveModel = FirebaseAI.googleAI().liveGenerativeModel(
        model: 'gemini-2.5-flash-native-audio-preview-12-2025',
        liveGenerationConfig: LiveGenerationConfig(
          responseModalities: [ResponseModalities.audio],
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
        ),
        systemInstruction: Content.system(
          'You are a caring Baby Companion inside the AlloMom app, speaking to a mother. '
          'Greet her warmly like a baby would: "Hi mommy! How are you feeling today?" '
          'Your role is to support mothers during pregnancy and after delivery with empathy and joy. '
          'Always respond in the same language that the mother speaks to you (e.g., if she speaks in Tamil, respond in Tamil; if in Hindi, respond in Hindi; if in English, respond in English). '
          'Ask about her well-being, pregnancy symptoms, mood, sleep, and postpartum recovery. '
          'Provide gentle guidance on pregnancy care, nutrition, rest, mental health, and baby care. '
          'Keep responses natural, concise, and warm like talking with a baby. '
          'Do not call tools or function declarations. '
          'Prioritize emotional support and practical pregnancy/postpartum advice.',
        ),
      );

      final session = await liveModel.connect();
      if (generation != _generation) {
        unawaited(session.close());
        return false;
      }
      _session = session;
      _startResponseLoop(session);
      unawaited(_send(session, question));

      await _voiceEngine.startRecording();
      if (generation != _generation) {
        // Stopped while the mic was starting, after stop() had turned it off.
        unawaited(_voiceEngine.stopRecording());
        return false;
      }

      unawaited(WakelockPlus.enable());
      isConnecting = false;
      isActive = true;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('[AlloBabyLive] Could not start the call: $error');
      if (generation == _generation) await stop();
      return false;
    }
  }

  /// Ends the call. With [owner], only if that is whose call it is.
  Future<void> stop({Object? owner}) async {
    if (owner != null && !identical(owner, _owner)) return;
    final wasOn = isOn || _session != null;
    _generation++;
    _owner = null;
    _onTurn = null;
    isConnecting = false;
    isActive = false;
    babyText = '';
    userText = '';
    _playbackEndsAt = DateTime.fromMillisecondsSinceEpoch(0);
    _speakingTimer?.cancel();
    if (wasOn) notifyListeners();
    if (!wasOn) return;

    unawaited(WakelockPlus.disable());
    await _audioChunkSubscription?.cancel();
    _audioChunkSubscription = null;
    try {
      await _voiceEngine
          .stopRecording()
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {}
    await _responseSubscription?.cancel();
    _responseSubscription = null;
    try {
      if (_isPcmAudioReady) {
        await FlutterPcmSound.release()
            .timeout(const Duration(milliseconds: 500));
        _isPcmAudioReady = false;
      }
    } catch (_) {}
    final session = _session;
    _session = null;
    if (session != null) {
      unawaited(
        session.close().timeout(const Duration(seconds: 2)).catchError((_) {}),
      );
    }
  }

  void _onStopRequested() {
    if (isOn) unawaited(stop());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The permission prompt makes the app inactive while connecting, so only
    // a live call is ended here.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        (state == AppLifecycleState.inactive && isActive)) {
      if (isActive) unawaited(stop());
    }
  }

  Future<void> _ensureVoiceEngineInitialized() async {
    if (_isVoiceEngineReady) return;
    _voiceEngine.audioConfig = AudioConfig(
      enableAEC: true,
      sampleRate: _micSampleRate,
      amplitudeThreshold: 0.02,
      bufferSize: 1024,
    );
    _voiceEngine.sessionConfig = AudioSessionConfig(
      category: AudioCategory.playAndRecord,
      mode: AudioMode.voiceChat,
      options: {AudioOption.defaultToSpeaker},
      preferredBufferDuration: 0.005,
    );
    await _voiceEngine.initialize();
    _isVoiceEngineReady = true;
  }

  void _startAudioChunkStream() {
    _audioChunkSubscription?.cancel();
    _audioChunkSubscription = _voiceEngine.audioChunkStream.listen(
      (pcmChunk) {
        final session = _session;
        if (!isActive || session == null || pcmChunk.isEmpty) return;
        final mimeType = defaultTargetPlatform == TargetPlatform.iOS
            ? 'audio/pcm;rate=24000'
            : 'audio/pcm;rate=$_micSampleRate';
        unawaited(
          session.sendAudioRealtime(InlineDataPart(mimeType, pcmChunk)),
        );
      },
      onError: (error) =>
          debugPrint('[AlloBabyLive] Microphone stream error: $error'),
      cancelOnError: false,
    );
  }

  Future<void> _send(LiveSession session, String question) async {
    final prompt = question.trim();
    try {
      await session.sendTextRealtime(prompt.isEmpty ? 'hello' : prompt);
    } catch (error) {
      debugPrint('[AlloBabyLive] Could not send the question: $error');
    }
  }

  void _startResponseLoop(LiveSession session) {
    _responseSubscription?.cancel();
    _responseSubscription = session.receive().listen(
      _handleLiveResponse,
      onError: (error) => debugPrint('[AlloBabyLive] Live error: $error'),
      onDone: () {
        if (identical(_session, session)) unawaited(stop());
      },
      cancelOnError: false,
    );
  }

  /// Whether the baby's last turn has finished, so the next words — hers or
  /// the mother's — start a fresh line.
  bool _babyTurnComplete = false;

  void _handleLiveResponse(LiveServerResponse response) {
    final message = response.message;
    if (message is! LiveServerContent) return;

    if (message.interrupted == true) {
      _playbackEndsAt = DateTime.now();
    }

    final inputText = message.inputTranscription?.text;
    if (inputText != null && inputText.isNotEmpty) {
      if (_babyTurnComplete) {
        babyText = '';
        _babyTurnComplete = false;
      }
      userText += inputText;
    }

    final outputText = message.outputTranscription?.text;
    if (outputText != null && outputText.isNotEmpty) {
      if (_babyTurnComplete) {
        babyText = '';
        _babyTurnComplete = false;
      }
      babyText += outputText;
    }

    final parts = message.modelTurn?.parts;
    if (parts != null) {
      for (final part in parts) {
        if (part is InlineDataPart && part.mimeType.startsWith('audio/pcm')) {
          unawaited(_playAudioChunk(part.bytes));
        }
      }
    }

    if (message.turnComplete == true) {
      _onTurn?.call(userText.trim(), babyText.trim());
      userText = '';
      _babyTurnComplete = true;
    }

    notifyListeners();
  }

  Future<void> _preparePcmAudio() async {
    if (_isPcmAudioReady) return;
    await FlutterPcmSound.setup(
      sampleRate: _pcmPlaybackSampleRate,
      channelCount: 1,
    );
    _isPcmAudioReady = true;
  }

  Future<void> _playAudioChunk(Uint8List bytes) async {
    if (bytes.isEmpty || !isActive) return;
    if (!_isPcmAudioReady) await _preparePcmAudio();

    final alignedLength = bytes.lengthInBytes - (bytes.lengthInBytes % 2);
    if (alignedLength <= 0) return;

    // 16-bit mono: two bytes a sample.
    final duration = Duration(
      microseconds: (alignedLength ~/ 2) * 1000000 ~/ _pcmPlaybackSampleRate,
    );
    final now = DateTime.now();
    final wasSpeaking = isBabySpeaking;
    _playbackEndsAt =
        (_playbackEndsAt.isAfter(now) ? _playbackEndsAt : now).add(duration);
    _speakingTimer?.cancel();
    _speakingTimer = Timer(_playbackEndsAt.difference(now), notifyListeners);
    if (!wasSpeaking) notifyListeners();

    final pcmBytes = Uint8List.sublistView(bytes, 0, alignedLength);
    await FlutterPcmSound.feed(
      PcmArrayInt16(bytes: ByteData.sublistView(pcmBytes)),
    );
  }
}
