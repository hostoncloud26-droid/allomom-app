import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:get/get.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

class AlloBotSpeechService extends GetxService {
  static AlloBotSpeechService get instance =>
      Get.isRegistered<AlloBotSpeechService>()
      ? Get.find<AlloBotSpeechService>()
      : Get.put(AlloBotSpeechService(), permanent: true);

  final AudioRecorder _recorder = AudioRecorder();

  /// Where the in-progress push-to-talk recording is being written.
  String? _currentRecordingPath;

  final StreamController<void> _speechStartedController =
      StreamController<void>.broadcast();
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<String> _audioPathController =
      StreamController<String>.broadcast();

  Stream<void> get onSpeechStarted => _speechStartedController.stream;
  Stream<String> get onTranscription => _transcriptionController.stream;
  Stream<String> get onAudioPath => _audioPathController.stream;

  bool _isListening = false;
  DateTime? _recordingStartedAt;

  /// Anything shorter than this is treated as an accidental tap.
  static const Duration _minRecordingDuration = Duration(milliseconds: 500);

  /// A WAV file with nothing but a header carries no audio.
  static const int _wavHeaderBytes = 44;
  String? _currentModelId;
  String? _modelPath;
  Whisper? _whisper;
  bool _isInitializing = false;
  bool _isTranscribing = false;
  Future<void>? _initializingFuture;
  final isReady = false.obs;

  Future<void> init(
      {required String modelId, required String modelPath}) async {
    final sameConfig = _whisper != null &&
        _currentModelId == modelId &&
        _modelPath == modelPath &&
        isReady.value;
    if (sameConfig) {
      return;
    }

    if (_isInitializing) {
      debugPrint('Speech service init already in progress, waiting...');
      final pendingInit = _initializingFuture;
      if (pendingInit != null) {
        await pendingInit;
      }
      return;
    }

    _isInitializing = true;
    _currentModelId = modelId;
    _modelPath = modelPath;

    debugPrint(
        'Initializing AlloBotSpeechService with modelId: $modelId, modelPath: $modelPath');

    _initializingFuture = () async {
      await _disposeWhisperContext(clearConfig: false);

      final mappedId = modelId.replaceAll('whisper-', '');
      final modelType = _getModel(mappedId);
      _whisper = Whisper(model: modelType);

      isReady.value = true;
      debugPrint('AlloBotSpeechService initialized successfully');
    }();

    try {
      await _initializingFuture;
    } finally {
      _isInitializing = false;
      _initializingFuture = null;
    }
  }

  Future<void> _disposeWhisperContext({required bool clearConfig}) async {
    final whisper = _whisper;
    _whisper = null;

    if (whisper != null) {
      try {
        await whisper.dispose();
        debugPrint('Whisper context disposed');
      } catch (e) {
        debugPrint('Whisper dispose warning: $e');
      }
    }

    if (clearConfig) {
      _currentModelId = null;
      _modelPath = null;
      isReady.value = false;
    }
  }

  /// Starts a push-to-talk recording.
  ///
  /// Speech capture used to run through Silero VAD, which owned the mic and
  /// decided on its own when an utterance began and ended. That was removed, so
  /// the caller now delimits the utterance: [startListening] opens the mic and
  /// [stopListening] closes it and emits the clip on [onAudioPath].
  Future<void> startListening() async {
    if (_isListening) {
      debugPrint('Already listening, ignoring startListening call');
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('Microphone permission denied');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path = p.join(
        tempDir.path,
        'allobot_speech_${DateTime.now().microsecondsSinceEpoch}.wav',
      );

      // 16 kHz mono WAV is what Whisper expects.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      _currentRecordingPath = path;
      _recordingStartedAt = DateTime.now();
      _isListening = true;

      // Callers use this to react to the user taking the floor — interrupting
      // TTS playback, for instance.
      _speechStartedController.add(null);
      debugPrint('Recording started at $path');
    } catch (e) {
      _isListening = false;
      _currentRecordingPath = null;
      debugPrint('Error starting recording: $e');
      rethrow;
    }
  }

  /// Stops the recording and publishes the clip on [onAudioPath].
  ///
  /// Clips shorter than [_minRecordingDuration] are dropped: they are almost
  /// always an accidental tap and transcribe to noise.
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    _isListening = false;
    final startedAt = _recordingStartedAt;
    _recordingStartedAt = null;

