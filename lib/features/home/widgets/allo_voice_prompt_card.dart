/// The card AlloBot talks through on the Home screen.
///
/// Sits above the Daily Summary and stays in place: no dialogs, no bottom
/// sheets. A popup for each of these questions would mean a mother opening the
/// app to a stack of modals before she can see anything, and every one of them
/// would hide the screen she is being asked about. Inline, she can read it,
/// answer it, or simply scroll past.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/services/allobot/home_voice_flow.dart';

class AlloVoicePromptCard extends StatelessWidget {
  const AlloVoicePromptCard({
    super.key,
    required this.message,
    this.prompt,
    this.isSpeaking = false,
    this.onYes,
    this.onNo,
    this.onPickDate,
    this.onSubmitText,
    this.onDismiss,
    this.onSpeakerTap,
    this.fillHeight = false,
  });

  /// What AlloBot just said. Shown whether or not a question follows.
  final String message;

  /// The question awaiting an answer, if any.
  final HomePrompt? prompt;

  final bool isSpeaking;

  final VoidCallback? onYes;
  final VoidCallback? onNo;

  /// Opens a date picker; the chosen date comes back through the callback.
  final ValueChanged<DateTime>? onPickDate;

  final ValueChanged<String>? onSubmitText;
  final VoidCallback? onDismiss;
  final VoidCallback? onSpeakerTap;

  /// Stretches the card to the height it is given, matching the Daily Summary
  /// card beside it in the carousel.
  ///
  /// Off by default so the card can also be dropped into an unbounded column,
  /// where filling is impossible and asking for it would throw.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    // Geometry copied from the Daily Summary card it sits beside: same
    // horizontal inset, same 22px padding, same 28px corners. Anything else
    // and the two pages of the carousel do not look like siblings.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD2DC), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4E6A).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
          // Like the summary card: content at the top, the thing she acts on
          // at the bottom.
          mainAxisAlignment: fillHeight
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            _buildMessageBlock(),
            if (prompt != null) _buildQuestionBlock(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBlock() {
    final block = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E2024),
            height: 1.45,
          ),
        ),
      ],
    );

    // Only the message scrolls, and only when the card is height-bound: a long
    // reply must not push the answer buttons off the card.
    if (!fillHeight) return block;
    return Flexible(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: block,
      ),
    );
  }

  Widget _buildQuestionBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: fillHeight ? 16 : 14),
        Text(
          prompt!.question,
          style: GoogleFonts.outfit(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC2334D),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        _buildAnswerControls(context),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0F3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSpeaking ? Icons.graphic_eq_rounded : Icons.auto_awesome_rounded,
            size: 16,
            color: const Color(0xFFFF4E6A),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'ALLOBOT',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFFF4E6A),
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        if (onSpeakerTap != null)
          GestureDetector(
            onTap: onSpeakerTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isSpeaking ? Icons.pause_rounded : Icons.volume_up_rounded,
                size: 19,
                color: const Color(0xFFFF8A9E),
              ),
            ),
          ),
        if (onDismiss != null)
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.only(left: 6, top: 4, bottom: 4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFFB0B6C3),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerControls(BuildContext context) {
    switch (prompt!.answerKind) {
      case HomeAnswerKind.yesNo:
        return Row(
          children: [
            Expanded(child: _button('Yes', filled: true, onTap: onYes)),
            const SizedBox(width: 10),
            Expanded(child: _button('No', filled: false, onTap: onNo)),
          ],
        );

      case HomeAnswerKind.date:
        return Row(
          children: [
            Expanded(
              child: _button(
                'Pick the date',
                filled: true,
                icon: Icons.calendar_month_rounded,
                onTap: () => _pickDate(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _button("Don't know yet", filled: false, onTap: onNo),
            ),
          ],
        );

      case HomeAnswerKind.text:
        return _AnswerField(
          onSubmit: onSubmitText,
          onSkip: onNo,
        );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 28)),
      // A next visit is always ahead, and never more than a pregnancy away.
      firstDate: now,
      lastDate: now.add(const Duration(days: 300)),
      helpText: 'Next ANC check-up',
    );
    if (picked != null) onPickDate?.call(picked);
  }

  Widget _button(
    String label, {
    required bool filled,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF4E6A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? const Color(0xFFFF4E6A) : const Color(0xFFFFD2DC),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: filled ? Colors.white : const Color(0xFFC2334D),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : const Color(0xFFC2334D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The free-text answer, used for what the doctor said.
class _AnswerField extends StatefulWidget {
  const _AnswerField({this.onSubmit, this.onSkip});

  final ValueChanged<String>? onSubmit;
  final VoidCallback? onSkip;

  @override
  State<_AnswerField> createState() => _AnswerFieldState();
}

class _AnswerFieldState extends State<_AnswerField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      widget.onSkip?.call();
      return;
    }
    widget.onSubmit?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF1E2024),
            ),
            decoration: InputDecoration(
              hintText: 'e.g. BP normal, iron tablets to continue, scan next month',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4E6A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Save to this visit',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: widget.onSkip,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD2DC)),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC2334D),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
