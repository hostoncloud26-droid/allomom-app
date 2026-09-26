/// Ask Allo — every turn answered by the intent catalogue on this device.
///
/// A port of AlloKonnect's "Ask AI" page: the downloaded bot definition is
/// matched and its flow graph walked locally, so a conversation costs no
/// network at all. AlloKonnect toggles between a voice view and the transcript;
/// here the transcript is its own tab, so this screen is only the voice view.
///
/// The face of it is AlloKonnect's AlloBot "Ask AI" screen, part for part —
/// the animated Gemini orb, the gradient heading over the intro card (the
/// reply takes the heading's place once she asks something), the "Try asking"
/// chips and the Features slider, on a soft gradient. The pieces live in
/// [AlloBotGeminiOrb], [AlloBotSuggestionChip] and [AlloBotFeatureSlider]; the
/// baby sits in the orb where AlloKonnect has its bot. Everything under the
/// surface — the voice popup, the flow options, the docked mic — is untouched.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/allobot/widgets/allobot_home_view.dart';
import 'package:allomom/features/allobot/widgets/allobot_welcome_view.dart'
    show GradientText;
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
  List<String> _drawOpeningSuggestions() =>
      alloBotOpeningSuggestions(controller);

  static const Set<String> _stopWords = {
    'the',
    'and',
    'for',
    'you',
    'your',
    'are',
    'was',
    'with',
    'this',
    'that',
    'can',
    'how',
    'what',
    'my',
    'me',
    'to',
    'of',
    'in',
    'on',
    'is',
    'it',
    'a',
    'an',
    'i',
    'do',
    'show',
    'open',
    'please',
    'have',
    'has',
    'will',
    'from',
  };

  Set<String> _keywords(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 2 && !_stopWords.contains(w))
      .toSet();

  /// The flow is waiting on one of its node's options: they replace the
  /// "Try asking" chips, and the Features slider and the composer step aside
  /// so the options are the only thing to answer with.
  bool get _showingOptions => controller.activeOptions.isNotEmpty;

  /// "Try asking" chips, as AlloKonnect ranks them: the options the flow is
  /// waiting on; otherwise, before the first message, the opening questions,
  /// and afterwards the catalogue's triggers ranked by overlap with the last
  /// turn.
  List<String> _suggestionTexts({
    required bool hasInteracted,
    String? lastUserText,
    String? lastReplyText,
  }) {
    if (_showingOptions) return controller.activeOptions.toList();
    if (_openingSuggestions.isEmpty) {
      _openingSuggestions = _drawOpeningSuggestions();
    }
    if (!hasInteracted) return _openingSuggestions;

    final triggers = controller.sampleTriggers(limit: 100);
    final pool = triggers.isEmpty ? _openingSuggestions : triggers;
    final asked = (lastUserText ?? '').trim().toLowerCase();
    final topic = _keywords('${lastUserText ?? ''} ${lastReplyText ?? ''}');
    final candidates = pool
        .where((t) => t.trim().toLowerCase() != asked)
        .toList();
    final scores = {
      for (final t in candidates) t: _keywords(t).intersection(topic).length,
    };
    // List.sort is not stable; ties keep the catalogue's order.
    final order = {
      for (var i = 0; i < candidates.length; i++) candidates[i]: i,
    };
    candidates.sort((a, b) {
      final byScore = scores[b]!.compareTo(scores[a]!);
      return byScore != 0 ? byScore : order[a]!.compareTo(order[b]!);
    });
    return candidates.take(10).toList();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // AlloKonnect's soft wash: white fading into a hint of the theme
        // colour at the bottom. Every stop is opaque — a translucent one lets
        // the page behind show through as a hard band.
        decoration: BoxDecoration(gradient: _backgroundGradient()),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopAppBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildVoiceView()),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _backgroundGradient() {
    Color tint(Color base, double alpha) =>
        Color.alphaBlend(primaryColor.withValues(alpha: alpha), base);
    if (_p.isDark) {
      return LinearGradient(
        colors: [
          const Color(0xFF161622),
          const Color(0xFF121218),
          tint(const Color(0xFF121218), 0.04),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return LinearGradient(
      colors: [
        Colors.white,
        const Color(0xFFF8FAFC),
        tint(const Color(0xFFF8FAFC), 0.05),
        tint(const Color(0xFFF8FAFC), 0.15),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
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
                    color: _p.pick(
                      Colors.black.withValues(alpha: 0.05),
                      _p.shadow,
                    ),
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
  //
  // AlloKonnect's Ask AI layout: the orb, the heading and the intro card up
  // top — the reply itself takes the heading's place once she has asked
  // something — and "Try asking" plus "Features" pinned to the bottom.

  Widget _buildVoiceView() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Obx(() {
              // Clears the docked mic, unless the composer below already lifts
              // the content above it.
              final bottomGap =
                  controller.isKeyboardMode.value && !_showingOptions
                  ? 8.0
                  : 40.0;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: bottomGap,
                ),
                child: ConstrainedBox(
                  // Fill the viewport: the empty first child and spaceBetween
                  // centre the hero in the room above the bottom block.
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - bottomGap,
                  ),
                  child: _buildVoiceContent(),
                ),
              );
            }),
          ),
        ),
        Obx(() {
          if (!controller.isKeyboardMode.value) {
            return const SizedBox(height: 12);
          }
          if (_showingOptions) {
            // The composer is going away; take the keyboard with it.
            if (_inputFocus.hasFocus) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _inputFocus.unfocus(),
              );
            }
            return const SizedBox(height: 12);
          }
          return OfflineChatbotComposer(
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
          );
        }),
      ],
    );
  }

  Widget _buildVoiceContent() {
    return Obx(() {
      final isTyping = controller.isTyping.value;
      // Rebuild once a catalogue sync lands, so its triggers show.
      controller.isSyncing.value;

      // The line the baby is on — deliberately not the end of the transcript:
      // a turn restored from her last visit is read out again without being
      // reprinted, so following the transcript would jump to its last line
      // the moment she started speaking the first.
      String? spoken = controller.currentLine.value?.trim();
      if (spoken != null && spoken.isEmpty) spoken = null;
      final messages = controller.messages;
      if (spoken == null) {
        for (var i = messages.length - 1; i >= 0; i--) {
          final message = messages[i];
          if (!message.fromUser &&
              !message.isSystem &&
              message.text.isNotEmpty) {
            spoken = message.text;
            break;
          }
        }
      }

      final lastUserIndex = messages.lastIndexWhere((m) => m.fromUser);
      final hasInteracted = lastUserIndex != -1;
      final suggestions = _suggestionTexts(
        hasInteracted: hasInteracted,
        lastUserText: hasInteracted ? messages[lastUserIndex].text : null,
        lastReplyText: spoken,
      );
      final showingOptions = _showingOptions;
      final isDark = _p.isDark;
      final headerStyle = GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.grey.shade800,
      );

      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox.shrink(),

          // ── Top: orb, heading, text ──
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: FittedBox(
                    child: AlloBotGeminiOrb(
                      isSpeaking: controller.isSpeaking.value,
                      isThinking: isTyping,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildHeroText(
                  isTyping: isTyping,
                  reply: hasInteracted ? spoken : null,
                  intro: _headlineMessage(spoken),
                ),
              ],
            ),
          ),

          // ── Bottom: suggestions and features ──
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  showingOptions ? 'Options' : 'Try asking:',
                  style: showingOptions
                      ? headerStyle.copyWith(fontSize: 18)
                      : headerStyle,
                ),
              ),
              SizedBox(height: showingOptions ? 14 : 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                // Options wrap onto more rows rather than scroll, so every
                // answer is in view at the bigger size.
                child: showingOptions
                    ? SizedBox(
                        key: ValueKey(suggestions.join('|')),
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final text in suggestions)
                              AlloBotSuggestionChip(
                                text: text,
                                onTap: _send,
                                large: true,
                              ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        key: ValueKey(suggestions.join('|')),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            for (final text in suggestions)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: AlloBotSuggestionChip(
                                  text: text,
                                  onTap: _send,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              if (!showingOptions) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Features', style: headerStyle),
                ),
                const SizedBox(height: 8),
                AlloBotFeatureSlider(
                  // A feature's page may have recorded something, so the view
                  // is rebuilt once she comes back from it.
                  onFeatureOpened: () {
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ],
          ),
        ],
      );
    });
  }

  /// Before her first question: "Hello! I am AlloBaby" over the intro card.
  /// Afterwards the line being read out takes the heading's place, in the
  /// same gradient — no card.
  Widget _buildHeroText({
    required bool isTyping,
    required String? reply,
    required String intro,
  }) {
    final Widget content;
    if (isTyping) {
      content = GradientText(
        key: const ValueKey('typing'),
        text: 'Thinking…',
        gradient: alloBotHeroGradient,
        style: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      );
    } else if (reply != null && reply.trim().isNotEmpty) {
      content = AlloBotHeroLine(key: ValueKey(reply), text: reply);
    } else {
      content = Column(
        key: const ValueKey('intro'),
        children: [
          GradientText(
            text: 'Hello! I am AlloBaby',
            gradient: alloBotHeroGradient,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildIntroCard(alloBotPlainText(intro)),
        ],
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: content,
      ),
    );
  }

  Widget _buildIntroCard(String text) {
    final isDark = _p.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.5,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
          height: 1.4,
        ),
      ),
    );
  }

  /// The intro card's text.
  ///
  /// Anything the voice input needs to tell her comes first, then that she is
  /// listening, then whatever she was last told, and only on a screen that
  /// has said nothing at all does the standing description show.
  String _headlineMessage(String? spoken) {
    final notice = controller.voiceNotice.value;
    if (notice.isNotEmpty) return notice;
    if (_isListening) return 'I am listening, Amma…';
    final line = (spoken ?? '').trim();
    if (line.isNotEmpty) return line;
    return 'Your personal maternal AI assistant. Ask me anything about your '
        'pregnancy, nutrition, or baby care.';
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
                            color: _p.pick(
                              const Color(0xFF8E95A5),
                              _p.textMuted,
                            ),
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
                                      color: _p.pick(
                                        const Color(0xFF1E2024),
                                        _p.textPrimary,
                                      ),
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
