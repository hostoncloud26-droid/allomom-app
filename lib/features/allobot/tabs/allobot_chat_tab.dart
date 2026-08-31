import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  bool _hasStartedChat = false;

  final List<Map<String, dynamic>> _messages = [];

  final List<String> _suggestedQueries = [
    'What should I eat today?',
    'Why does baby kick more at night?',
    'Is mild swelling in feet normal in week 24?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    setState(() {
      _hasStartedChat = true;
      _messages.add({
        'sender': 'user',
        'text': text.trim(),
        'time': timeStr,
        'isPlaying': false,
      });
    });

    _textController.clear();
    _scrollToBottom();

    // AI simulated response
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      String reply =
          "That's completely normal for week 24, Amma! Stay hydrated with 8-10 glasses of water and keep counting those precious kicks. ❤️";
      final lower = text.toLowerCase();

      if (lower.contains('eat') || lower.contains('diet') || lower.contains('food')) {
        reply =
            "For week 24, focus on iron & calcium rich foods: fresh spinach, lentils, ragi, curd, and citrus fruits like oranges!";
      } else if (lower.contains('kick')) {
        reply =
            "Babies kick more after you eat and when you rest on your left side. Aim for 10 kicks in 2 hours during active windows!";
      } else if (lower.contains('swelling') || lower.contains('feet')) {
        reply =
            "Mild swelling in the feet is very common in the 2nd trimester. Elevate your legs while resting and stay well hydrated.";
      }

      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': reply,
          'time': timeStr,
          'isPlaying': false,
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _resetChat() {
    setState(() {
      _hasStartedChat = false;
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP APP BAR ───
            Padding(
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
                          _hasStartedChat ? 'Active Companion' : 'Empathetic Maternal AI',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_hasStartedChat)
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
            ),

            // ─── BODY (INITIAL CENTER BABY OR ACTIVE CHAT) ───
            Expanded(
              child: _hasStartedChat
                  ? _buildActiveChatStream()
                  : _buildInitialBabyCenterView(),
            ),

            // ─── BOTTOM INPUT BAR ───
            _buildBottomInputBar(),
          ],
        ),
      ),
    );
  }

  // 1. Initial State: Center Baby Image + Greeting + Suggestions
  Widget _buildInitialBabyCenterView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Baby Hero Banner (Clean, no raw emoji overlays)
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

          // Greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "I'm here, Amma",
                style: GoogleFonts.outfit(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite,
                color: Color(0xFFFF2E56),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'How can I support you and your baby today?',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 22),

          // Suggested Prompts
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

          ..._suggestedQueries.map((query) {
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
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 2. Active Chat Message Stream View
  Widget _buildActiveChatStream() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        ..._messages.map((msg) => _buildMessageBubble(msg)),
        const SizedBox(height: 16),
      ],
    );
  }

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
          // Image attachment icon
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
          const SizedBox(width: 10),

          // Text Field
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
          const SizedBox(width: 10),

          // Send Button
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
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
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isBot = msg['sender'] == 'bot';

    if (isBot) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 30),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
              Text(
                msg['text'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E2024),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    msg['time'] ?? '9:30 AM',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF8E95A5),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        msg['isPlaying'] = !(msg['isPlaying'] ?? false);
                      });
                    },
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
                            (msg['isPlaying'] ?? false)
                                ? Icons.pause_rounded
                                : Icons.volume_up_rounded,
                            color: const Color(0xFFFF4E6A),
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (msg['isPlaying'] ?? false) ? 'Reading...' : 'Listen',
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
              ),
            ],
          ),
        ),
      );
    } else {
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
                msg['text'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                msg['time'] ?? '',
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
  }
}
