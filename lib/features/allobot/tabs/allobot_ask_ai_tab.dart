/// Ask Allo — every turn answered by the intent catalogue on this device.
///
/// A port of AlloKonnect's "Ask AI" page: the downloaded bot definition is
/// matched and its flow graph walked locally, so a conversation costs no
/// network at all. AlloKonnect toggles between a voice view and the transcript;
/// here the transcript is its own tab, so this screen is only the voice view —
/// and where AlloKonnect shows a round AlloBot avatar, AlloMom shows the baby,
/// who mouths the words while the reply is being read out.
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

  /// How tall the baby's card is allowed to grow. She takes the middle of the
  /// screen up to this; past it she is already as big as she reads well at, and
  /// the rest is better left as air than as a slab of pink.
  static const double _maxBabyHeight = 430;

  /// The floor she is never squeezed below.
  ///
  /// [BabyHeroBanner] drops the illustration and shows the bubble alone under
  /// 200px, and on this screen she is the point — so on a short phone the reply
  /// card gives up some of its room rather than costing us the baby entirely.
  static const double _minBabyHeight = 210;

  /// How tall the reply card may get: a share of the screen, so a small phone
  /// does not hand a third of itself to two lines of text.
  static double _replyCardCap(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.145).clamp(88.0, 118.0);

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
    FocusScope.of(context).unfocus();
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
            const SizedBox(height: 16),
            Expanded(child: _buildVoiceView()),
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
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AlloBaby',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
                Text(
                  'Your empathetic pregnancy companion',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
          ),
          _circleButton(
            icon: Icons.forum_outlined,
            tooltip: 'Open the conversation',
            onTap: widget.onOpenChat,
          ),
          // const SizedBox(width: 8),
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

  // ─── VOICE VIEW ───

  Widget _buildVoiceView() {
    return Obx(() {
      final isTyping = controller.isTyping.value;
      final isGenerating = controller.isGenerating.value;
      final isSpeaking = controller.isSpeaking.value;
      final isThinking = isTyping || isGenerating;

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

      // Resolved here, not inside the LayoutBuilder below: that builder runs
      // during layout, outside this Obx's tracking window, so an observable
      // read there would never rebuild the bubble when it changed.
      final bubbleText = _bubbleText();

      return Column(
        children: [
          // ── 1. The baby, mouthing the reply while it is read out ──
          //
          // She takes whatever the rest of the screen does not, so she is as
          // big as the phone allows; everything below her is sized to its
          // content. On a short screen the card shrinks first and the banner
          // drops to its own compact layout rather than squashing her.
          // ── 2. The latest reply, capped so it never stretches ──
          //
          // The two share the flexible middle of the screen, and the split is
          // deliberate: the baby is given it first, up to her ceiling, and the
          // card takes what is left. So a one-line answer reads as one line
          // rather than a line stranded at the top of a tall white box, a
          // longer one scrolls inside its cap, and the whole of it is always in
          // the transcript view.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The card's full allowance is reserved before she is
                // measured, not just its minimum — reserving the minimum gave
                // her every spare pixel and left the answer a two-line slot on
                // a mid-sized phone.
                final babyHeight =
                    (constraints.maxHeight - _replyCardCap(context) - 10).clamp(
                      _minBabyHeight,
                      _maxBabyHeight,
                    );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: BabyHeroBanner(
                        height: babyHeight,
                        speechText: bubbleText,
                        speakingOverride: isSpeaking,
                        thinkingOverride: isThinking,
                        bubblePosition: SpeechBubblePosition.topCenter,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Flexible, not Expanded: it sizes to its answer, and only
                    // shrinks when a short screen has given the baby her floor.
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: _replyCardCap(context),
                          ),
                          child: _buildReplyCard(latest, isThinking),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSuggestionStrip(suggestions),
          ],

          // ── 3. Keyboard composer, or room for the docked mic ──
          // Keyboard mode swaps in the composer; otherwise voice lives in the
          // popup the docked mic opens, so there is nothing to put here.
          if (controller.isKeyboardMode.value) ...[
            const SizedBox(height: 8),
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
            ),
          ],
          const SizedBox(height: 50),
        ],
      );
    });
  }

  /// What the baby's bubble says.
  ///
  /// Anything the voice input needs to tell her comes first — that is what the
  /// bubble is for, rather than a bar sliding over the bottom of the screen.
  /// Otherwise: that she is listening, or her greeting. The words being
  /// recognised show inside the voice popup, and the reply itself belongs in
  /// the card below — the bubble is a fixed shape over the illustration.
  String _bubbleText() {
    final notice = controller.voiceNotice.value;
    if (notice.isNotEmpty) return notice;
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
}
