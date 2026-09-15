import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/allocry/data/cry_data.dart';
import 'package:allomom/features/allocry/data/cry_record.dart';
import 'package:allomom/features/allocry/service/cry_audio_classifier.dart';
import 'package:allomom/features/allocry/service/cry_audio_store.dart';

/// What the recorder is doing right now.
enum CryListeningState { idle, loadingModel, listening, analyzing }

/// How a listening session ended.
///
/// The rolling analysis can finish a session by itself — the moment it hears a
/// cry, or when the listening window runs out — so the screen cannot simply
/// await the tap that started it. It watches [CryController.sessionResult]
/// for one of these instead.
class CrySessionResult {
  /// The saved reading, or null when no cry was heard.
  final CryRecord? record;

  const CrySessionResult(this.record);

  bool get heardACry => record != null;
}

/// Drives one AlloCry session: load the models, listen, decide, write it down.
///
/// The recorder writes a rolling WAV and every few seconds the clip so far is
/// handed to the on-device models. That gives the mother live feedback — "move
/// closer", "please don't talk", "baby cry detected" — instead of a blank
/// screen, and it means the moment a cry is heard the session can finish on
/// its own. Nothing is uploaded: both the audio and the verdict stay on the
/// phone, the reading landing in the local `cry` vitals stream.
class CryController extends GetxController {
  static CryController get instance => Get.isRegistered<CryController>()
      ? Get.find<CryController>()
      : Get.put(CryController(), permanent: true);

  /// How often the rolling clip is re-analysed while she records.
  static const int _analyseEverySeconds = 7;

  /// Give up after this long with no cry heard.
  static const int _maxListenSeconds = 22;

