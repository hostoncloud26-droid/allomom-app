import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/allobot/widgets/allobot_voice_assistant_modal.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/services/allobot/allobot_engine.dart';
import 'package:allomom/services/allobot/allobot_service.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/tts_service.dart';

/// One turn in the chat.
class _ChatMessage {
  _ChatMessage.user(this.text, this.time)
      : isBot = false,
        kind = AlloBotReplyKind.smallTalk,
        followUp = null,
        chips = const [],
        sourceLabel = null,
        grounding = const [],
        showKickCard = false,
        isContextQuestion = false,
        spokenText = '';

  _ChatMessage.bot(AlloBotReply reply, this.time)
      : isBot = true,
        text = reply.text,
        kind = reply.kind,
        followUp = reply.followUp,
        chips = reply.chips,
        sourceLabel = reply.sourceLabel,
        grounding = reply.grounding,
        showKickCard = reply.showKickCounterCard,
        isContextQuestion = reply.contextPrompt != null,
        spokenText = reply.spokenText;

  late final String text;
  final bool isBot;
  final String time;
  final AlloBotReplyKind kind;
  final String? followUp;
  final List<String> chips;
  final String? sourceLabel;
  final List<String> grounding;
  final bool showKickCard;

  /// Whether [followUp] is a question AlloBot asked about her own day rather
  /// than one from a seed sheet. Those take a plain no as usefully as a yes, so
  /// the bubble offers both.
  final bool isContextQuestion;

  final String spokenText;

  bool isPlaying = false;

  bool get isEmergency => kind == AlloBotReplyKind.emergency;
}

class AlloBotChatTab extends StatefulWidget {
  final VoidCallback? onBack;

  const AlloBotChatTab({
    super.key,
    this.onBack,
  });

  @override
  State<AlloBotChatTab> createState() => _AlloBotChatTabState();
}

