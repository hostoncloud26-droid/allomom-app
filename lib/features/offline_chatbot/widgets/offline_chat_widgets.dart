/// The chat surface Ask Allo is built from.
///
/// A port of AlloKonnect's offline chatbot page, re-skinned to AlloMom's warm
/// palette: the same status bar, bubbles, quick-reply chips and composer, so a
/// flow authored for one app reads the same way in the other.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

const Color _cardBg = Colors.white;
const Color _pageBorder = Color(0xFFF2E4E7);
const Color _textStrong = Color(0xFF1E2024);
const Color _textSoft = Color(0xFF8E95A5);

/// Live status of the downloaded catalogue: how many intents are ready, when
/// they were last fetched, and whether a flow is mid-conversation.
class OfflineChatbotStatusBar extends StatelessWidget {
  const OfflineChatbotStatusBar({super.key, required this.controller});

  final OfflineChatbotController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final synced = controller.lastSynced.value;
      final error = controller.error.value;
      final hasBundle = controller.hasBundle;
      final flowLabel = controller.flowLabel;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _pageBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (hasBundle ? successGreen : warningAmber).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasBundle ? Icons.bolt_rounded : Icons.cloud_off_rounded,
                    size: 16,
                    color: hasBundle ? successGreen : warningAmber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasBundle
                            ? '${controller.intentCount} topics ready offline'
                            : 'AlloBot not downloaded yet',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textStrong,
                        ),
                      ),
                      if (synced != null)
                        Text(
                          'Synced ${DateFormat('d MMM, h:mm a').format(synced)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textSoft,
                          ),
                        ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: flowLabel == 'Idle'
                              ? successGreen
                              : primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        flowLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (error.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dangerRed.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: dangerRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(fontSize: 11, color: dangerRed),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// One line of the transcript: a reply, what the mother said, or a system note.
class OfflineChatMessageBubble extends StatelessWidget {
  const OfflineChatMessageBubble({
    super.key,
    required this.message,
    required this.onOptionSelected,
    this.showOptions = true,
    this.showAvatar = true,
  });

  final OfflineChatMessage message;
  final void Function(String text) onOptionSelected;
  final bool showOptions;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _systemNote();

    final isUser = message.fromUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && showAvatar) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: accentLight,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/allobaby/minibaby.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.child_care_rounded,
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? primaryGradient : null,
                color: isUser ? null : _cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: _pageBorder),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? primaryColor.withValues(alpha: 0.22)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 140,
                              color: surfaceLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    isUser
                        ? Text(
                            message.text,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: Colors.white,
                            ),
                          )
                        : MarkdownBody(
                            data: message.text,
                            selectable: true,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    color: _textStrong,
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _textStrong,
                                  ),
                                  code: const TextStyle(
                                    backgroundColor: surfaceLight,
                                    color: primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                          ),
                  if (showOptions && message.options.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.options.map((opt) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onOptionSelected(opt),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.32),
                                ),
                              ),
                              child: Text(
                                opt,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.75)
                              : textLight,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.offline_bolt_outlined,
                          size: 10,
                          color: textLight,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: _textSoft,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing dots shown while the bot works out its reply.
class OfflineChatbotTypingBubble extends StatefulWidget {
  const OfflineChatbotTypingBubble({super.key, this.showAvatar = false});

  final bool showAvatar;

  @override
  State<OfflineChatbotTypingBubble> createState() =>
      _OfflineChatbotTypingBubbleState();
}

class _OfflineChatbotTypingBubbleState extends State<OfflineChatbotTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    // In initState, not a late field: a bubble disposed before its first build
    // would otherwise create the controller inside dispose().
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.showAvatar)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: accentLight,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/allobaby/minibaby.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.child_care_rounded,
                  color: primaryColor,
                  size: 16,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _pageBorder),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final progress = (_anim.value + (i * 0.2)) % 1.0;
                    final bounce = math.sin(progress * math.pi);
                    return Container(
                      margin: EdgeInsets.only(
                        left: i == 0 ? 0 : 4,
                        bottom: bounce * 4,
                      ),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: 0.4 + (bounce * 0.6),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The quick replies the step a flow is waiting on offers.
class OfflineChatbotActiveOptionsBar extends StatelessWidget {
  const OfflineChatbotActiveOptionsBar({
    super.key,
    required this.options,
    required this.onOptionSelected,
    this.title,
    this.isScrollable = true,
  });

  final List<String> options;
  final void Function(String text) onOptionSelected;
  final String? title;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    final chips = options.map((option) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onOptionSelected(option),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.85),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textSoft,
                ),
              ),
            ),
          if (isScrollable)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (int i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    chips[i],
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, runSpacing: 6, children: chips),
            ),
        ],
      ),
    );
  }
}

/// The input bar: the mic, the text field, and send.
///
/// The mic does not listen here — it hands off to [onMicTap], which is the
/// voice popup on both screens that use this. AlloKonnect's composer records a
/// Whisper clip inline as well; in AlloMom every spoken turn goes through the
/// popup, so there is one place that owns the recogniser instead of two.
class OfflineChatbotComposer extends StatefulWidget {
  const OfflineChatbotComposer({
    super.key,
    required this.input,
    required this.focusNode,
    required this.onSend,
    required this.controller,
    required this.onMicTap,
    this.hintText = 'Ask Allo anything…',
  });

  final TextEditingController input;
  final FocusNode focusNode;
  final void Function([String? text]) onSend;
  final OfflineChatbotController controller;

  /// Opens the voice popup. Required: a mic that does nothing is worse than no
  /// mic at all.
  final VoidCallback onMicTap;

  final String hintText;

  @override
  State<OfflineChatbotComposer> createState() => _OfflineChatbotComposerState();
}

class _OfflineChatbotComposerState extends State<OfflineChatbotComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.input.addListener(_onTextChanged);
    _hasText = widget.input.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.input.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.input.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _pageBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 4),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: accentLight,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Speak',
                  icon: const Icon(
                    Icons.mic_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                  onPressed: widget.onMicTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.numpadEnter)) {
                        if (!HardwareKeyboard.instance.isShiftPressed) {
                          widget.onSend();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: widget.input,
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => widget.onSend(),
                      style: const TextStyle(fontSize: 15, color: _textStrong),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          fontSize: 14.5,
                          color: textLight,
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_hasText)
                IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: _textSoft,
                  ),
                  onPressed: widget.input.clear,
                ),
              const SizedBox(width: 4),
              Obx(() {
                // `isBusy`, not `isTyping`: the button stays down for the
                // whole turn, as it always has. `isTyping` now ends at the
                // turn's first line, with the rest still to be said.
                final canSend = !widget.controller.isBusy.value && _hasText;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: canSend ? primaryGradient : null,
                    color: canSend ? null : dividerColor,
                    shape: BoxShape.circle,
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.32),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      color: canSend ? Colors.white : textLight,
                      size: 22,
                    ),
                    onPressed: canSend ? () => widget.onSend() : null,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
