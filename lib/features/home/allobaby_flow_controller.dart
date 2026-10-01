import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/services/allobot/allobaby_live_session.dart';
import 'package:allomom/services/speech_activity.dart';
import 'package:allomom/services/screen_voice_hint_service.dart';
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
  AlloBabyFlowController() {
    _live.add(this);
  }

  static final Set<AlloBabyFlowController> _live = {};

  /// Stops every card's flow when a page opens over it — including a page the
  /// flow opened itself, since that push does not wait for the page and the
  /// flow would otherwise carry on talking over whatever the page says.
  /// Sheets and dialogs are left alone: a flow's own sheet is her answering
  /// it. Registered in `GetMaterialApp`.
  static final NavigatorObserver observer = _StopOnNewPage();

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

  /// True from a question being asked until the first step of the answer is
  /// on screen, so the card can say it is thinking instead of repeating the
  /// line before.
  bool isThinking = false;

  /// Whether the flow has been started at all this session.
  bool hasRun = false;

  final AlloBabyLiveSession _call = AlloBabyLiveSession.instance;

  /// Whether the card is in a Gemini Live call — a question the catalogue had
  /// no answer for, taken to AlloBaby's Talk to Your Baby call right here.
  bool get isLive => _call.isOwnedBy(this);

  /// Whether the baby's live voice is sounding, so her mouth moves with it.
  bool get isLiveSpeaking => isLive && _call.isBabySpeaking;

  /// Starts the opening flow from the top. Completes once it has been said —
  /// or stopped — so a caller can sequence what comes after it.
  ///
  /// [intentKey] runs that intent instead of the opening one.
  /// If [resolveHint] is true, first visit plays [intentKey], and subsequent visits
  /// play [hintKey] (or auto-derived `_hint` key).
  Future<void> start({
    String? intentKey,
    String? hintKey,
    bool resolveHint = true,
  }) async {
    final generation = ++_generation;
    _claimVoice();
    _session = BotSession();
    hasRun = true;
    options = const [];
    isRunning = true;
    notifyListeners();

    final chatbot = OfflineChatbotController.instance;
    await chatbot.ready;

    String? targetKey = intentKey;
    if (targetKey != null && resolveHint) {
      targetKey = await ScreenVoiceHintService.resolveIntentKey(
        introKey: targetKey,
        hintKey: hintKey,
      );
    }

    var reply = await chatbot.runDetachedTurn(
      session: _session,
      intentKey: targetKey ?? chatbot.initialIntentKey,
    );
    if (reply == null && targetKey != intentKey && intentKey != null) {
      reply = await chatbot.runDetachedTurn(
        session: _session,
        intentKey: intentKey,
      );
    }
    if (generation != _generation) return;
    await _deliver(reply, generation);
  }

  /// Answers the step the flow is waiting on with one of its [options].
  Future<void> answer(String option) async {
    final generation = ++_generation;
    _claimVoice();
    options = const [];
    isRunning = true;
    isThinking = true;
    notifyListeners();

    final reply = await OfflineChatbotController.instance.runDetachedTurn(
      session: _session,
      message: option,
    );
    if (generation != _generation) return;
    // Nothing in the catalogue answers it: the baby keeps thinking while a
    // Gemini Live call connects, then answers in it. Offline, or if the call
    // will not connect, the fallback's own words are said instead.
    if (reply != null &&
        reply.isFallback &&
        ConnectionController.instance.isInternetAvailable &&
        await _goLive(option, generation)) {
      return;
    }
    if (generation != _generation) return;
    await _deliver(reply, generation);
  }

  /// Takes [question] to a Gemini Live call shown in this card. True once the
  /// call is live; the card follows it until it ends.
  Future<bool> _goLive(String question, int generation) async {
    _joiningLive = true;
    _call.addListener(_onLiveChanged);
    final live = await _call.start(owner: this, question: question);
    _joiningLive = false;
    if (!live || generation != _generation) {
      _call.removeListener(_onLiveChanged);
      return false;
    }
    _onLiveChanged();
    return true;
  }

  /// While [_goLive] waits on the call: the session clears whatever call came
  /// before, and that is not this card's call ending.
  bool _joiningLive = false;

  /// Mirrors the call into the card: what the baby is saying while it is on,
  /// and the card handed back once it ends — hung up, failed or taken over.
  void _onLiveChanged() {
    if (_joiningLive) return;
    if (_call.isOwnedBy(this)) {
      if (_call.isConnecting) return;
      isThinking = false;
      line = _call.line;
      notifyListeners();
      return;
    }
    _call.removeListener(_onLiveChanged);
    if (!isRunning) return;
    _generation++;
    SpeechActivity.instance.release(this);
    isRunning = false;
    isThinking = false;
    notifyListeners();
  }

  /// Silences the card and abandons the rest of the turn.
  Future<void> stop() async {
    _abandon();
    await _tts.stop();
  }

  /// Drops the rest of the turn, leaving the voice alone. True if a turn was
  /// running.
  bool _abandon() {
    _generation++;
    _call.removeListener(_onLiveChanged);
    unawaited(_call.stop(owner: this));
    SpeechActivity.instance.release(this);
    final wasRunning = isRunning;
    isRunning = false;
    isThinking = false;
    if (wasRunning) notifyListeners();
    return wasRunning;
  }

  /// Takes the voice for this turn. Whoever takes it next — AlloBot in Ask
  /// Allo or Chat — ends this turn; the voice itself is theirs to stop, and
  /// stopping it here could cut off their first line.
  void _claimVoice() => SpeechActivity.instance.claim(this, _abandon);

  @override
  void dispose() {
    _live.remove(this);
    _abandon();
    super.dispose();
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
        // Each action runs right after the line it follows, not once the
        // whole segment has been said — see [BotSegment.actionsAt].
        if (!await _runActionsAt(segment, 0, generation)) return;
        for (var i = 0; i < segment.utterances.length; i++) {
          final utterance = segment.utterances[i];
          if (!utterance.isEmpty) {
            final text = utterance.text.trim();
            if (text.isNotEmpty) {
              line = text;
              isThinking = false;
              notifyListeners();
            }
            await _say(text, utterance.audioUrl);
            if (generation != _generation) return;
          }
          if (!await _runActionsAt(segment, i + 1, generation)) return;
        }
      }
      options = reply.options;
    } finally {
      if (generation == _generation) {
        SpeechActivity.instance.release(this);
        isRunning = false;
        isThinking = false;
        notifyListeners();
      }
    }
  }

  /// Runs the actions queued after [count] of [segment]'s lines. False when
  /// the run was stopped or superseded meanwhile — a sheet waits on her, so
  /// that can happen while one is open.
  Future<bool> _runActionsAt(
    BotSegment segment,
    int count,
    int generation,
  ) async {
    final actions = segment.actionsAt(count);
    if (actions.isEmpty) return true;
    await OfflineChatbotController.instance.runDetachedActions(
      actions,
      session: _session,
    );
    return generation == _generation;
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
    final lang = (BackgroundAudioController.isReady &&
            BackgroundAudioController.to.languageCode.value.isNotEmpty)
        ? BackgroundAudioController.to.languageCode.value
        : OfflineChatbotController.instance.langCode.value.trim();
    await _tts.speakAndWait(
      text,
      audioUrl: OfflineChatbotController.resolveAudioUrl(audioUrl),
      language: lang.isEmpty || lang == 'all' ? null : lang,
    );
  }
}

class _StopOnNewPage extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute) return;
    for (final flow in AlloBabyFlowController._live) {
      if (flow.isRunning) flow.stop();
    }
  }
}
