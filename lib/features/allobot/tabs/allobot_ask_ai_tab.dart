/// Ask Allo — every turn answered by the intent catalogue on this device.
///
/// A port of AlloKonnect's "Ask AI" page: the downloaded bot definition is
/// matched and its flow graph walked locally, so a conversation costs no
/// network at all. The two views are AlloKonnect's — a voice landing view and
/// the full transcript — with one substitution: where AlloKonnect shows a round
/// AlloBot avatar, AlloMom shows the baby, who mouths the words while the reply
/// is being read out.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/widgets/allobot_voice_popup.dart';
import 'package:allomom/features/offline_chatbot/widgets/offline_chat_widgets.dart';

class AlloBotAskAiTab extends StatefulWidget {
  final VoidCallback onOpenChat;
  final bool initialListening;
  final ValueChanged<bool>? onListeningChanged;

  const AlloBotAskAiTab({
    super.key,
    required this.onOpenChat,
    this.initialListening = false,
    this.onListeningChanged,
  });

  @override
  State<AlloBotAskAiTab> createState() => AlloBotAskAiTabState();
}

class AlloBotAskAiTabState extends State<AlloBotAskAiTab> {
  final OfflineChatbotController controller = OfflineChatbotController.instance;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  /// Voice landing view, or the full transcript. AlloKonnect's own toggle.
  bool _showListView = false;

  /// Whether the voice popup is open, so the page's mic can show that the
  /// phone is listening.
  bool _isListening = false;

  /// The chips shown before she has said anything. Drawn once from the
  /// catalogue so they do not reshuffle on every rebuild.
  List<String> _openingSuggestions = const [];

  @override
  void initState() {
    super.initState();
    _openingSuggestions = _drawOpeningSuggestions();

    if (widget.initialListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) => startListening());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── Sending ──────────────────────────────────────────────────────────────

  void _send([String? text]) {
    final message = (text ?? _input.text).trim();
    if (message.isEmpty) return;
    _input.clear();
    controller.send(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ── Voice ────────────────────────────────────────────────────────────────
  //
  // Every turn spoken goes through the popup, the way AlloKonnect does it: the
  // page's mic opens the sheet, the sheet owns the recogniser, and it closes
  // itself once it has something to send. [startListening] and
  // [toggleListening] stay public because the docked mic drives them.

  Future<void> startListening() async {
    if (_isListening) return;
    // Whatever the baby is still saying belongs to the previous turn.
    await controller.stopCurrentTurn();
    if (!mounted) return;

    _setListening(true);
    await AlloBotVoicePopup.show(
      context,
      controller: controller,
      onTopicsRequested: _showTopicsSheet,
      onEnableKeyboardMode: () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _inputFocus.requestFocus(),
        );
      },
    );
    // `show` completes when the sheet closes, however it was closed.
    _setListening(false);
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    _setListening(false);
  }

