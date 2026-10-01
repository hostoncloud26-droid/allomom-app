import 'dart:async';

import 'dart:math' as math;
import 'dart:ui';

import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:flutter_voice_engine/flutter_voice_engine.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:lottie/lottie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// AlloBaby's theme colours (Config/Colors.dart there).
const _primaryColor = Color(0xffFF626F);
const _secondaryColor = Color(0xff448AFF);
const _accentColor = Color(0xffffcfd3);

/// AlloBaby's "Talk to Your Baby" Gemini Live page.
///
/// Talk2Baby opens it when the offline catalogue has no answer: it connects
/// straight away, shows the baby thinking while it does, and opens the
/// conversation with [initialPrompt] — the question the catalogue could not
/// answer — instead of a bare hello.
class GeminiLivePage extends StatefulWidget {
  const GeminiLivePage({super.key, this.initialPrompt});

  /// What to open the live session with. Null greets with "hello", as
  /// AlloBaby does.
  final String? initialPrompt;

  @override
  State<GeminiLivePage> createState() => _GeminiLivePageState();
}

class _GeminiLivePageState extends State<GeminiLivePage>
    with WidgetsBindingObserver {
  static const int _micSampleRate = 16000;
  static const int _pcmPlaybackSampleRate = 24000;
  static const Duration _cameraFrameInterval = Duration(milliseconds: 2000);

  final FlutterVoiceEngine _voiceEngine = FlutterVoiceEngine();
  final PCMVisualizer _userVisualizer = PCMVisualizer();
  final PCMVisualizer _aiVisualizer = PCMVisualizer();
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  LiveSession? _session;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;
  StreamSubscription<LiveServerResponse>? _responseSubscription;
  StreamSubscription<Uint8List>? _audioChunkSubscription;
  StreamSubscription<String>? _voiceErrorSubscription;
  Timer? _cameraTimer;
  Future<void>? _teardownFuture;

  CameraController? _cameraController;

  final StringBuffer _userTranscriptBuffer = StringBuffer();
  final StringBuffer _aiTranscriptBuffer = StringBuffer();
  final List<_TranscriptEntry> _timeline = [];
  final List<DateTime> _audioChunkTimestamps = [];

  bool _isConnecting = false;
  bool _isSessionActive = false;
  bool _isMicStreaming = false;
  bool _isModelResponding = false;
  bool _isCameraSharing = false;
  bool _isCameraLoading = false;
  bool _isCameraCapturing = false;
  bool _isPcmAudioReady = false;
  bool _isVoiceEngineReady = false;
  bool _hasRetriedMicStart = false;
  DateTime? _lastMicChunkAt;
  Completer<void>? _voiceEngineInitCompleter;
  String _liveSubtitle = 'Waiting for voice input.'.tr;
  String _activeSpeaker = 'Idle';
  String _status = 'Talk to Your Baby';

  String _targetAiText = "";
  String _displayedAiText = "";
  Timer? _typewriterTimer;
  Timer? _listenTimer;
  final StreamController<String> _typewriterStreamController = StreamController<String>.broadcast();
  bool _isAiTurnComplete = false;

  void _startTypewriter() {
    if (_typewriterTimer != null && _typewriterTimer!.isActive) return;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_displayedAiText.length < _targetAiText.length) {
        _displayedAiText = _targetAiText.substring(0, _displayedAiText.length + 1);
        _typewriterStreamController.add(_displayedAiText);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userVisualizer.reset();
    _aiVisualizer.reset();
    unawaited(WakelockPlus.enable());

    // Talk2Baby hands over mid-conversation, so the live session starts on
    // its own; the first frame already shows the baby thinking.
    _isConnecting = true;
    _status = 'Baby is thinking...'.tr;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isConnecting = false;
      unawaited(_startSession());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(WakelockPlus.enable());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(WakelockPlus.disable());
      unawaited(_pauseForBackground());
    }
  }

  Future<void> _pauseForBackground() async {
    if (_isSessionActive) {
      await _stopSession(closeSession: true);
    }
  }

  Future<void> _ensureVoiceEngineInitialized() async {
    if (_isVoiceEngineReady) return;
    if (_voiceEngineInitCompleter != null) {
      await _voiceEngineInitCompleter!.future;
      return;
    }

    final completer = Completer<void>();
    _voiceEngineInitCompleter = completer;

    _voiceEngine.audioConfig = AudioConfig(
        enableAEC: true,
        sampleRate: _micSampleRate,
        amplitudeThreshold: 0.02,
        bufferSize: 1024);
    _voiceEngine.sessionConfig = AudioSessionConfig(
      category: AudioCategory.playAndRecord,
      mode: AudioMode.voiceChat,
      options: {AudioOption.defaultToSpeaker},
      preferredBufferDuration: 0.005,
    );

    try {
      await _voiceEngine.initialize();
      _isVoiceEngineReady = true;

      await _voiceErrorSubscription?.cancel();
      _voiceErrorSubscription = _voiceEngine.errorStream.listen(
        (error) {
          if (!mounted) return;
          setState(() {
            _status = '${'Voice engine error:'.tr} $error';
          });
        },
      );

      completer.complete();
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      _voiceEngineInitCompleter = null;
    }
  }

  void _startAudioChunkStream() {
    _audioChunkSubscription?.cancel();
    _audioChunkSubscription = _voiceEngine.audioChunkStream.listen(
      (pcmChunk) {
        final currentSession = _session;
        if (!_isSessionActive || currentSession == null || pcmChunk.isEmpty) {
          return;
        }

        _lastMicChunkAt = DateTime.now();

        try {
          _userVisualizer.feed(pcmChunk);
        } catch (_) {
          // Ignore visualizer errors to prevent app crash
        }

        final mimeType = defaultTargetPlatform == TargetPlatform.iOS
            ? 'audio/pcm;rate=24000'
            : 'audio/pcm;rate=$_micSampleRate';
        unawaited(
          currentSession.sendAudioRealtime(
            InlineDataPart(mimeType, pcmChunk),
          ),
        );

        if (!_isMicStreaming && mounted) {
          setState(() {
            _isMicStreaming = true;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _status = '${'Microphone stream error:'.tr} $error';
        });
      },
      cancelOnError: false,
    );
  }

  Future<void> _ensureMicCaptureActive() async {
    _lastMicChunkAt = null;
    _hasRetriedMicStart = false;

    await _voiceEngine.startRecording();
    unawaited(_verifyMicFlow());
  }

  Future<void> _verifyMicFlow() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!_isSessionActive) return;

    final lastChunkAt = _lastMicChunkAt;
    final stale = lastChunkAt == null ||
        DateTime.now().difference(lastChunkAt).inSeconds >= 2;
    if (!stale || _hasRetriedMicStart) {
      return;
    }

    _hasRetriedMicStart = true;
    try {
      await _voiceEngine.stopRecording();
      await Future.delayed(const Duration(milliseconds: 200));
      await _voiceEngine.startRecording();
      if (mounted) {
        setState(() {
          _status = 'Restarted microphone capture. Speak again.'.tr;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = '${'Microphone restart failed:'.tr} $error';
      });
    }
  }

  Future<void> _startSession() async {
    if (_isConnecting || _isSessionActive) return;

    debugPrint(
        '[GeminiLive] _startSession triggered. Setting isConnecting = true');
    setState(() {
      _isConnecting = true;
      _status = 'Baby is thinking...'.tr;
    });
    _typewriterStreamController.add(_status);

    // Wait for any running background teardown to completely finish first
    if (_teardownFuture != null) {
      debugPrint('[GeminiLive] Waiting for previous teardown to complete...');
      await _teardownFuture;
      _teardownFuture = null;
      debugPrint('[GeminiLive] Previous teardown completed.');
    }
    if (!_isConnecting) {
      debugPrint(
          '[GeminiLive] Start cancelled by guard before initialization.');
      return;
    }

    try {
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        throw Exception('Microphone permission not granted.');
      }
      if (!_isConnecting) {
        debugPrint(
            '[GeminiLive] Start cancelled by guard after mic permission check.');
        return;
      }

      debugPrint('[GeminiLive] Ensuring voice engine is initialized...');
      await _ensureVoiceEngineInitialized();
      if (!_isConnecting) {
        debugPrint(
            '[GeminiLive] Start cancelled by guard after voice engine initialization.');
        return;
      }
      _startAudioChunkStream();

      debugPrint('[GeminiLive] Preparing PCM audio playback...');
      await _preparePcmAudio();
      if (!_isConnecting) {
        debugPrint(
            '[GeminiLive] Start cancelled by guard after PCM audio preparation.');
        return;
      }
      if (_isCameraSharing) {
        await _initCameraIfNeeded();
      }
      if (!_isConnecting) {
        debugPrint(
            '[GeminiLive] Start cancelled by guard after camera initialization.');
        return;
      }

      debugPrint('[GeminiLive] Connecting to live generative model...');
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
          'When the camera is shared, describe what you see and react with baby-like enthusiasm. '
          'Do not call tools or function declarations. '
          'Prioritize emotional support and practical pregnancy/postpartum advice.',
        ),
      );

      final session = await liveModel.connect();
      if (!_isConnecting) {
        debugPrint(
            '[GeminiLive] Start cancelled by guard after live model connect. Closing session...');
        unawaited(session.close());
        return;
      }
      _session = session;
      _isSessionActive = true;
      _isMicStreaming = false;
      _isModelResponding = false;
      _userTranscriptBuffer.clear();
      _aiTranscriptBuffer.clear();
      _targetAiText = "";
      _displayedAiText = "";
      _typewriterStreamController.add("");
      _isAiTurnComplete = false;
      _timeline.clear();
      _audioChunkTimestamps.clear();
      _userVisualizer.reset();
      _aiVisualizer.reset();
      _startResponseLoop(session);
      unawaited(_sendInitialGreeting(session));

      debugPrint('[GeminiLive] Activating microphone capture flow...');
      await _ensureMicCaptureActive();
      if (!_isConnecting) {
        debugPrint(
            '[GeminiLive] Start cancelled by guard after mic capture activation.');
        return;
      }

      if (_isCameraSharing) {
        unawaited(_startCameraStreaming());
      }

      debugPrint('[GeminiLive] Session successfully started and active.');
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _status = 'Live session active. Speak now.'.tr;
        _activeSpeaker = 'You';
      });
    } catch (error) {
      debugPrint('[GeminiLive] Error starting session: $error');
      if (!_isConnecting) {
        debugPrint(
            '[GeminiLive] Error caught but start was cancelled, ignoring state changes.');
        return;
      }
      await _stopSession(closeSession: true);
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _status = '${'Failed to start live session:'.tr} $error';
      });
    }
  }

  Future<void> _stopSession({bool closeSession = true}) async {
    debugPrint(
        '[GeminiLive] _stopSession triggered. Setting active speaker and session state to idle/stopped.');
    if (mounted) {
      setState(() {
        _isSessionActive = false;
        _isConnecting = false;
        _isModelResponding = false;
        _isMicStreaming = false;
        _activeSpeaker = 'Idle';
        _targetAiText = "";
        _displayedAiText = "";
        _typewriterStreamController.add("");
        _liveSubtitle = 'Waiting for voice input.'.tr;
        _status = 'Session stopped. Tap Start Live to begin again.'.tr;
      });
    }

    _teardownFuture = _performTeardown(closeSession);
  }

  Future<void> _performTeardown(bool closeSession) async {
    debugPrint('[GeminiLive] _performTeardown started.');
    try {
      debugPrint('[GeminiLive] Stopping camera stream...');
      await _stopCameraStreaming();
      debugPrint('[GeminiLive] Camera stream stopped successfully.');
    } catch (e) {
      debugPrint('[GeminiLive] Error stopping camera stream: $e');
    }

    _listenTimer?.cancel();

    try {
      debugPrint('[GeminiLive] Cancelling mic chunk stream subscription...');
      _audioChunkSubscription?.cancel();
      debugPrint(
          '[GeminiLive] Mic chunk stream subscription cancelled successfully.');
    } catch (e) {
      debugPrint('[GeminiLive] Error cancelling mic subscription: $e');
    }
    _audioChunkSubscription = null;

    try {
      debugPrint('[GeminiLive] Stopping voice engine recording...');
      await _voiceEngine
          .stopRecording()
          .timeout(const Duration(milliseconds: 500));
      debugPrint('[GeminiLive] Voice engine recording stopped successfully.');
    } catch (e) {
      debugPrint('[GeminiLive] Error stopping voice engine recording: $e');
    }

    try {
      debugPrint('[GeminiLive] Cancelling live session response listener...');
      _responseSubscription?.cancel();
      debugPrint(
          '[GeminiLive] Live session response listener cancelled successfully.');
    } catch (e) {
      debugPrint('[GeminiLive] Error cancelling response listener: $e');
    }
    _responseSubscription = null;

    try {
      if (_isPcmAudioReady) {
        debugPrint('[GeminiLive] Releasing FlutterPcmSound player...');
        await FlutterPcmSound.release()
            .timeout(const Duration(milliseconds: 500));
        _isPcmAudioReady = false;
        debugPrint(
            '[GeminiLive] FlutterPcmSound player released successfully.');
      }
    } catch (e) {
      debugPrint('[GeminiLive] Error releasing FlutterPcmSound: $e');
    }

    if (closeSession && _session != null) {
      final sessionToClose = _session;
      _session = null;
      debugPrint(
          '[GeminiLive] Initiating background session socket closure...');
      unawaited(() async {
        try {
          await sessionToClose!.close().timeout(const Duration(seconds: 2));
          debugPrint(
              '[GeminiLive] Background session socket closed successfully.');
        } catch (e) {
          debugPrint(
              '[GeminiLive] Error closing background session socket: $e');
        }
      }());
    } else {
      _session = null;
    }
    debugPrint('[GeminiLive] _performTeardown completed.');
  }

  Future<void> _sendInitialGreeting(LiveSession session) async {
    try {
      final prompt = widget.initialPrompt?.trim() ?? '';
      await session.sendTextRealtime(prompt.isEmpty ? 'hello' : prompt);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = '${'Unable to send greeting:'.tr} $error';
      });
    }
  }

  void _startResponseLoop(LiveSession session) {
    unawaited(_responseSubscription?.cancel());
    _responseSubscription = session.receive().listen(
      _handleLiveResponse,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _status = '${'Live session error:'.tr} $error';
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _status =
              _isSessionActive ? 'Live stream ended unexpectedly.'.tr : _status;
        });
      },
      cancelOnError: false,
    );
  }

  void _handleLiveResponse(LiveServerResponse response) {
    final message = response.message;
    var isTurnComplete = false;

    if (message is LiveServerContent) {
      final liveContent = message;
      if (message.interrupted == true) {
        _listenTimer?.cancel();
        if (mounted) {
          setState(() {
            _isModelResponding = false;
            _status = 'My Baby was interrupted. Listening...'.tr;
          });
        }
      }

      final inputText = message.inputTranscription?.text;
      if (inputText != null && inputText.isNotEmpty) {
        _listenTimer?.cancel();
        debugPrint('[GeminiLive] User Transcript: "$inputText"');
        
        if (_isAiTurnComplete || _targetAiText.isNotEmpty) {
           _targetAiText = "";
           _displayedAiText = "";
           _typewriterStreamController.add("");
           _aiTranscriptBuffer.clear();
           _isAiTurnComplete = false;
           _isModelResponding = false;
        }

        _userTranscriptBuffer
          ..clear()
          ..write(inputText);
          
        _typewriterStreamController.add(_userTranscriptBuffer.toString());
      }

      final outputText = message.outputTranscription?.text;
      if (outputText != null && outputText.isNotEmpty) {
        _listenTimer?.cancel();
        debugPrint('[GeminiLive] AI Transcript: "$outputText"');
        if (_isAiTurnComplete) {
           _targetAiText = "";
           _displayedAiText = "";
           _typewriterStreamController.add("");
           _aiTranscriptBuffer.clear();
           _isAiTurnComplete = false;
        }
        _aiTranscriptBuffer.write(outputText);
        _targetAiText += outputText;
        _startTypewriter();
      }

      final parts = message.modelTurn?.parts;
      if (parts != null) {
        for (final part in parts) {
          if (part is InlineDataPart && part.mimeType.startsWith('audio/pcm')) {
            _isModelResponding = true;
            _audioChunkTimestamps.insert(0, DateTime.now());
            if (_audioChunkTimestamps.length > 8) {
              _audioChunkTimestamps.removeRange(
                  8, _audioChunkTimestamps.length);
            }
            try {
              _aiVisualizer.feed(part.bytes);
            } catch (_) {}
            unawaited(_playAudioChunk(part.bytes));
          }
        }
      }

      if (liveContent.turnComplete == true) {
        isTurnComplete = true;
        _isAiTurnComplete = true;
        _isModelResponding = false;
        
        _listenTimer?.cancel();
        _listenTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _targetAiText = "";
              _displayedAiText = "";
              _typewriterStreamController.add("");
              _isAiTurnComplete = false;
              _activeSpeaker = 'You';
              _typewriterStreamController.add('Listening to your voice...'.tr);
            });
          }
        });

        _appendConversationEntry(
          speaker: 'My Baby',
          text: _aiTranscriptBuffer.toString().trim(),
          color: const Color(0xFF7C3AED),
        );
        _appendConversationEntry(
          speaker: 'You',
          text: _userTranscriptBuffer.toString().trim(),
          color: const Color(0xFF06B6D4),
        );
        _userTranscriptBuffer.clear();
      }
    }

    if (!mounted) return;
    setState(() {
      _isMicStreaming = _isSessionActive;
      
      if (_targetAiText.isNotEmpty) {
        _activeSpeaker = 'My Baby';
      } else if (_isModelResponding) {
        _activeSpeaker = 'My Baby';
        _typewriterStreamController.add('My Baby is speaking...'.tr);
      } else if (_userTranscriptBuffer.isNotEmpty) {
        _activeSpeaker = 'You';
        // We already pushed the user text to the stream in the above block, but just in case:
        _typewriterStreamController.add(_userTranscriptBuffer.toString());
      } else if (_isMicStreaming) {
        _activeSpeaker = 'You';
        if (_targetAiText.isEmpty && _userTranscriptBuffer.isEmpty) {
          _typewriterStreamController.add('Listening to your voice...'.tr);
        }
      } else {
        _activeSpeaker = 'Idle';
        if (_targetAiText.isEmpty && _userTranscriptBuffer.isEmpty) {
          _typewriterStreamController.add('Waiting for voice input.'.tr);
        }
      }

      if (isTurnComplete) {
        _status = 'Response complete. Ask the next thing.'.tr;
      } else if (_isModelResponding) {
        _status = 'My Baby is speaking...'.tr;
      } else if (_isMicStreaming) {
        _status = 'Listening to your voice...'.tr;
      }
    });
  }

  void _appendConversationEntry({
    required String speaker,
    required String text,
    required Color color,
  }) {
    if (text.isEmpty) return;

    _timeline.insert(
      0,
      _TranscriptEntry(
        speaker: speaker,
        text: text,
        color: color,
        timestamp: DateTime.now(),
      ),
    );

    if (_timeline.length > 8) {
      _timeline.removeRange(8, _timeline.length);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _preparePcmAudio() async {
    if (_isPcmAudioReady) {
      return;
    }

    await FlutterPcmSound.setup(
      sampleRate: _pcmPlaybackSampleRate,
      channelCount: 1,
    );
    _isPcmAudioReady = true;
  }

  Future<void> _playAudioChunk(Uint8List bytes) async {
    if (bytes.isEmpty) return;

    if (!_isPcmAudioReady) {
      await _preparePcmAudio();
    }

    final alignedLength = bytes.lengthInBytes - (bytes.lengthInBytes % 2);
    if (alignedLength <= 0) {
      return;
    }

    final pcmBytes = Uint8List.sublistView(bytes, 0, alignedLength);
    await FlutterPcmSound.feed(
      PcmArrayInt16(bytes: ByteData.sublistView(pcmBytes)),
    );
  }

  Future<void> _toggleCameraSharing() async {
    if (_isCameraSharing) {
      await _stopCameraStreaming();
      if (!mounted) return;
      setState(() {
        _isCameraSharing = false;
      });
      return;
    }

    setState(() {
      _isCameraLoading = true;
    });

    try {
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        throw Exception('Camera permission not granted.');
      }

      await _initCameraIfNeeded();
      await _startCameraStreaming();

      if (!mounted) return;
      setState(() {
        _isCameraSharing = true;
      });
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Camera',
        'Unable to start camera sharing: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isCameraLoading = false;
      });
    }
  }

  Future<void> _initCameraIfNeeded() async {
    if (_availableCameras.isEmpty) {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        throw Exception('No camera available on this device.');
      }
    }

    final selectedCamera =
        _availableCameras[_currentCameraIndex % _availableCameras.length];

    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        _cameraController!.description.name == selectedCamera.name &&
        _cameraController!.description.lensDirection ==
            selectedCamera.lensDirection) {
      return;
    }

    final previousController = _cameraController;
    _cameraController = null;
    if (previousController != null) {
      await previousController.dispose();
    }

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _cameraController = controller;
    });
  }

  Future<void> _startCameraStreaming() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _cameraTimer?.cancel();
      _cameraTimer = null;
      return;
    }

    final session = _session;
    final cameraController = _cameraController;
    if (session == null || cameraController == null) return;

    _cameraTimer?.cancel();
    _cameraTimer = Timer.periodic(_cameraFrameInterval, (timer) {
      unawaited(_captureAndSendFrame());
    });
  }

  Future<void> _captureAndSendFrame() async {
    final session = _session;
    final cameraController = _cameraController;
    if (session == null || cameraController == null || !_isCameraSharing) {
      return;
    }
    if (_isCameraCapturing || !cameraController.value.isInitialized) {
      return;
    }

    _isCameraCapturing = true;
    try {
      if (cameraController.value.isTakingPicture) return;

      final XFile file = await cameraController.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        final resizedBytes = await compute(_resizeCapturedFrame, bytes);
        await session.sendVideoRealtime(
          InlineDataPart('image/jpeg', resizedBytes),
        );
      }
    } catch (_) {
      // Ignore intermittent capture failures while the camera warms up.
    } finally {
      _isCameraCapturing = false;
    }
  }

  Future<void> _stopCameraStreaming() async {
    _cameraTimer?.cancel();
    _cameraTimer = null;
  }

  Future<void> _switchCamera() async {
    if (_isCameraLoading || _availableCameras.length < 2) {
      return;
    }

    setState(() {
      _isCameraLoading = true;
    });

    final wasSharing = _isCameraSharing;

    try {
      await _stopCameraStreaming();
      _currentCameraIndex =
          (_currentCameraIndex + 1) % _availableCameras.length;

      final previousController = _cameraController;
      _cameraController = null;
      if (previousController != null) {
        await previousController.dispose();
      }

      await _initCameraIfNeeded();

      if (wasSharing && _isSessionActive) {
        await _startCameraStreaming();
        if (!mounted) return;
        setState(() {
          _isCameraSharing = true;
        });
      }
    } catch (error) {
      if (!mounted) return;
      Get.snackbar(
        'Camera',
        'Unable to switch camera: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isCameraLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(WakelockPlus.disable());
    unawaited(_stopSession(closeSession: true));
    unawaited(_audioChunkSubscription?.cancel());
    unawaited(_voiceErrorSubscription?.cancel());
    _promptController.dispose();
    _scrollController.dispose();
    _cameraController?.dispose();
    _userVisualizer.dispose();
    _aiVisualizer.dispose();
    unawaited(_voiceEngine.shutdownAll());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F1),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor.withOpacity(0.06), // Top-left soft pink
                    _secondaryColor.withOpacity(0.06), // Soft blue
                    _accentColor.withOpacity(0.12), // Light peach
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(),
                Expanded(
                  child: Stack(
                    children: [
                      // Middle Section: Sphere or Full-screen Camera
                      Positioned.fill(
                        child: _isCameraSharing
                            ? _buildCameraFeed()
                            : Center(child: _buildBabySphere()),
                      ),

                      // Subtitles Section (Floating above bottom)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 120,
                        child: _buildStreamingSubtitles(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button: White circle with shadow, dark grey icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF374151), // dark grey
                  size: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: AutoSizeText(
              'Talk to Your Baby'.tr,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937), // dark grey
                letterSpacing: -0.2,
              ),
            ),
          ),
          // Status Chip (LIVE Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color:
                        _isSessionActive ? _primaryColor : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isSessionActive ? 'LIVE'.tr : 'IDLE'.tr,
                  style: GoogleFonts.outfit(
                    color:
                        _isSessionActive ? _primaryColor : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBabySphere() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Outer subtle breathing/glowing ring
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _primaryColor.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryColor.withOpacity(0.24),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.06),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    // center lighter pink
                    _primaryColor,
                    _accentColor, // outer primary color
                  ],
                  center: Alignment.center,
                  radius: 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _isModelResponding
                  ? Lottie.asset(
                      'assets/animations/Baby Speaking F.json',
                      key: const ValueKey('baby_speaking'),
                      animate: true,
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                    )
                  : Lottie.asset(
                      'assets/animations/Baby Non Speaking Final.json',
                      key: const ValueKey('baby_non_speaking'),
                      animate: true,
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 35),
        // Discrete 7-bar voice visualizer centered under the baby container
        SizedBox(
          height: 36,
          width: 90,
          child: ListenableBuilder(
            listenable: Listenable.merge([_aiVisualizer, _userVisualizer]),
            builder: (context, child) {
              final waveform = _isModelResponding
                  ? Uint8List.fromList(_aiVisualizer.value.waveform)
                  : (_isMicStreaming
                      ? Uint8List.fromList(_userVisualizer.value.waveform)
                      : Uint8List(0));
              return CustomPaint(
                painter: BarWavePainter(
                  waveform,
                  _secondaryColor, // Sleek secondary theme color (blue)
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCameraFeed() {
    return Stack(
      children: [
        Positioned.fill(
          child: _cameraController != null &&
                  _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : const Center(child: CircularProgressIndicator()),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
                stops: const [0.0, 0.2, 0.75, 1.0],
              ),
            ),
          ),
        ),
        if (_availableCameras.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    child: InkWell(
                      onTap: _isCameraLoading ? null : _switchCamera,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStreamingSubtitles() {
    final hasContent =
        _liveSubtitle.isNotEmpty && _liveSubtitle != 'Waiting for voice input.';
    final displayText = _isConnecting
        ? _status
        : (hasContent ? _liveSubtitle : 'Waiting for voice input.'.tr);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.06), // themed pink shadow
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _primaryColor.withOpacity(0.24), // themed border tint
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: _primaryColor, // themed sparkles
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnecting
                      ? 'Thinking...'.tr
                      : (_activeSpeaker == 'My Baby'
                          ? 'My Baby'.tr
                          : 'You'.tr),
                  style: GoogleFonts.outfit(
                    color: _primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_isConnecting) ...[
                  const SizedBox(width: 10),
                  const _ThinkingDots(color: _primaryColor),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  child: StreamBuilder<String>(
                    stream: _typewriterStreamController.stream,
                    initialData: _activeSpeaker == 'My Baby' && _targetAiText.isNotEmpty 
                        ? _displayedAiText 
                        : displayText,
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? '',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2D3142), // Dark text
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme, bool isDark) {
    // Left button texts
    final stopSessionText =
        _isSessionActive ? 'Stop Session'.tr : 'Start Talking'.tr;
    final leftParts = stopSessionText.split(' ');
    final leftLine1 = leftParts.isNotEmpty ? leftParts[0] : '';
    final leftLine2 =
        leftParts.length > 1 ? leftParts.sublist(1).join(' ') : '';

    // Right button texts
    final cameraText = _isCameraSharing ? 'Hide Camera'.tr : 'Share Camera'.tr;
    final rightParts = cameraText.split(' ');
    final rightLine1 = rightParts.isNotEmpty ? rightParts[0] : '';
    final rightLine2 =
        rightParts.length > 1 ? rightParts.sublist(1).join(' ') : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: _ActionCapsuleButton(
              labelLine1: leftLine1,
              labelLine2: leftLine2,
              icon: _isSessionActive
                  ? Icons.stop_circle_outlined
                  : Icons.mic_none_outlined,
              color: _isSessionActive
                  ? const Color(0xFFEF5350) // Red stop
                  : _primaryColor, // Primary theme color for start/talk
              onTap: _isConnecting
                  ? null
                  : (_isSessionActive ? _stopSession : _startSession),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ActionCapsuleButton(
              labelLine1: rightLine1,
              labelLine2: rightLine2,
              icon: _isCameraSharing
                  ? Icons.videocam_off_outlined
                  : Icons.videocam_outlined,
              color: _secondaryColor, // Secondary theme color (blue) for camera
              onTap: _isCameraLoading ? null : _toggleCameraSharing,
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List _resizeCapturedFrame(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  final resized = img.copyResize(
    decoded,
    width: 768,
    height: 768,
  );

  return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
}

class GlassBox extends StatelessWidget {
  const GlassBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlowSphere extends StatefulWidget {
  const GlowSphere({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<GlowSphere> createState() => _GlowSphereState();
}

class _GlowSphereState extends State<GlowSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: SpherePainter(_controller.value, widget.accentColor),
        );
      },
    );
  }
}

class SpherePainter extends CustomPainter {
  SpherePainter(this.progress, this.accentColor);
  final double progress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final gradient = RadialGradient(
      colors: [
        accentColor.withOpacity(0.9),
        accentColor.withOpacity(0.65),
        accentColor.withOpacity(0.35),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
      center: Alignment(
        math.cos(progress * 2 * math.pi) * 0.2,
        math.sin(progress * 2 * math.pi) * 0.2,
      ),
    );

    final paint = Paint()
      ..shader =
          gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, radius, paint);

    // Inner highlight
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(
        center + const Offset(-20, -20), radius * 0.4, innerPaint);
  }

  @override
  bool shouldRepaint(SpherePainter oldDelegate) => true;
}

class WaveVisualizer extends StatelessWidget {
  const WaveVisualizer(
      {super.key, required this.waveform, required this.color});
  final Uint8List waveform;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WavePainter(waveform, color),
    );
  }
}

class WavePainter extends CustomPainter {
  WavePainter(this.waveform, this.color);
  final Uint8List waveform;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final samples = waveform.length;
    final step = width / (samples - 1);

    for (var i = 0; i < samples; i++) {
      final x = i * step;
      // Convert PCM byte to normalized value -1.0 to 1.0
      final normalized = (waveform[i] - 128) / 128.0;
      final y = centerY + normalized * (height / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}

class _ActionCapsuleButton extends StatelessWidget {
  const _ActionCapsuleButton({
    required this.labelLine1,
    required this.labelLine2,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String labelLine1;
  final String labelLine2;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFFCF9FC), // extremely light pinkish white at the bottom
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12), // matching soft glow shadow!
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.18), // matching premium border tint!
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelLine1,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1F2937), // sleek dark slate
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      labelLine2,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4B5563), // muted charcoal
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BarWavePainter extends CustomPainter {
  BarWavePainter(this.waveform, this.color);
  final Uint8List waveform;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    const int numBars = 7;
    const double spacing = 6.0;
    final double totalSpacing = spacing * (numBars - 1);
    final double barWidth = (size.width - totalSpacing) / numBars;
    final double centerY = size.height / 2;

    double maxVal = 1.0;
    double totalDev = 0.0;
    if (waveform.isNotEmpty) {
      for (final val in waveform) {
        final dev = (val - 128).abs().toDouble();
        totalDev += dev;
        if (dev > maxVal) {
          maxVal = dev;
        }
      }
    }
    final double avgDev =
        waveform.isNotEmpty ? (totalDev / waveform.length) : 0.0;
    // Quiet threshold to detect actual speaking voice vs static noise
    final bool isSilent = avgDev < 0.8;

    for (int i = 0; i < numBars; i++) {
      double amp = 0.0;
      if (waveform.isNotEmpty && !isSilent) {
        amp = _getAmplitudeForSegment(waveform, i, numBars);
      }

      // Maximize dynamic range by dividing directly by maxVal when active
      double normalized = isSilent ? 0.0 : (amp / maxVal).clamp(0.0, 1.0);

      // Idle height is 6.0, max height is size.height
      const double minBarHeight = 6.0;
      final double maxBarHeight = size.height;

      // Symmetric height scaling so it looks nice and balanced
      double heightScale = 1.0;
      if (i == 0 || i == 6) {
        heightScale = 0.35;
      } else if (i == 1 || i == 5) {
        heightScale = 0.65;
      } else if (i == 2 || i == 4) {
        heightScale = 0.85;
      }

      // If waveform is empty or silent, show tiny resting indicator dots
      final double targetHeight = (waveform.isEmpty || isSilent)
          ? minBarHeight + (4.0 * heightScale)
          : minBarHeight +
              (maxBarHeight - minBarHeight) * normalized * heightScale;

      final double x = i * (barWidth + spacing);
      final double y = centerY - (targetHeight / 2);

      final rect = Rect.fromLTWH(x, y, barWidth, targetHeight);
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color, // e.g. _secondaryColor Color(0xff448AFF)
          _primaryColor, // e.g. _primaryColor Color(0xffFF626F)
        ],
      ).createShader(rect);

      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  double _getAmplitudeForSegment(
      Uint8List waveform, int segment, int totalSegments) {
    if (waveform.isEmpty) return 0.0;
    final int segmentLength = waveform.length ~/ totalSegments;
    if (segmentLength == 0) return 0.0;
    final int start = segment * segmentLength;
    final int end = start + segmentLength;
    double sum = 0.0;
    int count = 0;
    for (int i = start; i < end && i < waveform.length; i++) {
      sum += (waveform[i] - 128).abs();
      count++;
    }
    return count > 0 ? sum / count : 0.0;
  }

  @override
  bool shouldRepaint(BarWavePainter oldDelegate) => true;
}

class _TranscriptEntry {
  _TranscriptEntry({
    required this.speaker,
    required this.text,
    required this.color,
    required this.timestamp,
  });

  final String speaker;
  final String text;
  final Color color;
  final DateTime timestamp;
}

/// AlloBaby's "Baby is thinking..." dots (talk_with_baby_home.dart), shown
/// while the live session connects.
class _ThinkingDots extends StatefulWidget {
  final Color color;
  const _ThinkingDots({required this.color});

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (math.sin((_controller.value * 2 * math.pi) -
                        (delay * math.pi)) +
                    1) /
                2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.3 + (value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
