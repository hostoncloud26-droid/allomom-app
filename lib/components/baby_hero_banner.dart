import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:allomom/components/baby_animations.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

enum SpeechBubblePosition { left, right, topCenter, none }

class BabyHeroBanner extends StatelessWidget {
  final String speechText;
  final String greetingText;
  final SpeechBubblePosition bubblePosition;
  final double height;
  final double? babyHeight;
  final VoidCallback? onTap;

  /// When set, a speaker button is shown inside the speech bubble and tapping
  /// it calls this instead of [onTap]. Used by the onboarding screens, which
  /// read their prompt aloud.
  ///
  /// Left null when [narrationKey] is set: the narration wires its own speaker,
  /// which replays the clip rather than showing a snackbar about it.
  final VoidCallback? onSpeakerTap;

  /// Outer margin. The onboarding screens place the card inside a full-width
  /// column, so they inset it the same 20px the home page does.
  final EdgeInsetsGeometry? margin;

  /// A `NarrationKeys` constant. When set, the card speaks that line as it
  /// appears, shows the line's text in the bubble in place of [speechText], and
  /// turns its speaker button into a replay control.
  final String? narrationKey;

  /// Whether the clip plays by itself when the card appears. False for cards
  /// that should stay quiet until the speaker is tapped.
  final bool autoPlayNarration;

  /// Whether leaving the screen cuts the clip off. False on the last card of a
  /// flow, which keeps talking as the next screen comes in.
  final bool stopNarrationOnDispose;

  /// Whether the line replaces [speechText] for good, or only while it plays.
  /// See [BabyNarration.bindText].
  final bool bindNarrationText;

  /// Set by [BabyPrompt], which owns the narration itself so the clip is not
  /// cut in half when the keyboard swaps this card for the slim bar.
  final bool speakingOverride;

  /// Whether the baby is thinking / generating an answer or audio.
  final bool thinkingOverride;

  /// Drops the fixed [height] and lets the card fill whatever the parent hands
  /// it, so a screen can put the card in an `Expanded` and give the baby every
  /// pixel the form below does not need.
  ///
  /// The registration screens used to pair a fixed-height card with a `Spacer`,
  /// which parked a band of empty background between the baby and the form.
  /// Growing the card instead keeps the page full at any screen height.
  final bool expand;

  /// Whether the baby sits on its pink card — the wash, the hearts-and-stars
  /// pattern, the border and the shadow. False on Home, where the baby and
  /// its bubble stand straight on the page, over a soft glow in the theme's
  /// colours (the Ask Allo orb's nebula, recoloured).
  final bool showBackground;

  const BabyHeroBanner({
    super.key,
    this.speechText = '',
    this.greetingText = "",
    this.bubblePosition = SpeechBubblePosition.topCenter,
    this.height = 270,
    this.babyHeight,
    this.onTap,
    this.onSpeakerTap,
    this.margin,
    this.narrationKey,
    this.autoPlayNarration = true,
    this.stopNarrationOnDispose = true,
    this.bindNarrationText = true,
    this.speakingOverride = false,
    this.thinkingOverride = false,
    this.expand = false,
    this.showBackground = true,
  });

  /// Keys so layout tests can assert the bubble and the baby never overlap.
  static const bubbleKey = Key('babyHeroBubble');
  static const babyKey = Key('babyHeroBaby');

  /// Below this the bubble alone fills the card and the baby is dropped.
  ///
  /// A two-line bubble needs ~110px once padding is counted, so on a shorter
  /// card the baby would be a 30px sliver rather than a character. Every form
  /// shrinks the card to 150 when the keyboard opens, which lands here: the
  /// mother gets a clean prompt instead of a squashed baby.
  static const compactHeight = 200.0;

  /// How tall the baby claims to be while [expand] is on.
  ///
  /// `BoxFit.contain` lets the real baby grow with the card, but the raw asset
  /// reports its own pixel height as an intrinsic — and a `SliverFillRemaining`
  /// sizes the page off intrinsics. Left uncapped the page would decide it
  /// needed ~800px and scroll on every phone. This is roughly the room the
  /// fixed 270 card used to leave the baby, so the page's minimum height is
  /// unchanged and only the slack above it is new.
  static const expandedBabyExtent = 140.0;