  /// The recorder's format. YAMNet was trained on 16kHz mono PCM; anything
  /// else would have to be resampled before it could be scored.
  static const RecordConfig _recordConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    numChannels: 1,
    sampleRate: 16000,
  );

  final CryAudioClassifier _classifier = CryAudioClassifier();
  final _uuid = const Uuid();

  AudioRecorder? _recorder;
  Timer? _ticker;
  bool _analysing = false;
  bool _finished = false;

  // ─── Observable session state ───────────────────────────────────────────

  final Rx<CryListeningState> state = CryListeningState.idle.obs;

  /// Seconds recorded so far.
  final RxInt elapsedSeconds = 0.obs;

  /// The live coaching line under the animation.
  final RxString statusMessage = 'Getting your baby sound…'.obs;

  /// True once YAMNet has heard a cry in the rolling clip.
  final RxBool cryHeard = false.obs;

  /// Set when the models could not be loaded at all.
  final RxString modelError = ''.obs;

  /// Emitted once, when a session ends on its own. Cleared at the start of
  /// each session so a stale result cannot navigate the next one away.
  final Rxn<CrySessionResult> sessionResult = Rxn<CrySessionResult>();

  bool get isListening => state.value == CryListeningState.listening;
  bool get isModelReady => _classifier.isReady;

  @override
  void onClose() {
    _ticker?.cancel();
    _recorder?.dispose();
    _classifier.dispose();
    super.onClose();
  }

  /// Loads both TFLite graphs. Safe to call repeatedly; only the first does
  /// work. The 15MB YAMNet graph takes a moment, hence the explicit state.
  Future<bool> loadModel() async {
    if (_classifier.isReady) return true;
    state.value = CryListeningState.loadingModel;
    modelError.value = '';
    try {
      await _classifier.initialize();
      state.value = CryListeningState.idle;
      return true;
    } catch (e) {
      debugPrint('⚠️ [CryController] model load failed: $e');
      modelError.value = 'AlloCry could not start its listening model.';
      state.value = CryListeningState.idle;
      return false;
    }
  }

  /// Starts a listening session. Returns false when the microphone is
  /// unavailable, which the recording screen turns into a permission prompt.
  Future<bool> startListening() async {
    if (isListening) return true;
    if (!await loadModel()) return false;

    _finished = false;
    _analysing = false;
    sessionResult.value = null;
    cryHeard.value = false;
    elapsedSeconds.value = 0;
    statusMessage.value = 'Getting your baby sound…';

    final recorder = AudioRecorder();
    _recorder = recorder;

    if (!await recorder.hasPermission()) {
      await _disposeRecorder();
      return false;
    }

    await recorder.start(_recordConfig, path: await _nextClipPath());
    state.value = CryListeningState.listening;

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    return true;
  }

  /// Stops recording without analysing — she tapped cancel or left the screen.
  Future<void> cancelListening() async {
    _finished = true;
    _ticker?.cancel();
    await _disposeRecorder();
    state.value = CryListeningState.idle;
  }

  Future<void> _onTick() async {
    if (_finished) return;
    elapsedSeconds.value++;

    if (elapsedSeconds.value >= _maxListenSeconds) {
      await _finishWithNoCry();
      return;
    }

    // Re-score the clip so far every few seconds. Skipped while a previous
    // pass is still running so a slow phone queues up work it cannot finish.
    if (elapsedSeconds.value % _analyseEverySeconds == 0 && !_analysing) {
      await _analyseRollingClip();
    }
  }

  /// Stops the recorder, scores what it captured, and restarts it so the
  /// session continues seamlessly if no cry was found yet.
  Future<void> _analyseRollingClip() async {
    final recorder = _recorder;
    if (recorder == null || _finished) return;

    _analysing = true;
    try {
      final path = await recorder.stop();
      if (path == null || _finished) return;

      final analysis = await _classifier.analyze(path);
      if (_finished) return;

      _applyCoaching(analysis);

      if (analysis.cryDetected) {
        await _finishWithCry(analysis);
        return;
      }

      // No cry yet — keep listening into a fresh clip.
      await recorder.start(_recordConfig, path: await _nextClipPath());
    } catch (e) {
      debugPrint('⚠️ [CryController] rolling analysis failed: $e');
    } finally {
      _analysing = false;
    }
  }

  /// Turns YAMNet's labels into the line she reads while recording.
  void _applyCoaching(CryAnalysis analysis) {
    final labels = analysis.soundLabels;

    if (analysis.cryDetected) {
      cryHeard.value = true;
      statusMessage.value = 'Baby cry detected.';
    } else if (labels.contains('Silence')) {
      statusMessage.value = 'Please move closer to your baby.';
    } else if (labels.contains('Speech')) {
      statusMessage.value = "Please don't talk while recording.";
    } else {
      statusMessage.value = 'Listening for your baby…';
    }
  }

  /// Ends the session on a cry: score the final clip, keep the audio, and
  /// write the reading into the vitals stream.
  Future<CryRecord?> _finishWithCry(CryAnalysis analysis) async {
    _finished = true;
    _ticker?.cancel();
    state.value = CryListeningState.analyzing;

    final seconds = elapsedSeconds.value;
    await _disposeRecorder();

    final record = await saveReading(
      analysis: analysis,
      durationSeconds: seconds,
    );

    state.value = CryListeningState.idle;
    sessionResult.value = CrySessionResult(record);
    return record;
  }

  /// The listening window ran out without a cry. Nothing is written — a
  /// reading she cannot hear a cry in is not worth keeping.
  Future<void> _finishWithNoCry() async {
    _finished = true;
    _ticker?.cancel();
    await _disposeRecorder();
    state.value = CryListeningState.idle;
    cryHeard.value = false;
    sessionResult.value = const CrySessionResult(null);
  }

  /// She tapped stop: score whatever has been captured and end the session.
  ///
  /// The outcome is published to [sessionResult] rather than returned, so this
  /// and the rolling analysis share one path to the screen. A tap that lands
  /// while a rolling pass is still in flight waits for it — that pass may have
  /// already found the cry, and stopping the recorder underneath it would lose
  /// the clip it is holding.
  Future<void> stopAndAnalyze() async {
    await _awaitRollingPass();
    if (_finished) return;

    final recorder = _recorder;
    if (recorder == null) return;

    _finished = true;
    _ticker?.cancel();
    state.value = CryListeningState.analyzing;

    final seconds = elapsedSeconds.value;
    try {
      final path = await recorder.stop();
      await _disposeRecorder();

      CryRecord? record;
      if (path != null) {
        final analysis = await _classifier.analyze(path);
        _applyCoaching(analysis);
        if (analysis.cryDetected) {
          record = await saveReading(
            analysis: analysis,
            durationSeconds: seconds,
          );
        }
      }

      state.value = CryListeningState.idle;
      sessionResult.value = CrySessionResult(record);
    } catch (e) {
      debugPrint('⚠️ [CryController] stopAndAnalyze failed: $e');
      await _disposeRecorder();
      state.value = CryListeningState.idle;
      sessionResult.value = const CrySessionResult(null);
    }
  }

  /// Waits out an in-flight rolling analysis, capped so a wedged pass cannot
  /// leave the Stop button dead.
  Future<void> _awaitRollingPass() async {
    for (int i = 0; i < 100 && _analysing; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Keeps the recording and writes the reading into the `cry` vitals stream.
  ///
  /// The audio is copied out of the recorder's scratch file first: if that
  /// fails the reading is still saved, just without a clip to play back.
  Future<CryRecord?> saveReading({
    required CryAnalysis analysis,
    required int durationSeconds,
  }) async {
    final cryType = analysis.cryType ?? 'Unknown Cry';
    final clipId = _uuid.v7();
    final audioFile = await CryAudioStore.persist(analysis.audioPath, clipId);

    final data = CryRecord.toVitalData(
      cryType: cryType,
      confidence: analysis.confidence,
      cryDetected: analysis.cryDetected,
      audioFile: audioFile,
      soundLabels: analysis.soundLabels,
      durationSeconds: durationSeconds,
    );

    final vital = await HealthVitalsController.instance.addCryEntry(
      cryCode: CryRecord.codeFor(cryType),
      data: data,
      createdAt: DateTime.now(),
    );

    if (vital == null) {
      debugPrint('⚠️ [CryController] cry vital was not written');
      return null;
    }
    return CryRecord.fromVital(vital);
  }

  /// Frees the two interpreters and the scratch clips when she leaves
  /// AlloCry. The 15MB YAMNet graph is not worth holding for a feature that
  /// is not on screen; the home page loads it again on the way back in.
  Future<void> releaseModel() async {
    await cancelListening();
    _classifier.dispose();
    await clearScratchClips();
  }

  // ─── History ────────────────────────────────────────────────────────────

  /// Every reading she has taken, newest first.
  List<CryRecord> history() {
    final vitals = HealthVitalsController.instance.getHistory(
      CryRecord.vitalKey,
    );
    final records = vitals.map(CryRecord.fromVital).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return records;
  }

  /// Reloads the vitals stream from the local database.
  Future<void> refreshHistory() =>
      HealthVitalsController.instance.fetchLatestVitals(showLoading: false);

  /// Removes a reading and the recording behind it.
  Future<void> deleteRecord(CryRecord record) async {
    await HealthVitalsController.instance.deleteVital(
      record.id,
      createdAt: record.recordedAt,
    );
    await CryAudioStore.delete(record.audioFile);
    await refreshHistory();
  }

  /// How many times each cry type has come up, for the history summary.
  Map<String, int> typeBreakdown(List<CryRecord> records) {
    final counts = <String, int>{};
    for (final record in records) {
      counts[record.cryType] = (counts[record.cryType] ?? 0) + 1;
    }
    return Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Everything AlloCry can say about a cry type id.
  CryType describe(String cryType) => CryTypes.resolve(cryType);

  // ─── Internals ──────────────────────────────────────────────────────────

  /// A fresh scratch path per clip. Reusing one name across the session made
  /// the recorder append to a file the classifier was still reading.
  Future<String> _nextClipPath() async {
    final dir = await getTemporaryDirectory();
    return p.join(dir.path, 'allocry_${_uuid.v7()}.wav');
  }

  Future<void> _disposeRecorder() async {
    final recorder = _recorder;
    _recorder = null;
    if (recorder == null) return;
    try {
      if (await recorder.isRecording()) await recorder.stop();
      await recorder.dispose();
    } catch (e) {
      debugPrint('⚠️ [CryController] recorder cleanup: $e');
    }
  }

  /// Clears the scratch WAVs a session leaves in the temp directory. The kept
  /// recordings live in `CryAudioStore` and are untouched.
  Future<void> clearScratchClips() async {
    try {
      final dir = await getTemporaryDirectory();
      await for (final entity in dir.list()) {
        if (entity is File && p.basename(entity.path).startsWith('allocry_')) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CryController] scratch cleanup: $e');
    }
  }
}