  void toggleListening() {
    if (_isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  void _setListening(bool value) {
    if (_isListening != value && mounted) {
      setState(() => _isListening = value);
    } else {
      _isListening = value;
    }
    widget.onListeningChanged?.call(value);
  }

  // ── Suggestions ──────────────────────────────────────────────────────────

  /// Trigger phrases from the downloaded catalogue, falling back to a curated
  /// pool while nothing has been downloaded yet.
  List<String> _drawOpeningSuggestions() {
    final triggers = controller.sampleTriggers(limit: 6, randomize: true);
    if (triggers.length >= 3) return triggers;

    final pool = <String>[
      'How is my baby this week?',
      'What should I eat today?',
      'Show my health vitals',
      'When is my next checkup?',
      'Open my reports',
      'My baby is kicking',
      'My baby is crying',
      'What can you do?',
    ]..shuffle();
    return pool.take(6).toList();
  }

  /// What to offer right now: the live quick replies of the step a flow is
  /// waiting on, or the opening suggestions while nothing is in progress.
  List<String> _currentSuggestions() {
    if (controller.activeOptions.isNotEmpty) {
      return controller.activeOptions.toList();
    }
    if (_openingSuggestions.isEmpty) {
      _openingSuggestions = _drawOpeningSuggestions();
    }
    return _openingSuggestions;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopAppBar(),
            Expanded(
              child: _showListView ? _buildTranscriptView() : _buildVoiceView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP APP BAR ───
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              controller.stopCurrentTurn();
              Navigator.maybePop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFFFF4E6A),
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'AlloBot',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
                Text(
                  'Your empathetic pregnancy companion',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
          ),
          _circleButton(
            icon: _showListView
                ? Icons.graphic_eq_rounded
                : Icons.format_list_bulleted_rounded,
            tooltip: _showListView ? 'Voice view' : 'Full conversation',
            onTap: () => setState(() => _showListView = !_showListView),
          ),
          const SizedBox(width: 8),
          Obx(
            () => _circleButton(
              icon: Icons.more_vert_rounded,
              tooltip: 'More',
              busy: controller.isSyncing.value,
              onTap: _showMenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool busy = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                )
              : Icon(icon, color: const Color(0xFFFF4E6A), size: 20),
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_comment_outlined,
                  color: primaryColor),
              title: const Text('New conversation'),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.createNewChat();
                setState(() => _openingSuggestions = _drawOpeningSuggestions());
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined,
                  color: primaryColor),
              title: const Text('Sync AlloBot'),
              subtitle: const Text('Download the latest topics and flows'),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.sync().then((_) {
                  if (mounted) {
                    setState(
                      () => _openingSuggestions = _drawOpeningSuggestions(),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum_outlined, color: primaryColor),
              title: const Text('Open chat'),
              onTap: () {
                Navigator.pop(sheetContext);
                widget.onOpenChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: dangerRed),
              title: const Text(
                'Clear downloaded topics',
                style: TextStyle(color: dangerRed),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.clearCache();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── VOICE VIEW ───

  Widget _buildVoiceView() {
    return Obx(() {
      final isTyping = controller.isTyping.value;
      final isSpeaking = controller.isSpeaking.value;

      // The latest thing the bot said, which is what the card below the baby
      // shows. A fresh conversation falls back to the greeting, so the card is
      // never blank.
      OfflineChatMessage? latest;
      for (var i = controller.messages.length - 1; i >= 0; i--) {
        final message = controller.messages[i];
        if (!message.fromUser && !message.isSystem && message.text.isNotEmpty) {
          latest = message;
          break;
        }
      }

      final suggestions = _currentSuggestions();

      return Column(
        children: [
          // ── 1. The baby, mouthing the reply while it is read out ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BabyHeroBanner(
              height: 240,
              speechText: _bubbleText(),
              speakingOverride: isSpeaking,
              bubblePosition: SpeechBubblePosition.topCenter,
            ),
          ),
          const SizedBox(height: 10),

          // ── 2. The latest reply, and the chips that follow from it ──
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildReplyCard(latest, isTyping),
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSuggestionStrip(suggestions),
                ],
                const SizedBox(height: 8),

                // ── 3. Keyboard composer, or the voice bar's two controls ──
                // Keyboard mode swaps in the composer; otherwise nothing but
                // room for the docked mic, which is where voice lives.
                if (controller.isKeyboardMode.value)
                  OfflineChatbotComposer(
                    input: _input,
                    focusNode: _inputFocus,
                    onSend: _send,
                    controller: controller,
                    onMicTap: () {
                      HapticFeedback.mediumImpact();
                      controller.isKeyboardMode.value = false;
                      _inputFocus.unfocus();
                      startListening();
                    },
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// What the baby's bubble says.
  ///
  /// Her greeting, or that she is listening — the words being recognised show
  /// inside the voice popup, which is over this card while it is open. The
  /// reply itself belongs in the card below: the bubble is a fixed shape over
  /// the illustration.
  String _bubbleText() {
    if (_isListening) return 'I am listening, Amma…';
    return controller.greetingLine().split('\n').first;
  }

  Widget _buildReplyCard(OfflineChatMessage? message, bool isTyping) {
    final text = (message?.text ?? '').trim().isEmpty
        ? controller.greetingLine()
        : message!.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF2E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isTyping
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OfflineChatbotTypingBubble(),
                const SizedBox(width: 10),
                Text(
                  'Thinking…',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.poppins(
                    fontSize: 14.5,
                    height: 1.45,
                    color: const Color(0xFF1E2024),
                  ),
                  strong: GoogleFonts.poppins(
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSuggestionStrip(List<String> suggestions) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = suggestions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _send(prompt);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD2DC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      prompt,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF474A57),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Everything the downloaded catalogue can answer, as a tappable list.
  void _showTopicsSheet() {
    final triggers = controller.sampleTriggers(limit: 24);
    final prompts = triggers.isNotEmpty ? triggers : _openingSuggestions;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Text(
                    'What I can help with',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Tap to ask',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF4E6A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: prompts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'Nothing downloaded yet. Sync AlloBot to load the '
                          'topics she can answer offline.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF8E95A5),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: prompts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final prompt = prompts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _send(prompt);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFFD2DC),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    prompt,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E2024),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Color(0xFFFF8A9E),
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TRANSCRIPT VIEW ───

  Widget _buildTranscriptView() {
    return Column(
      children: [
        OfflineChatbotStatusBar(controller: controller),
        Expanded(
          child: Obx(() {
            final messages = controller.messages;
            _scrollToBottom();

            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: messages.length + (controller.isTyping.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= messages.length) {
                  return const OfflineChatbotTypingBubble(showAvatar: true);
                }
                return OfflineChatMessageBubble(
                  message: messages[index],
                  onOptionSelected: _send,
                );
              },
            );
          }),
        ),
        Obx(() {
          if (controller.activeOptions.isEmpty) return const SizedBox.shrink();
          return OfflineChatbotActiveOptionsBar(
            options: controller.activeOptions.toList(),
            onOptionSelected: _send,
          );
        }),
        OfflineChatbotComposer(
          input: _input,
          focusNode: _inputFocus,
          onSend: _send,
          controller: controller,
          onMicTap: toggleListening,
        ),
      ],
    );
  }
}