  @override
  Widget build(BuildContext context) {
    final key = narrationKey;
    if (key == null) {
      return _buildCard(
        context,
        speechText,
        onSpeakerTap,
        speakingOverride,
        thinkingOverride,
      );
    }

    return BabyNarration(
      narrationKey: key,
      autoPlay: autoPlayNarration,
      stopOnDispose: stopNarrationOnDispose,
      bindText: bindNarrationText,
      fallbackText: speechText,
      builder: (context, state) => _buildCard(
        context,
        state.text,
        state.onSpeakerTap,
        state.speaking,
        thinkingOverride,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String text,
    VoidCallback? speakerTap,
    bool speaking,
    bool thinking,
  ) {
    final showBubble =
        bubblePosition != SpeechBubblePosition.none && text.isNotEmpty;
    final compact = !expand && height < compactHeight && showBubble;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        height: expand ? null : height,
        width: double.infinity,
        decoration: !showBackground
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: p.pick(const Color(0xFFFFF2F5), _darkWash),
                border: Border.all(
                  color: p.pick(const Color(0xFFFFE2E8), p.accentBorder),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.pick(
                      const Color(0xFFFF8A9E).withValues(alpha: 0.10),
                      p.shadow,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          // Without the card there is no edge to clip to, and clipping would
          // cut the glow off square instead of letting it fade out.
          clipBehavior: showBackground ? Clip.antiAlias : Clip.none,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: showBackground ? Clip.hardEdge : Clip.none,
            children: [
              // Background pattern image with hearts/clouds
              if (showBackground)
                Image.asset(
                  'assets/allobaby/AllomomBg.png',
                  fit: BoxFit.cover,
                  // Dark mode multiplies the pink wash and its hearts/stars
                  // down to a dim rose, so the pattern still reads at night.
                  color: p.isDark ? const Color(0xFF45333A) : null,
                  colorBlendMode: p.isDark ? BlendMode.modulate : null,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: p.pick(
                            const [Color(0xFFFFF5F7), Color(0xFFFFE6ED)],
                            const [Color(0xFF2E2024), Color(0xFF24181B)],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // No card: a glow behind the baby instead, under the bubble so
              // it never tints it. The baby takes the lower part of the card.
              if (!showBackground)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: (expand ? 320.0 : height) * 0.72,
                  child: const _ThemeNebula(),
                ),

              // Bubble on top, baby filling whatever room is left below it.
              //
              // These used to be two independent `Positioned` widgets with the
              // baby pinned at a fixed 160px. Nothing related the two, so the
              // moment a screen shrank the card — every form does, to make way
              // for the keyboard — the baby overflowed the top of the card and
              // the bubble landed on its face. A column makes the overlap
              // impossible instead of merely unlikely: the bubble takes the
              // height it needs, the baby scales into the remainder.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Column(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (showBubble)
                      // Compact: Flexible hands the bubble the real content
                      // box, so an unusually long prompt is trimmed instead of
                      // overflowing the card. Full: capped at 55% so the baby
                      // always keeps ~40% of the card, however long the prompt.
                      if (compact)
                        Flexible(
                          child: _buildSpeechBubble(
                            context,
                            text,
                            speakerTap,
                            speaking,
                          ),
                        )
                      else
                        ConstrainedBox(
                          // Expanding: the card has no height to take a share
                          // of, and the bubble caps itself at four lines.
                          constraints: BoxConstraints(
                            maxHeight: expand ? double.infinity : height * 0.55,
                          ),
                          child: _buildSpeechBubble(
                            context,
                            text,
                            speakerTap,
                            speaking,
                          ),
                        ),
                    if (!compact) ...[
                      if (showBubble) const SizedBox(height: 6),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                babyHeight ??
                                (expand ? expandedBabyExtent : double.infinity),
                          ),
                          child: _buildBaby(speaking, thinking),
                        ),
                      ),
                    ],
                    if (greetingText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        greetingText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2024),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The animated baby using Lottie.
  ///
  /// Mouth moves only while there is sound ([BabyAnimations.speaking]).
  /// While thinking / generating, plays the breathing and blinking clip
  /// ([BabyAnimations.idle]).
  Widget _buildBaby(bool speaking, bool thinking) {
    final still = Image.asset(
      'assets/allobaby/AlloMombabySquare.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      errorBuilder: (context, error, stackTrace) {
        return const FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.face_retouching_natural_rounded,
            size: 110,
            color: Color(0xFFFF6584),
          ),
        );
      },
    );

    if (speaking) {
      return KeyedSubtree(
        key: babyKey,
        child: Image.asset(
          BabyAnimations.speaking,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => still,
        ),
      );
    }

    if (thinking) {
      return KeyedSubtree(
        key: babyKey,
        child: Image.asset(
          BabyAnimations.idle,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => still,
        ),
      );
    }

    return KeyedSubtree(key: babyKey, child: still);
  }

  Widget _buildSpeechBubble(
    BuildContext context,
    String text,
    VoidCallback? speakerTap,
    bool speaking,
  ) {
    final label = Text(
      text,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 4,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2D3142),
        height: 1.45,
        letterSpacing: 0.1,
      ),
    );

