import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';

/// Home's keyboard input: a single rounded field that rises with the keyboard,
/// opened from the voice popup's keyboard control. What she types is answered
/// in the AlloBaby card, not in Ask Allo — AlloKonnect's home composer.
class HomeAskComposer extends StatefulWidget {
  const HomeAskComposer({super.key, required this.onSend});

  final ValueChanged<String> onSend;

  /// Shows the composer over Home.
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSend,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (_) => HomeAskComposer(onSend: onSend),
    );
  }

  @override
  State<HomeAskComposer> createState() => _HomeAskComposerState();
}

class _HomeAskComposerState extends State<HomeAskComposer> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.fromLTRB(18, 6, 8, 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  autofocus: true,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask AlloBaby anything…',
                    hintStyle: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : const Color(0xFF757575),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded, color: primaryColor),
                tooltip: 'Send',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