class _AlloBotChatTabState extends State<AlloBotChatTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TtsService _ttsService = TtsService();

  final List<_ChatMessage> _messages = [];

  AlloBotEngine? _engine;
  bool _isPreparing = true;
  bool _isThinking = false;

  /// The language her seed answers and the voice come back in.
  String _language = AppLanguage.fallback;

  /// The suggestions shown on the landing view, replaced by context-aware ones
  /// as soon as the engine knows which week she is in.
  List<String> _suggestedQueries = const [
    'What should I eat today?',
    'When is my next ANC visit?',
    'Why does baby kick more at night?',
    'Which symptoms need a doctor immediately?',
  ];

  bool get _hasStartedChat => _messages.any((message) => !message.isBot);

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _prepare();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  /// Loads the corpus and her context, then has AlloBot open the conversation.
  ///
  /// The greeting is posted without being asked for — the chat should feel like
  /// someone already waiting, not a blank prompt — but it is *not* spoken.
  /// Voice is opt-in through the Listen button: a phone that starts talking on
  /// its own is intrusive, and this screen is often opened somewhere a mother
  /// would rather not be overheard.
  Future<void> _prepare() async {
    AlloBotEngine engine;
    var language = AppLanguage.fallback;
    try {
      language = await AppLanguage.current();
      engine = await AlloBotService.createEngine(language: language);
    } catch (e) {
      debugPrint('AlloBotChatTab: engine unavailable, falling back: $e');
      engine = AlloBotEngine();
    }
    if (!mounted) return;

    final opening = engine.opening();
    setState(() {
      _engine = engine;
      _language = language;
      _isPreparing = false;
      _suggestedQueries = opening.chips.isEmpty ? _suggestedQueries : opening.chips;
      _messages.add(_ChatMessage.bot(opening, _timestamp()));
    });
  }

  String _timestamp() {
    final now = TimeOfDay.now();
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isThinking) return;

    final engine = _engine;
    setState(() {
      _messages.add(_ChatMessage.user(query, _timestamp()));
      _isThinking = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Retrieval is synchronous and fast, so a short beat is added on purpose:
    // an instant reply reads as canned, and the pause is where the typing
    // indicator does its work.
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    final reply = engine == null
        ? composeThinkingReply(query, AlloBotEngine().context)
        : engine.ask(query);

    setState(() {
      _isThinking = false;
      _messages.add(_ChatMessage.bot(reply, _timestamp()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _resetChat() {
    _ttsService.stop();
    final engine = _engine;
    engine?.reset();

    setState(() {
      _messages.clear();
      _isThinking = false;
    });

    if (engine == null) return;
    final opening = engine.opening();
    setState(() {
      _suggestedQueries = opening.chips.isEmpty ? _suggestedQueries : opening.chips;
      _messages.add(_ChatMessage.bot(opening, _timestamp()));
    });
  }

  void _speak(_ChatMessage message) {
    for (final other in _messages) {
      other.isPlaying = false;
    }
    setState(() => message.isPlaying = true);
    _ttsService.speak(
      message.spokenText.isEmpty ? message.text : message.spokenText,
      language: _language,
      onComplete: () {
        if (!mounted) return;
        setState(() => message.isPlaying = false);
      },
    );
  }

  void _toggleTts(_ChatMessage message) {
    if (message.isPlaying) {
      _ttsService.stop();
      setState(() => message.isPlaying = false);
      return;
    }
    _speak(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _hasStartedChat
                  ? _buildActiveChatStream()
                  : _buildInitialBabyCenterView(),
            ),
            _buildBottomInputBar(),
          ],
        ),
      ),
    );
  }

  // ─── TOP APP BAR ───
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_hasStartedChat) {
                _resetChat();
              } else if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF1E2024),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AlloBot Chat',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                Text(
                  _isPreparing
                      ? 'Getting your details…'
                      : _hasStartedChat
                          ? 'Active Companion'
                          : 'Empathetic Maternal AI',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            GestureDetector(
              onTap: _resetChat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD2DC)),
                ),
                child: Text(
                  'New Chat',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 1. LANDING VIEW: baby hero, AlloBot's opening turn, suggestions ───
  Widget _buildInitialBabyCenterView() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4E6A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/allobaby/AllomomBg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFFFFF2F5));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 6),
                    child: Image.asset(
                      'assets/allobaby/AlloMombaby.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/allobaby/BabyIllustration.png',
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          if (_isPreparing)
            _buildPreparingCard()
          else ...[
            // AlloBot's unprompted opening turn.
            ..._messages.map(_buildMessageBubble),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ask AlloBot anything:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8E95A5),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._suggestedQueries.map(_buildSuggestionRow),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPreparingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFFFF4E6A)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Looking at your week, your visits and today’s care…',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow(String query) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _sendMessage(query),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  query,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E2024),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFFF4E6A),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 2. ACTIVE CHAT STREAM ───
  Widget _buildActiveChatStream() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        ..._messages.map(_buildMessageBubble),
        if (_isThinking) _buildThinkingBubble(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TypingDots(),
            const SizedBox(width: 10),
            Text(
              'AlloBot is thinking…',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return message.isBot ? _buildBotBubble(message) : _buildUserBubble(message);
  }

  Widget _buildBotBubble(_ChatMessage message) {
    final isEmergency = message.isEmergency;
    final isThinkingReply = message.kind == AlloBotReplyKind.thinking;

    final background = isEmergency
        ? const Color(0xFFFFF5F5)
        : isThinkingReply
            ? const Color(0xFFFDFBF6)
            : Colors.white;
    final borderColor = isEmergency
        ? const Color(0xFFFFC9C9)
        : isThinkingReply
            ? const Color(0xFFF0E3C8)
            : const Color(0xFFE5E7EB);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isEmergency ? 1.4 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEmergency) _buildEmergencyHeader(),

            _buildRichText(message.text, isEmergency),

            if (message.grounding.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildGroundingChips(message.grounding),
            ],

            if (message.showKickCard) ...[
              const SizedBox(height: 12),
              _buildKickCounterCard(),
            ],

            if (message.followUp != null && message.followUp!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildFollowUp(message.followUp!, message.isContextQuestion),
            ],

            if (message.chips.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildReplyChips(message.chips),
            ],

            const SizedBox(height: 10),
            _buildBubbleFooter(message),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE01B24), size: 18),
          const SizedBox(width: 6),
          Text(
            'PLEASE GET CHECKED',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE01B24),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the `**bold**` the engine uses to stress a date or a warning.
  Widget _buildRichText(String text, bool isEmergency) {
    final baseStyle = GoogleFonts.poppins(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: isEmergency ? const Color(0xFF7A1A1F) : const Color(0xFF1E2024),
      height: 1.5,
    );

    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));

    return SelectableText.rich(TextSpan(style: baseStyle, children: spans));
  }

  /// The facts the answer was based on — her week, her ANC visit, her EDD — so
  /// she can see the reply is about her and not generic advice.
  Widget _buildGroundingChips(List<String> grounding) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: grounding
          .map(
            (fact) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fact,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// The seed sheet's own "Next Trigger Question", tappable so answering it
  /// walks her one step deeper into the topic.
  /// The question AlloBot ends a turn on — either the seed sheet's own
  /// "Next Trigger Question" or one it asked about her day.
  Widget _buildFollowUp(String followUp, bool isContextQuestion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            followUp,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC2334D),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildAnswerButton('Yes', filled: true),
              const SizedBox(width: 8),
              // A "no" to a question about her own day is where the useful
              // advice lives, so it needs to be as easy to tap as a yes.
              if (isContextQuestion) _buildAnswerButton('No', filled: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String label, {required bool filled}) {
    return GestureDetector(
      onTap: () => _sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF4E6A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? const Color(0xFFFF4E6A) : const Color(0xFFFFD2DC),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : const Color(0xFFC2334D),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyChips(List<String> chips) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips
          .map(
            (chip) => GestureDetector(
              onTap: () => _sendMessage(chip),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD2DC)),
                ),
                child: Text(
                  chip,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBubbleFooter(_ChatMessage message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                message.time,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF8E95A5),
                ),
              ),
              if (message.sourceLabel != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.menu_book_rounded,
                    size: 12, color: Color(0xFFB0B6C3)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    message.sourceLabel!,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB0B6C3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _toggleTts(message),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.isPlaying
                      ? Icons.pause_rounded
                      : Icons.volume_up_rounded,
                  color: const Color(0xFFFF4E6A),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  message.isPlaying ? 'Reading...' : 'Listen',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKickCounterCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KickCounterPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD2DC)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/allobaby/KickCounter.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.directions_walk_rounded,
                  color: Color(0xFFFF4E6A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kick Counter',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  Text(
                    'Tap to open & record kicks',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4E6A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Open',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(_ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E7E), Color(0xFFFF3366)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3366).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM INPUT BAR ───
  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AlloBotVoiceAssistantModal.show(context, onOpenChat: () {});
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD2DC)),
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Color(0xFFFF4E6A),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attach medical report or image'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: Color(0xFF6B7280),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: _sendMessage,
                textInputAction: TextInputAction.send,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF1E2024),
                ),
                decoration: InputDecoration(
                  hintText: 'Message AlloBot...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Opacity(
              opacity: _isThinking ? 0.5 : 1,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF5E7E), Color(0xFFFF3366)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40FF3366),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three dots that fade in sequence while AlloBot composes a reply.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Each dot leads the one before it by a third of the cycle.
            final phase = (_controller.value - index * 0.22) % 1.0;
            final opacity = phase < 0.5 ? 0.35 + phase : 1.35 - phase;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4E6A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