    return Container(
      key: bubbleKey,
      constraints: const BoxConstraints(maxWidth: 320),
      child: CustomPaint(
        painter: _ChatBubbleTailPainter(
          color: Colors.white,
          shadowColor: const Color(0xFFFF8A9E).withValues(alpha: 0.16),
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            speakerTap == null ? 22 : 12,
            22,
          ),
          child: speakerTap == null
              ? label
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: label),
                    const SizedBox(width: 8),
                    NarrationSpeakerButton(
                      onTap: speakerTap,
                      speaking: speaking,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The speaker control inside a speech bubble.
///
/// Doubles as the playing indicator: an equaliser glyph on a filled pill while
/// the clip runs, a plain speaker when it does not. Tapping it mid-clip stops
/// the baby, which is the only way to cut a line short now that the card is
/// part of the screen and cannot be swiped away like AlloBaby's floating
/// bubble.
class NarrationSpeakerButton extends StatelessWidget {
  const NarrationSpeakerButton({
    super.key,
    required this.onTap,
    this.speaking = false,
    this.size = 15,
  });

  final VoidCallback onTap;
  final bool speaking;
  final double size;

  static const buttonKey = Key('narrationSpeakerButton');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: speaking ? const Color(0xFFFF4E6A) : const Color(0xFFFFF0F3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
          color: speaking ? Colors.white : const Color(0xFFFF4E6A),
          size: size,
        ),
      ),
    );
  }
}

class _ChatBubbleTailPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _ChatBubbleTailPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 22.0;
    const double tailWidth = 16.0;
    const double tailHeight = 8.0;

    final Path path = Path();
    final bubbleRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height - tailHeight,
    );
    path.addRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(radius)),
    );

    // Tail pointing downwards in the center
    final centerX = size.width / 2;
    path.moveTo(centerX - tailWidth / 2, size.height - tailHeight);
    path.lineTo(centerX, size.height);
    path.lineTo(centerX + tailWidth / 2, size.height - tailHeight);
    path.close();

    // Draw shadow
    canvas.drawShadow(path, shadowColor, 8.0, true);

    // Draw bubble fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slim version of [BabyHeroBanner] for when the keyboard is open.
///
/// The full card needs ~260px to hold the baby; squeezing it to 150 leaves
/// either a clipped baby or an empty pink block with a bubble floating in it.
/// This keeps the same voice — small baby, same prompt, same speaker — in the
/// height a form can actually spare.
class BabyPromptBar extends StatelessWidget {
  const BabyPromptBar({
    super.key,
    this.text = '',
    this.onSpeakerTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
    this.narrationKey,
    this.autoPlayNarration = true,
    this.stopNarrationOnDispose = true,
    this.bindNarrationText = true,
    this.speakingOverride = false,
  });

  final String text;
  final VoidCallback? onSpeakerTap;
  final EdgeInsetsGeometry margin;

  /// See [BabyHeroBanner.narrationKey].
  final String? narrationKey;
  final bool autoPlayNarration;
  final bool stopNarrationOnDispose;
  final bool bindNarrationText;

  /// See [BabyHeroBanner.speakingOverride].
  final bool speakingOverride;

  static const barKey = Key('babyPromptBar');

  @override
  Widget build(BuildContext context) {
    final key = narrationKey;
    if (key == null) return _buildBar(text, onSpeakerTap, speakingOverride);

    return BabyNarration(
      narrationKey: key,
      autoPlay: autoPlayNarration,
      stopOnDispose: stopNarrationOnDispose,
      bindText: bindNarrationText,
      fallbackText: text,
      builder: (context, state) =>
          _buildBar(state.text, state.onSpeakerTap, state.speaking),
    );
  }

