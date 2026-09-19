/// Chat — the whole conversation, as a transcript.
///
/// The same bot Ask Allo speaks to, read rather than heard: one controller, two
/// views. Ask Allo is where she talks to it, this is where she scrolls back
/// through what was said, taps a quick reply, or types.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/widgets/allobot_voice_popup.dart';
import 'package:allomom/features/offline_chatbot/widgets/offline_chat_widgets.dart';

class AlloBotChatTab extends StatefulWidget {
  final VoidCallback? onBack;

  const AlloBotChatTab({super.key, this.onBack});

  @override
  State<AlloBotChatTab> createState() => _AlloBotChatTabState();
}

class _AlloBotChatTabState extends State<AlloBotChatTab> {
  final OfflineChatbotController controller = OfflineChatbotController.instance;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = (text ?? _input.text).trim();
    if (message.isEmpty) return;
    _input.clear();
    // Not spoken: this screen is the conversation being read back, and a reply
    // read aloud over it would talk across what she is reading.
    controller.send(message, speak: false);
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

  /// Voice from here opens the same popup Ask Allo uses, rather than sending
  /// her to the other tab: the answer lands in this transcript either way.
  void _openVoice() {
    HapticFeedback.mediumImpact();
    _inputFocus.unfocus();
    AlloBotVoicePopup.show(
      context,
      controller: controller,
      speakReply: false,
      onEnableKeyboardMode: () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _inputFocus.requestFocus(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            OfflineChatbotStatusBar(controller: controller),
            Expanded(
              child: Obx(() {
                final messages = controller.messages;
                _scrollToBottom();

                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount:
                      messages.length + (controller.isTyping.value ? 1 : 0),
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
              if (controller.activeOptions.isEmpty) {
                return const SizedBox.shrink();
              }
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
              onMicTap: _openVoice,
              hintText: 'Message AlloBot…',
            ),
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
              if (widget.onBack != null) {
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
                Obx(
                  () => Text(
                    controller.isTyping.value
                        ? 'Thinking…'
                        : (controller.flowLabel == 'Idle'
                              ? 'Empathetic Maternal AI'
                              : controller.flowLabel),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF8E95A5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.messages.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: controller.createNewChat,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F3),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/allobaby/minibaby.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.child_care_rounded,
                  color: Color(0xFFFF4E6A),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing here yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask me something here, or talk to me from Ask Allo — '
              'everything we say lands in this transcript.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                height: 1.45,
                color: const Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
