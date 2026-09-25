import 'package:flutter/foundation.dart';

import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/services/tts_service.dart';

/// Runs Ask Allo's opening flow on Home, inside the AlloBaby card.
///
/// The same intent Ask Allo opens on ([OfflineChatbotController.initialIntentKey]),
/// traversed by the same engine — conditions, redirects and actions included —
/// but in a session of its own, so nothing lands in the chat transcript and
/// the chat's own flow is left alone. Each step is shown as it is said and the
/// next waits for it, with the step's recording preferred and the device voice
/// taking over when the clip will not play (see [TtsService.speakAndWait]).
class AlloBabyFlowController extends ChangeNotifier {
  final TtsService _tts = TtsService();
  BotSession _session = BotSession();

  /// Bumped whenever a run is superseded or stopped; a delivery that finds it
  /// changed abandons the rest of its turn.
  int _generation = 0;

  /// The step on screen — what the baby is saying, or said last.
  String line = '';

  /// The choices the flow is waiting on, once it has finished speaking.
  List<String> options = const [];

  bool isRunning = false;

  /// Whether the flow has been started at all this session.
  bool hasRun = false;

  /// Starts the opening flow from the top. Completes once it has been said —
  /// or stopped — so a caller can sequence what comes after it.
  Future<void> start() async {
    final generation = ++_generation;
    _session = BotSession();
    hasRun = true;
    options = const [];
    isRunning = true;
    notifyListeners();

    final chatbot = OfflineChatbotController.instance;
    await chatbot.ready;
    final reply = await chatbot.runDetachedTurn(
      session: _session,
      intentKey: chatbot.initialIntentKey,
    );
    if (generation != _generation) return;
    await _deliver(reply, generation);
  }

  /// Answers the step the flow is waiting on with one of its [options].
  Future<void> answer(String option) async {
    final generation = ++_generation;
    options = const [];
    isRunning = true;
    notifyListeners();

    final reply = await OfflineChatbotController.instance.runDetachedTurn(
      session: _session,
      message: option,
    );
    if (generation != _generation) return;
    await _deliver(reply, generation);
  }

  /// Silences the card and abandons the rest of the turn.
  Future<void> stop() async {
    _generation++;
    final wasRunning = isRunning;
    isRunning = false;
    if (wasRunning) notifyListeners();
    await _tts.stop();
  }

  Future<void> _deliver(BotReply? reply, int generation) async {
    try {
      if (reply == null) return;
      for (final segment in reply.segments) {
        if (segment.delay > 0) {
          await Future.delayed(
            Duration(milliseconds: (segment.delay * 1000).round()),
          );
          if (generation != _generation) return;
        }
        for (final utterance in segment.utterances) {
          if (utterance.isEmpty) continue;
          final text = utterance.text.trim();
          if (text.isNotEmpty) {
            line = text;
            notifyListeners();
          }
          await _say(text, utterance.audioUrl);
          if (generation != _generation) return;
        }
      }
      options = reply.options;
    } finally {
      if (generation == _generation) {
        isRunning = false;
        notifyListeners();
      }
    }
  }

  /// Reads one step aloud, or gives it a reading pause when the voice is off,
  /// so the steps still arrive one at a time.
  Future<void> _say(String text, String? audioUrl) async {
    final voiceOn =
        !BackgroundAudioController.isReady ||
        BackgroundAudioController.to.isVoiceEnabled.value;
    if (!voiceOn) {
      if (text.isEmpty) return;
      final words = text.split(RegExp(r'\s+')).length;
      await Future.delayed(
        Duration(milliseconds: (words * 180).clamp(900, 4000)),
      );
      return;
    }
    final lang = OfflineChatbotController.instance.langCode.value.trim();
    await _tts.speakAndWait(
      text,
      audioUrl: OfflineChatbotController.resolveAudioUrl(audioUrl),
      language: lang.isEmpty || lang == 'all' ? null : lang,
    );
  }
}
