import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';

/// Speaks a line the first time its section is actually on screen.
///
/// The long screens — the pregnancy journey, home — have three or four sections
/// with a line each. Playing them all on open is a lecture the mother cannot
/// follow and cannot stop, and the last one would be about a card she has not
/// scrolled to yet. This waits until the section is really in front of her.
///
/// It also refuses to interrupt: if the baby is mid-sentence when a section
/// appears, the line is left for the next scroll rather than queued behind it.
/// Scrolling quickly past a section therefore says nothing, which is right —
/// she was not reading it.
class NarrationOnVisible extends StatefulWidget {
  const NarrationOnVisible({
    super.key,
    required this.narrationKey,
    required this.child,
    this.visibleFraction = 0.5,
  });

  final String narrationKey;
  final Widget child;

  /// How much of the section has to be on screen to count as seen.
  final double visibleFraction;

  @override
  State<NarrationOnVisible> createState() => _NarrationOnVisibleState();
}

class _NarrationOnVisibleState extends State<NarrationOnVisible> {
  ScrollPosition? _position;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _position)) return;
    _position?.removeListener(_check);
    _position = position;
    _position?.addListener(_check);
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_done || !mounted) return;
    if (!BackgroundAudioController.isReady) return;

    final controller = BackgroundAudioController.to;
    if (!controller.isVoiceEnabled.value) return;

    // Said already, in this session or by another copy of this section — stop
    // watching rather than recomputing geometry on every scroll frame.
    if (controller.hasSpoken(widget.narrationKey)) {
      _done = true;
      return;
    }

    // Mid-sentence. Leave it; the next scroll will ask again.
    if (controller.isPlaying.value) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return;
    final height = box.size.height;
    if (height <= 0) return;

    final screenHeight = MediaQuery.maybeOf(context)?.size.height;
    if (screenHeight == null) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final visible =
        math.min(top + height, screenHeight) - math.max(top, 0.0);
    if (visible / height < widget.visibleFraction) return;

    _done = true;
    controller.playByKey(widget.narrationKey);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
