import 'package:flutter/widgets.dart';

import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_catalog.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/speech_activity.dart';
import 'package:allomom/services/screen_voice_hint_service.dart';
import 'package:allomom/services/tts_service.dart';

/// Runs Ask Allo's opening flow on Home, inside the AlloBaby card.
///
/// The same intent Ask Allo opens on ([OfflineChatbotController.initialIntentKey]),
/// traversed by the same engine — conditions, redirects and actions included —
/// but in a session of its own, so nothing lands in the chat transcript and
/// the chat's own flow is left alone. Each step is shown as it is said and the
/// next waits for it, with the step's recording preferred and the server's
/// designed voice taking over when there is none or it will not play. The
/// phone's own voice is never used: a line the server cannot voice stays
/// silent (see [TtsService.speakAndWait]).
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
    line = '';
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

    if (reply == null && targetKey != null && targetKey.isNotEmpty) {
      final audioCtrl = BackgroundAudioController.isReady
          ? BackgroundAudioController.to
          : null;
      var lang = (audioCtrl != null && audioCtrl.languageCode.value.trim().isNotEmpty)
          ? audioCtrl.languageCode.value.trim().toLowerCase()
          : (OfflineChatbotController.instance.langCode.value.trim().isNotEmpty
              ? OfflineChatbotController.instance.langCode.value.trim().toLowerCase()
              : AppLanguage.voiceCachedOrFallback);
      if (lang.isEmpty || lang == 'all') lang = 'en';
      if (lang != 'en' && !NarrationCatalog.hasRecordedAudio(targetKey, lang)) {
        lang = 'en';
      }
      final text = audioCtrl?.textFor(targetKey, lang) ??
          NarrationCatalog.textFor(targetKey, languageCode: lang) ??
          '';
      if (text.isNotEmpty) {
        final url = OfflineChatbotEngine.audioUrlForKey(
          targetKey,
          lang,
        );
        reply = BotReply()
          ..say(text)
          ..addAudio(url)
          ..endStep();
      }
    }

    debugPrint(
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      '👶 [AlloBabyFlowController Start]\n'
      '   📍 Requested Intent Key : "$intentKey"\n'
      '   🎯 Resolved Target Key  : "$targetKey"\n'
      '   💬 Spoken Line          : "${reply?.segments.firstOrNull?.text ?? reply?.segments.firstOrNull?.utterances.firstOrNull?.text}"\n'
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

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
    await _deliver(reply, generation);
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
      designedVoiceOnly: true,
      onFallbackToEnglish: (enText) {
        line = enText;
        notifyListeners();
      },
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
