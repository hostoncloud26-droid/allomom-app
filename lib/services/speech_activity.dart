import 'package:flutter/foundation.dart';

import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/services/allobot/allobaby_live_session.dart';
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

  Object? _owner;
  VoidCallback? _onLost;

  /// Takes the baby's voice for [who], a sequence about to say something.
  ///
  /// Every voice here comes out of one [TtsService], and each line it starts
  /// cuts off the last — which releases whichever sequence was waiting on that
  /// line, so it said its next one and cut back in. Two flows running at once
  /// took turns talking over each other. Claiming first means the one that
  /// held the voice is told to give up its whole turn ([onLost]), not just
  /// the line that was cut.
  void claim(Object who, VoidCallback onLost) {
    final previous = _owner;
    final lost = _onLost;
    _owner = who;
    _onLost = onLost;
    if (previous != null && !identical(previous, who)) lost?.call();
  }

  /// Gives the voice back once [who] has finished, so a later claim does not
  /// stop a sequence that is no longer running.
  void release(Object who) {
    if (!identical(_owner, who)) return;
    _owner = null;
    _onLost = null;
  }

  /// True while a line is sounding or its clip is loading.
  bool get isActive {
    if (_tts.isSpeaking || _tts.isGenerating) return true;
    // A Gemini Live call counts the whole time it is open: the mic is how she
    // hangs up.
    if (AlloBabyLiveSession.instance.isOn) return true;
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
