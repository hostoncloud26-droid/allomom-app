import 'package:flutter/foundation.dart';

import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/services/tts_service.dart';

/// Whether the baby is saying anything anywhere in the app, and the one way to
/// silence her.
///
/// Speech comes out of two places — [TtsService] (AlloBot, the AlloBaby card,
/// library clips) and [BackgroundAudioController]'s bundled clips — so the
/// docked mic, which is what shows and stops it, reads both through here.
class SpeechActivity {
  SpeechActivity._();
  static final SpeechActivity instance = SpeechActivity._();

  final TtsService _tts = TtsService();

  /// Bumped by [stopAll]. Anything that plays a sequence of lines listens and
  /// abandons the rest of it, so a stop means silence rather than "skip to the
  /// next line".
  final ValueNotifier<int> stopRequests = ValueNotifier<int>(0);

  /// True while a line is sounding or its clip is loading.
  bool get isActive {
    if (_tts.isSpeaking || _tts.isGenerating) return true;
    return BackgroundAudioController.isReady &&
        BackgroundAudioController.to.isPlaying.value;
  }

  /// Stops every voice and tells any running sequence to give up.
  Future<void> stopAll() async {
    stopRequests.value++;
    await _tts.stop();
    if (BackgroundAudioController.isReady) {
      await BackgroundAudioController.to.stop();
    }
  }
}
