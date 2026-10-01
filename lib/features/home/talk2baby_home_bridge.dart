import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

/// The AlloBaby card on Home, as a view onto Talk2Baby's own conversation.
///
/// Not a flow of its own: the opening intent, the questions asked from Home
/// and the answers to its options all run in [OfflineChatbotController]'s
/// session and land in its transcript, so a conversation started on Home
/// carries on in Talk2Baby and the other way round. What the card shows —
/// the line being said, "Thinking…" while its voice is fetched, the
/// `ai_speaking_delay` line when that takes long — is read from the same
/// controller Ask Allo reads it from.
///
/// Mirrors the parts of [AlloBabyFlowController] Home uses, which the auth,
/// register and AlloCry pages keep using for their own screen intents.
class Talk2BabyHomeBridge extends ChangeNotifier {
  Talk2BabyHomeBridge() {
    _live.add(this);
    final chatbot = OfflineChatbotController.instance;
    _workers.addAll([
      ever<String?>(chatbot.currentLine, (_) => notifyListeners()),
      ever<String?>(chatbot.delayLine, (_) => notifyListeners()),
      ever<bool>(chatbot.isTyping, (_) => notifyListeners()),
      ever<bool>(chatbot.isBusy, (_) => _onBusyChanged()),
      ever<bool>(chatbot.isVoicePending, (_) => notifyListeners()),
      ever<List<String>>(chatbot.activeOptions, (_) => notifyListeners()),
    ]);
  }

  static final Set<Talk2BabyHomeBridge> _live = {};

  /// Stops a turn Home started when a page opens over it — a page the flow
  /// opened itself included, since that push does not wait for the page. A
  /// turn started in Talk2Baby is left alone. Registered in `GetMaterialApp`.
  static final NavigatorObserver observer = _StopOnNewPage();

  final List<Worker> _workers = [];

  /// Whether the turn under way was started from Home.
  bool _ownsTurn = false;

  OfflineChatbotController get _chatbot => OfflineChatbotController.instance;

  /// The line on screen: what fills a slow voice while it plays, else the
  /// line being said, else the last thing the baby said.
  String get line {
    final delay = _chatbot.delayLine.value?.trim() ?? '';
    if (delay.isNotEmpty) return delay;
    final current = _chatbot.currentLine.value?.trim() ?? '';
    if (current.isNotEmpty) return current;
    for (final message in _chatbot.messages.reversed) {
      if (!message.fromUser && !message.isSystem && message.text.isNotEmpty) {
        return message.text.trim();
      }
    }
    return '';
  }

  /// The choices the conversation is waiting on, once it has been said.
  List<String> get options =>
      isRunning ? const [] : _chatbot.activeOptions.toList();

  /// Whether a turn is being worked out or said.
  bool get isRunning => _chatbot.isBusy.value;

  /// Nothing to show yet — the turn has said nothing so far, or its line is
  /// waiting on its voice with no delay line to fill the gap.
  bool get isThinking =>
      _chatbot.isTyping.value ||
      (_chatbot.isVoicePending.value && _chatbot.delayLine.value == null);

  /// Opens Talk2Baby's conversation on Home, out loud. Leaves a flow waiting
  /// on her answer where it is, as Ask Allo does.
  Future<void> start() async {
    _ownsTurn = true;
    await _chatbot.openConversation(recordedOnly: false);
    // A flow left waiting on her answer is not reopened, so nothing ran.
    if (!isRunning) _ownsTurn = false;
  }

  /// Asks [text] in the shared conversation — a question, or one of
  /// [options] — and has the answer read out.
  Future<void> answer(String text) async {
    _ownsTurn = true;
    notifyListeners();
    await _chatbot.send(text, speak: true);
  }

  /// Silences the card and abandons the turn under way.
  Future<void> stop() async {
    _ownsTurn = false;
    await _chatbot.stopCurrentTurn();
  }

  void _onBusyChanged() {
    if (!_chatbot.isBusy.value) _ownsTurn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _live.remove(this);
    for (final worker in _workers) {
      worker.dispose();
    }
    super.dispose();
  }
}

class _StopOnNewPage extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute) return;
    for (final bridge in Talk2BabyHomeBridge._live) {
      if (bridge._ownsTurn && bridge.isRunning) unawaited(bridge.stop());
    }
  }
}
