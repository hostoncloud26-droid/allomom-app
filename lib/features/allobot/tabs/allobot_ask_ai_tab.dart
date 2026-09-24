/// Ask Allo — every turn answered by the intent catalogue on this device.
///
/// A port of AlloKonnect's "Ask AI" page: the downloaded bot definition is
/// matched and its flow graph walked locally, so a conversation costs no
/// network at all. AlloKonnect toggles between a voice view and the transcript;
/// here the transcript is its own tab, so this screen is only the voice view.
///
/// The face of it is AlloBaby's AlloBot screen, part for part — the nebula orb,
/// the gradient greeting and the "Try asking:" card strip, all in
/// [AlloBotWelcomeView]. Only the cards differ: AlloBaby offers pregnancy tips,
/// and these open the app's own helpers. Everything under the surface — the
/// voice popup, the flow options, the docked mic — is untouched.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/allobot/widgets/allobot_welcome_view.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/widgets/allobot_voice_popup.dart';
import 'package:allomom/features/offline_chatbot/widgets/offline_chat_widgets.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

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

  AppPalette get _p => context.palette;

  /// How tall the orb is allowed to grow once a conversation is under way. It
  /// takes the middle of the screen up to this; past it the glow is already as
  /// big as it reads well at, and the rest is better left as air.
  static const double _maxOrbHeight = 260;

  /// The floor the orb is never squeezed below — under this the nebula behind
  /// the glass core stops reading as one shape. On a short phone the reply card
  /// gives up some of its room first.
  static const double _minOrbHeight = 150;

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

    // The page opens on the week's message and the baby says it aloud. Held to
    // the first frame so the transcript is on screen before she starts, and
    // not while the voice sheet is about to take over the turn.
    if (!widget.initialListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(controller.openConversation());
      });
    }

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
    // Silence first: the mic is about to open, and the baby's own voice coming
    // out of the speaker is the last thing speech recognition should hear.
    if (BackgroundAudioController.isReady) {
      await BackgroundAudioController.to.stop();
    }
    speak(NarrationKeys.pgAllobotListening);

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
      backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
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
                color: _p.card,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _p.pick(Colors.black.withValues(alpha: 0.05), _p.shadow),
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
          const SizedBox(width: 12),
          // The round avatar AlloBaby's AlloBot bar wears.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFE4E9)),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assistant_rounded,
              color: Color(0xFFFF4E6A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AlloBaby',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online & Ready',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
                      ),
                    ),
                  ],
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
            color: _p.card,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _p.pick(Colors.black.withValues(alpha: 0.05), _p.shadow),
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
      // Thinking is the wait before the turn says anything at all. Once it
      // has, the baby is either reading a line out or between two of them —
      // never thinking — so a clip loading mid-flow no longer flips her back
      // and forth on every step.
      final isTyping = controller.isTyping.value;

      // The line the baby is on, which is what the card below her shows.
      //
      // Deliberately not the end of the transcript. A turn restored from her
      // last visit is read out again without being reprinted, so the whole of
      // it is already in the transcript while she is still on its first line —
      // following the transcript put the last line on screen the moment she
      // started speaking the first. The controller publishes the line being
      // said; the transcript stays the log behind it.
      String? spoken = controller.currentLine.value?.trim();
      if (spoken != null && spoken.isEmpty) spoken = null;

      if (spoken == null) {
        for (var i = controller.messages.length - 1; i >= 0; i--) {
          final message = controller.messages[i];
          if (!message.fromUser &&
              !message.isSystem &&
              message.text.isNotEmpty) {
            spoken = message.text;
            break;
          }
        }
      }

      // Until she has asked something the screen is the welcome view — the orb,
      // the greeting and the cards that open her helpers. Her first question
      // swaps it for the conversation view, where the same orb sits smaller
      // over the line being read out.
      final hasAsked = controller.messages.any((message) => message.fromUser);
      final showWelcome = !hasAsked && !isTyping;

      final suggestions = _currentSuggestions();

      // Resolved here, not inside the LayoutBuilder below: that builder runs
      // during layout, outside this Obx's tracking window, so an observable
      // read there would never rebuild the line when it changed.
      final headline = _headlineMessage(spoken);

      return Column(
        children: [
          // ── 1. The orb, and what she is saying under it ──
          //
          // The welcome view scrolls as one piece, the way AlloBaby's does. In
          // conversation the orb is given a fixed share of the screen and the
          // reply card takes what is left, up to its cap — so a one-line answer
          // reads as one line rather than a line stranded at the top of a tall
          // white box, a longer one scrolls inside its cap, and the whole of it
          // is always in the transcript view.
          Expanded(
            child: showWelcome
                ? AlloBotWelcomeView(
                    title: 'Hello! I am AlloBaby',
                    message: headline,
                    suggestions: suggestions,
                    onSuggestionTap: _send,
                    // A card's page may have recorded something, so the strip
                    // is rebuilt once she comes back from it.
                    onFeatureOpened: () {
                      if (mounted) setState(() {});
                    },
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // The card's full allowance is reserved before the orb is
                      // measured, not just its minimum — reserving the minimum
                      // gave the orb every spare pixel and left the answer a
                      // two-line slot on a mid-sized phone.
                      final cardRoom = _replyCardCap(context);
                      var orbHeight = (constraints.maxHeight - cardRoom - 10)
                          .clamp(_minOrbHeight, _maxOrbHeight);

                      // On a short screen the floor alone would push the card
                      // off the bottom, now that the cards below take a fixed
                      // slice — so the orb gives up its floor before that.
                      final ceiling = constraints.maxHeight * 0.55;
                      if (orbHeight > ceiling) orbHeight = ceiling;

                      // Centred as one pair. The orb has a ceiling, so on a
                      // tall screen there is height to spare — split above and
                      // below the two of them rather than left in a band under
                      // the card.
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AlloBotOrb(size: orbHeight),
                          const SizedBox(height: 10),
                          // Flexible, not Expanded: it sizes to its answer, and
                          // only shrinks when a short screen has given the orb
                          // its floor.
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: _replyCardCap(context),
                                ),
                                // The card shows the line she is on. Once a
                                // turn has said something there is a line to
                                // read, and it must not blank back to
                                // "Thinking…" — that hid every line of a flow
                                // but the last.
                                child: _buildReplyCard(spoken, isTyping),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // The welcome view carries its own copy, scrolling with the
          // greeting. Here it is pinned under the reply card, so the cards and
          // the chips are still there once a conversation has started.
          if (!showWelcome) ...[
            const SizedBox(height: 8),
            AlloBotTryAskingBlock(
              suggestions: suggestions,
              onSuggestionTap: _send,
              onFeatureOpened: () {
                if (mounted) setState(() {});
              },
            ),
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

  /// The grey line under the welcome view's headline.
  ///
  /// Anything the voice input needs to tell her comes first — that slot is what
  /// used to be the baby's bubble, and it is still where a notice belongs
  /// rather than a bar sliding over the bottom of the screen. Then that she is
  /// listening, then whatever she was last told, and only on a screen that has
  /// said nothing at all does the standing description show.
  String _headlineMessage(String? spoken) {
    final notice = controller.voiceNotice.value;
    if (notice.isNotEmpty) return notice;
    if (_isListening) return 'I am listening, Amma…';
    final line = (spoken ?? '').trim();
    if (line.isNotEmpty) return line;
    return 'Your personal maternal AI assistant. Ask me anything about your '
        'pregnancy, nutrition, or baby care.';
  }

  /// The card under the baby: the line she is on, or the greeting when the
  /// conversation has not started, so it is never blank.
  Widget _buildReplyCard(String? line, bool isTyping) {
    final text = (line ?? '').trim().isEmpty
        ? controller.greetingLine()
        : line!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _p.pick(const Color(0xFFF2E4E7), _p.border),
        ),
        boxShadow: [
          BoxShadow(
            color: _p.pick(Colors.black.withValues(alpha: 0.04), _p.shadow),
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
                    color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
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
                    color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                  ),
                  strong: GoogleFonts.poppins(
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                  ),
                ),
              ),
            ),
    );
  }

  /// Everything the downloaded catalogue can answer, as a tappable list.
  void _showTopicsSheet() {
    speak(NarrationKeys.pgAllobotTopics);

    final triggers = controller.sampleTriggers(limit: 24);
    final prompts = triggers.isNotEmpty ? triggers : _openingSuggestions;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _p.card,
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
                color: _p.divider,
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
                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _p.pick(const Color(0xFFFFF0F3), _p.accentSoft),
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
                            color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
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
                              color: _p.pick(
                                const Color(0xFFFFF5F7),
                                _p.accentSoft,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _p.pick(
                                  const Color(0xFFFFD2DC),
                                  _p.accentBorder,
                                ),
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
                                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
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