    try {
      final path = await _recorder.stop() ?? _currentRecordingPath;
      _currentRecordingPath = null;

      if (path == null) {
        debugPrint('Recording stopped but produced no file');
        return;
      }

      final tooShort = startedAt != null &&
          DateTime.now().difference(startedAt) < _minRecordingDuration;
      if (tooShort) {
        debugPrint('Discarding recording shorter than $_minRecordingDuration');
        unawaited(_deleteFile(path));
        return;
      }

      final file = File(path);
      if (!await file.exists() || await file.length() <= _wavHeaderBytes) {
        debugPrint('Discarding empty recording at $path');
        unawaited(_deleteFile(path));
        return;
      }

      debugPrint('Recording saved to $path');
      _audioPathController.add(path);
    } catch (e) {
      _currentRecordingPath = null;
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort — a stray temp file is harmless.
    }
  }

  WhisperModel _getModel(String modelId) {
    return WhisperModel.values.firstWhere(
      (m) => m.name == modelId || m.modelName == modelId,
      orElse: () => WhisperModel.base,
    );
  }

  Future<String> transcribe(String audioPath) async {
    if (_isTranscribing) {
      debugPrint(
          'Transcription skipped because another transcription is in progress');
      return '';
    }

    try {
      if (_modelPath == null || _modelPath!.isEmpty) {
        debugPrint('Transcription failed: Model path is empty or null');
        return '';
      }

      if (!File(_modelPath!).existsSync()) {
        debugPrint('Transcription failed: Model file not found at $_modelPath');
        return '';
      }

      debugPrint(
          'Transcribing audio from: $audioPath with model at: $_modelPath');

      if (_whisper == null) {
        final modelId = _currentModelId;
        if (modelId == null || modelId.isEmpty) {
          debugPrint('Transcription failed: Model id is missing');
          return '';
        }

        debugPrint('Whisper instance missing, re-initializing speech service');
        await init(modelId: modelId, modelPath: _modelPath!);
        if (_whisper == null) {
          debugPrint(
              'Transcription failed: Whisper init did not produce an instance');
          return '';
        }
      }

      _isTranscribing = true;

      final result = await _whisper!.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: 'en',
        ),
        modelPath: _modelPath!,
      );
      final text = result.text.trim();
      debugPrint('Transcription result: "$text"');
      return text;
    } catch (e) {
      debugPrint('Allobot Transcription Error (GGML): $e');
      return '';
    } finally {
      _isTranscribing = false;

      // On iOS, explicitly releasing the native context between requests
      // helps avoid memory growth and context init failures after app resume.
      if (Platform.isIOS) {
        await _disposeWhisperContext(clearConfig: false);
      }
    }
  }

  Future<String> downloadModel(
      String modelId, Function(double) onProgress) async {
    try {
      final mappedId = modelId.replaceAll('whisper-', '');
      final modelType = _getModel(mappedId);

      final url = modelType.modelUri.toString();
      final dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/${modelType.modelName}.bin');

      if (await file.exists()) {
        debugPrint('Model already exists at: ${file.path}');
        onProgress(1.0);
        return file.path;
      }

      debugPrint('Starting download of model from: $url');

      final HttpClient httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 60);

      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to download model: HTTP ${response.statusCode}');
      }

      final int totalBytes = response.contentLength;
      int receivedBytes = 0;

      debugPrint('Downloading model: $totalBytes bytes total');

      final sink = file.openWrite();

      await for (var chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes != -1) {
          onProgress(receivedBytes / totalBytes);
          if (receivedBytes % (1024 * 1024 * 5) == 0) {
            debugPrint(
                'Downloaded: ${(receivedBytes / (1024 * 1024)).toStringAsFixed(2)}MB / ${(totalBytes / (1024 * 1024)).toStringAsFixed(2)}MB');
          }
        }
      }

      await sink.close();
      httpClient.close();

      debugPrint('Download completed. Model saved at: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Allobot Download Error (GGML): $e');
      rethrow;
    }
  }

  @override
  void onClose() {
    unawaited(_disposeWhisperContext(clearConfig: true));
    _recorder.dispose();
    _speechStartedController.close();
    _transcriptionController.close();
    _audioPathController.close();
    super.onClose();
  }
}
