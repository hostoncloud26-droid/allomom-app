/// Owns the on-device Whisper model: which one, whether it is here yet, and
/// getting it here.
///
/// A port of AlloKonnect's speech controller onto AlloMom's storage. The model
/// is fetched once, in the background, on the first launch that needs it, and
/// loaded on every launch after that — so by the time a mother taps the mic,
/// the words she says never leave the phone.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/features/offline_chatbot/speech/allobot_speech_service.dart';

class AlloBotSpeechModelOption {
  const AlloBotSpeechModelOption({
    required this.id,
    required this.name,
    required this.intelligence,
    required this.downloadSize,
    this.platform = const ['android', 'ios'],
  });

  /// Matches what `whisper_ggml` expects once `whisper-` is stripped.
  final String id;
  final String name;
  final String intelligence;
  final String downloadSize;
  final List<String> platform;

  bool get isSupported {
    if (Platform.isAndroid && platform.contains('android')) return true;
    if (Platform.isIOS && platform.contains('ios')) return true;
    return false;
  }
}

class AlloBotSpeechController extends GetxController {
  static const _kActiveModelId = 'allomom_speech_active_model_id';
  static const _kLocalPath = 'allomom_speech_local_path';

  /// Whisper Base is the single on-device speech model.
  static const String defaultModelId = 'whisper-base';

  static AlloBotSpeechController get instance =>
      Get.isRegistered<AlloBotSpeechController>()
      ? Get.find<AlloBotSpeechController>()
      : Get.put(AlloBotSpeechController(), permanent: true);

  final models = const <AlloBotSpeechModelOption>[
    AlloBotSpeechModelOption(
      id: 'whisper-base',
      name: 'Whisper Base',
      intelligence: 'Balanced · clearer on long sentences',
      downloadSize: '145 MB',
    ),
  ];

  final RxString activeModelId = ''.obs;
  final RxString localPath = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;
  final RxString errorMessage = ''.obs;

  /// True once the model is loaded and a clip can actually be transcribed.
  final RxBool isReady = false.obs;

  List<AlloBotSpeechModelOption> get supportedModels =>
      models.where((model) => model.isSupported).toList(growable: false);

  AlloBotSpeechModelOption? get activeModel =>
      models.firstWhereOrNull((m) => m.id == activeModelId.value);

  bool get hasDownloadedActiveModel =>
      activeModelId.value.isNotEmpty && localPath.value.isNotEmpty;

  /// Whether the mic can be used right now. False while a model is downloading,
  /// which is what greys the centre mic out.
  bool get canListen => hasDownloadedActiveModel && !isDownloading.value;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  /// Restores the choice, loads the model if it is already here, and fetches it
  /// if it is not. Runs on app open, so the mic is ready before it is tapped.
  Future<void> _bootstrap() async {
    await _loadState();

    if (activeModelId.value != defaultModelId) {
      activeModelId.value = defaultModelId;
      localPath.value = '';
      isReady.value = false;
      await _persistState();
    }

    if (hasDownloadedActiveModel) {
      await _loadModel();
      return;
    }

    // Nothing on the phone yet. Fetched in the background.
    unawaited(startDownload());
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      activeModelId.value = prefs.getString(_kActiveModelId) ?? '';
      localPath.value = prefs.getString(_kLocalPath) ?? '';

      // A path that no longer resolves is worse than no path: it would fail at
      // the moment she speaks rather than at launch, when it can be refetched.
      if (localPath.value.isNotEmpty && !File(localPath.value).existsSync()) {
        debugPrint('Speech model missing at ${localPath.value}');
        localPath.value = '';
        downloadProgress.value = 0.0;
      }
    } catch (e) {
      debugPrint('Could not read the speech model settings: $e');
    }
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveModelId, activeModelId.value);
      await prefs.setString(_kLocalPath, localPath.value);
    } catch (e) {
      debugPrint('Could not save the speech model settings: $e');
    }
  }

  Future<void> _loadModel() async {
    if (!hasDownloadedActiveModel) return;
    try {
      await AlloBotSpeechService.instance.init(
        modelId: activeModelId.value,
        modelPath: localPath.value,
      );
      isReady.value = true;
    } catch (e) {
      isReady.value = false;
      debugPrint('Could not load the speech model: $e');
    }
  }

  /// Switches model. The new one is fetched straight away, because a choice
  /// that only takes effect the next time she speaks is a choice that looks
  /// broken.
  Future<void> selectModel(String modelId) async {
    if (modelId == activeModelId.value && hasDownloadedActiveModel) return;
    if (isDownloading.value) return;

    activeModelId.value = modelId;
    localPath.value = '';
    isReady.value = false;
    downloadProgress.value = 0.0;
    await _persistState();
    await startDownload();
  }

  Future<void> startDownload() async {
    if (isDownloading.value) return;

    final model = activeModel;
    if (model == null || !model.isSupported) {
      errorMessage.value = 'That voice model does not run on this phone.';
      return;
    }

    isDownloading.value = true;
    downloadProgress.value = 0.0;
    errorMessage.value = '';

    try {
      final path = await AlloBotSpeechService.instance.downloadModel(
        model.id,
        (progress) => downloadProgress.value = progress,
      );
      if (path.isEmpty) throw Exception('the download produced no file');

      localPath.value = path;
      downloadProgress.value = 1.0;
      await _persistState();
      await _loadModel();
    } catch (e) {
      localPath.value = '';
      errorMessage.value = 'Could not download the voice model: $e';
      debugPrint('Speech model download failed: $e');
      await _persistState();
    } finally {
      isDownloading.value = false;
    }
  }

  /// Forgets the downloaded model, for a phone that needs the space back.
  Future<void> removeDownload() async {
    if (isDownloading.value) return;

    final path = localPath.value;
    localPath.value = '';
    downloadProgress.value = 0.0;
    isReady.value = false;
    await _persistState();

    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Could not delete the speech model: $e');
    }
  }

  /// Where downloaded models live, for showing what is taking up space.
  Future<String> modelsDirectory() async =>
      (await getApplicationDocumentsDirectory()).path;
}
