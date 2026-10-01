import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/allobot/widgets/allobot_home_view.dart';

/// AlloBaby's line on Home, typed out a few letters at a time as if she were
/// saying it, in a box that keeps one height whatever the length: a long line
/// scrolls inside it, following the newest words, instead of pushing the page.
class StreamingHeroLine extends StatefulWidget {
  const StreamingHeroLine({
    super.key,
    required this.text,
    this.height = 132,
    this.charDelay = const Duration(milliseconds: 28),
  });

  final String text;

  /// The text area's fixed height.
  final double height;

  /// How long each letter waits for the one before it.
  final Duration charDelay;

  @override
  State<StreamingHeroLine> createState() => _StreamingHeroLineState();
}

class _StreamingHeroLineState extends State<StreamingHeroLine> {
  final _scroll = ScrollController();
  Timer? _timer;
  String _plain = '';
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant StreamingHeroLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _start();
  }

  void _start() {
    _timer?.cancel();
    final next = alloBotPlainText(widget.text);
    // A line that only grew — a live call's words arriving as she says them —
    // carries on from where the typing was rather than starting over.
    final grew = _plain.isNotEmpty && next.startsWith(_plain);
    _plain = next;
    if (!grew) {
      _shown = 0;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    _timer = Timer.periodic(widget.charDelay, (timer) {
      if (!mounted) return timer.cancel();
      if (_shown >= _plain.length) return timer.cancel();
      setState(() => _shown++);
      _followLatest();
    });
  }

  /// Keeps the newest words in view as the line grows past the box.
  void _followLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (_scroll.offset < end) _scroll.jumpTo(end);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typing = _shown < _plain.length;
    final dark = context.palette.isDark;
    final line = Text.rich(
      TextSpan(
        text: _plain.substring(0, _shown),
        children: [
          // A caret while she is still talking, in the app's pink.
          if (typing)
            const TextSpan(
              text: ' ▍',
              style: TextStyle(color: primaryColor),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: context.palette.textPrimary,
      ),
    );
    return SizedBox(
      height: widget.height,
      child: Center(
        child: SingleChildScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          // Light mode takes Talk 2 Baby's blue-purple-pink gradient; dark
          // keeps plain ink, which reads better on the dark backdrop.
          child: dark
              ? line
              : ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => alloBotHeroGradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: line,
                ),
        ),
      ),
    );
  }
}