  Widget _buildBar(String label, VoidCallback? speakerTap, bool speaking) {
    return Container(
      key: barKey,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE2E8), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: speaking
                // Zoomed onto the face: the clip is the full-body frame, and
                // at this size only the face reads.
                ? Transform.scale(
                    scale: 2.0,
                    alignment: const Alignment(0, -0.3),
                    child: Image.asset(
                      BabyAnimations.speaking,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) =>
                          _stillBabyHead(),
                    ),
                  )
                : _stillBabyHead(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label.replaceAll('\n', ' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3142),
                height: 1.35,
              ),
            ),
          ),
          if (speakerTap != null) ...[
            const SizedBox(width: 8),
            NarrationSpeakerButton(
              onTap: speakerTap,
              speaking: speaking,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stillBabyHead() => Image.asset(
    'assets/allobaby/AlloMombaby.png',
    fit: BoxFit.cover,
    // The asset is a full-body baby; crop to the head so the face
    // still reads at this size.
    alignment: Alignment.topCenter,
    errorBuilder: (context, error, stackTrace) => const Icon(
      Icons.face_retouching_natural_rounded,
      size: 24,
      color: Color(0xFFFF6584),
    ),
  );
}

/// Picks the right baby prompt for the room available.
///
/// Form screens shrink hard when the keyboard opens, so they pass
/// `compact: true` and get [BabyPromptBar] instead of a squeezed
/// [BabyHeroBanner]. One call site rather than two branches per screen.
class BabyPrompt extends StatelessWidget {
  const BabyPrompt({
    super.key,
    this.text = '',
    this.onSpeakerTap,
    this.compact = false,
    this.height = 260,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
    this.narrationKey,
    this.autoPlayNarration = true,
    this.stopNarrationOnDispose = true,
    this.bindNarrationText = true,
    this.expand = false,
  });

  final String text;
  final VoidCallback? onSpeakerTap;

  /// True when the keyboard is open and the full card will not fit.
  final bool compact;

  /// See [BabyHeroBanner.expand]. The caller puts this widget in an `Expanded`
  /// and the card grows into the slack; the compact bar keeps its own height
  /// and leaves the rest of the slot empty rather than stretching into a tall
  /// pink slab.
  final bool expand;

  final double height;
  final EdgeInsetsGeometry margin;

  /// See [BabyHeroBanner.narrationKey].
  final String? narrationKey;
  final bool autoPlayNarration;
  final bool stopNarrationOnDispose;
  final bool bindNarrationText;

  @override
  Widget build(BuildContext context) {
    final key = narrationKey;
    if (key == null) return _build(text, onSpeakerTap, false);

    // The narration lives here rather than on the two leaves below. Opening
    // the keyboard swaps the card for the bar, which would otherwise dispose
    // one narration and start another — cutting the clip off mid-sentence and
    // then declining to replay it, since the key had already been spoken.
    return BabyNarration(
      narrationKey: key,
      autoPlay: autoPlayNarration,
      stopOnDispose: stopNarrationOnDispose,
      bindText: bindNarrationText,
      fallbackText: text,
      builder: (context, state) =>
          _build(state.text, state.onSpeakerTap, state.speaking),
    );
  }

  Widget _build(String label, VoidCallback? speakerTap, bool speaking) {
    if (compact) {
      final bar = BabyPromptBar(
        text: label,
        onSpeakerTap: speakerTap,
        margin: margin,
        speakingOverride: speaking,
      );
      if (!expand) return bar;
      return Column(children: [bar, const Spacer()]);
    }
    return BabyHeroBanner(
      margin: margin,
      height: height,
      expand: expand,
      speechText: label,
      onSpeakerTap: speakerTap,
      speakingOverride: speaking,
    );
  }
}

/// The glow behind the baby when it has no card: four discs in the theme's
/// pinks, blurred until they read as one wash — the Ask Allo orb's nebula in
/// Allomom's own colours.
class _ThemeNebula extends StatelessWidget {
  const _ThemeNebula();

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.isDark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Wider than the baby, so the glow fades out around it rather than
        // ending at its edges. Drawn against the orb's 200px original.
        final extent = constraints.biggest.shortestSide * 1.35;
        final scale = extent / 200;
        final opacity = dark ? 0.8 : 0.85;

        // Min sizes zeroed: the slot hands down tight constraints as wide as
        // the card, which would otherwise override the glow's own size.
        return OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: extent,
          maxHeight: extent,
          child: IgnorePointer(
            child: SizedBox(
              width: extent,
              height: extent,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 32.0 * scale,
                  sigmaY: 32.0 * scale,
                ),
                child: Stack(
                  children: [
                    _blob(
                      const Alignment(-0.5, -0.5),
                      90 * scale,
                      const Color(0xFFFF626F),
                      opacity,
                    ),
                    _blob(
                      const Alignment(0.5, 0.5),
                      85 * scale,
                      const Color(0xFFB983FF),
                      opacity,
                    ),
                    _blob(
                      const Alignment(0.5, -0.5),
                      80 * scale,
                      const Color(0xFFE25584),
                      opacity,
                    ),
                    _blob(
                      const Alignment(-0.5, 0.5),
                      75 * scale,
                      const Color(0xFFFFA38A),
                      opacity * 0.9,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _blob(Alignment alignment, double size, Color color, double opacity) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
