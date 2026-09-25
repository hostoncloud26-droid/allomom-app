import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:allomom/components/baby_animations.dart';
import 'package:allomom/components/baby_bottom_avatar.dart';
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

  /// When set, a ✕ on the bubble's corner calls this — Home uses it to stop
  /// the baby and put the bubble away until she has something new to say.
  final VoidCallback? onClose;

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

  /// Whether the theme-coloured glow sits behind the baby. On everywhere, so
  /// every screen's baby has Home's colours; pass false for a plain card.
  final bool showGlow;

  /// How much of the card the baby takes with no bubble showing, 0..1 of what
  /// is left once the bubble's room is kept clear. 1 keeps her exactly the
  /// size she is beside a two-line bubble; above that she grows into the
  /// space, still standing on the same spot.
  final double restingBabyScale;

  const BabyHeroBanner({
    super.key,
    this.speechText = '',
    this.greetingText = "",
    this.bubblePosition = SpeechBubblePosition.topCenter,
    this.height = 270,
    this.babyHeight,
    this.onTap,
    this.onSpeakerTap,
    this.onClose,
    this.margin,
    this.narrationKey,
    this.autoPlayNarration = true,
    this.stopNarrationOnDispose = true,
    this.bindNarrationText = true,
    this.speakingOverride = false,
    this.thinkingOverride = false,
    this.expand = false,
    this.showBackground = true,
    this.showGlow = true,
    this.restingBabyScale = 1.0,
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

  /// What a two-line bubble takes from the card: its padding, its lines, the
  /// tail, the gap under it and the card's own top and bottom padding. The
  /// baby keeps this much clear when there is no bubble, so she stays the same
  /// size whether it is showing or not.
  static const _bubbleAllowance = 18.0 + 8 + 36 + 2 * 13.5 * 1.45 + 6;

  /// The card's pink wash, dimmed to a rose-tinted dark for dark mode.
  static const _darkWash = Color(0xFF2A1D21);

  @override
  Widget build(BuildContext context) => BabyOnScreen(child: _build(context));

  Widget _build(BuildContext context) {
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
    final p = context.palette;

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

              // A glow behind the baby, under the bubble so it never tints it.
              // The baby takes the lower part of the card.
              if (showGlow)
                compact
                    // Side by side: the glow sits behind the baby on the left.
                    ? Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: _compactBabyWidth + 40,
                        child: const BabyThemeNebula(),
                      )
                    : Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: (expand ? 320.0 : height) * 0.72,
                        child: const BabyThemeNebula(),
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
                child: compact
                    ? _buildCompactRow(
                        context,
                        text,
                        speakerTap,
                        speaking,
                        thinking,
                      )
                    : Column(
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
                                  maxHeight: expand
                                      ? double.infinity
                                      : height * 0.55,
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
                              child:
                                  !showBubble && !expand && babyHeight == null
                                  // No bubble: keep her the size she is beside a
                                  // two-line one, standing where she stood, rather
                                  // than growing to fill the card when it closes.
                                  ? Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SizedBox(
                                        height:
                                            ((height - _bubbleAllowance) *
                                                    restingBabyScale)
                                                .clamp(0.0, height - 26),
                                        child: _buildBaby(speaking, thinking),
                                      ),
                                    )
                                  : ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            babyHeight ??
                                            (expand
                                                ? expandedBabyExtent
                                                : double.infinity),
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

  /// How wide the baby stands in a short card, beside her bubble.
  double get _compactBabyWidth => ((height - 26) * 0.85).clamp(60.0, 140.0);

  /// A short card — too short to stack the bubble over the baby — with the
  /// two side by side instead, the bubble's tail pointing at her. The vitals
  /// and nutrition screens keep their card short to leave room for the data.
  Widget _buildCompactRow(
    BuildContext context,
    String text,
    VoidCallback? speakerTap,
    bool speaking,
    bool thinking,
  ) {
    return Row(
      // Stretch, so the baby gets the card's full height to stand in.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _compactBabyWidth,
          child: _buildBaby(speaking, thinking),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildSpeechBubble(
              context,
              text,
              speakerTap,
              speaking,
              tailLeft: true,
            ),
          ),
        ),
      ],
    );
  }

  /// The animated baby.
  ///
  /// Mouth moves only while there is sound ([BabyAnimations.speaking]);
  /// otherwise — resting or thinking — she breathes and blinks
  /// ([BabyAnimations.idle]). The PNG still is only a fallback for a clip that
  /// fails to decode.
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

    return KeyedSubtree(
      key: babyKey,
      child: Image.asset(
        speaking ? BabyAnimations.speaking : BabyAnimations.idle,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => still,
      ),
    );
  }

  Widget _buildSpeechBubble(
    BuildContext context,
    String text,
    VoidCallback? speakerTap,
    bool speaking, {
    bool tailLeft = false,
  }) {
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

    final bubble = Container(
      key: bubbleKey,
      constraints: const BoxConstraints(maxWidth: 320),
      child: CustomPaint(
        painter: _ChatBubbleTailPainter(
          color: Colors.white,
          shadowColor: const Color(0xFFFF8A9E).withValues(alpha: 0.16),
          tailLeft: tailLeft,
        ),
        child: Container(
          padding: tailLeft
              ? EdgeInsets.fromLTRB(
                  _ChatBubbleTailPainter.sideTail + 14,
                  12,
                  speakerTap == null ? 14 : 10,
                  12,
                )
              : EdgeInsets.fromLTRB(22, 14, speakerTap == null ? 22 : 12, 22),
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

    final close = onClose;
    if (close == null) return bubble;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bubble,
        Positioned(
          top: -10,
          right: -8,
          child: BabyBubbleCloseButton(onTap: close),
        ),
      ],
    );
  }
}

/// The small round ✕ on a speech bubble's corner — the Home card's and the
/// bottom popup's.
class BabyBubbleCloseButton extends StatelessWidget {
  const BabyBubbleCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // A bigger target than the 26px disc, so it is easy to hit.
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: p.pick(Colors.white, p.surface),
              shape: BoxShape.circle,
              border: Border.all(
                color: p.pick(const Color(0xFFFFE2E8), p.border),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: p.pick(const Color(0xFF5B5F6B), p.textSecondary),
            ),
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

  /// Tail on the left edge, pointing at a baby beside the bubble, instead of
  /// down at one below it.
  final bool tailLeft;

  _ChatBubbleTailPainter({
    required this.color,
    required this.shadowColor,
    this.tailLeft = false,
  });

  /// How far a side tail reaches out from the bubble.
  static const double sideTail = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 22.0;
    const double tailWidth = 16.0;
    const double tailHeight = 8.0;

    final Path path;
    if (tailLeft) {
      final body = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(sideTail, 0, size.width - sideTail, size.height),
            const Radius.circular(20),
          ),
        );
      // Overlaps the body and is unioned in, so there is no seam at the join.
      final y = size.height / 2;
      final tail = Path()
        ..moveTo(sideTail + 2, y - 8)
        ..lineTo(0, y)
        ..lineTo(sideTail + 2, y + 8)
        ..close();
      path = Path.combine(PathOperation.union, body, tail);
    } else {
      path = Path();
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
    }

    // Draw shadow
    canvas.drawShadow(path, shadowColor, 8.0, true);

    // Draw bubble fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChatBubbleTailPainter oldDelegate) =>
      oldDelegate.tailLeft != tailLeft;
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
  Widget build(BuildContext context) => BabyOnScreen(child: _build());

  Widget _build() {
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
            child: Image.asset(
              speaking ? BabyAnimations.speaking : BabyAnimations.idle,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => _stillBabyHead(),
            ),
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
    'assets/allobaby/AlloMombabySquare.png',
    fit: BoxFit.contain,
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

/// The glow behind the baby: four discs in the theme's
/// pinks, blurred until they read as one wash — the Ask Allo orb's nebula in
/// Allomom's own colours.
class BabyThemeNebula extends StatelessWidget {
  const BabyThemeNebula({super.key});

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

/// The baby peeking over the top edge of a bottom sheet, hands on the rim,
/// as in the AlloMom designs' Log Food sheet.
///
/// Wraps the sheet's own container: the sheet keeps its shape, and the baby
/// sits above it with the edge running under her chin. The sheet must be shown
/// on a transparent background (`showModalBottomSheet(backgroundColor:
/// Colors.transparent)`, as every sheet here already is) so the head shows
/// over the scrim rather than inside a white slab.
class BabySheetPeek extends StatelessWidget {
  const BabySheetPeek({super.key, required this.child, this.babyWidth = 120});

  final Widget child;
  final double babyWidth;

  static const asset = 'assets/allobaby/bottomsheetbaby.png';
  static const babyKey = Key('babySheetPeekBaby');

  // The drawing inside the 2400 × 1200 canvas, measured from its alpha.
  static const _contentWidth = 910 / 2400;
  static const _contentHeight = 726 / 1200;
  static const _contentAspect = 910 / 726;

  /// Where the sheet's edge meets her: just under the chin, so the hands rest
  /// on the rim.
  static const _edgeAt = 0.88;

  double get _babyHeight => babyWidth / _contentAspect;

  @override
  Widget build(BuildContext context) {
    final above = _babyHeight * _edgeAt;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: EdgeInsets.only(top: above), child: child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: SizedBox(
                key: babyKey,
                width: babyWidth,
                height: _babyHeight,
                // The canvas has a wide transparent margin; clip to the
                // drawing so the size above is the baby's, not the margin's.
                child: ClipRect(
                  child: OverflowBox(
                    maxWidth: babyWidth / _contentWidth,
                    maxHeight: _babyHeight / _contentHeight,
                    alignment: const Alignment(-0.0164, -0.422),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The baby's line inside a bottom sheet: a soft pink box with a heart, her
/// words and the speaker — the sheet-sized partner of [BabySheetPeek].
///
/// Takes the same narration as [BabyPromptBar], which it replaces in sheets:
/// the line plays when the sheet opens and the speaker replays or stops it.
class BabySheetPrompt extends StatelessWidget {
  const BabySheetPrompt({
    super.key,
    this.text = '',
    this.narrationKey,
    this.onSpeakerTap,
    this.margin = EdgeInsets.zero,
  });

  final String text;
  final String? narrationKey;
  final VoidCallback? onSpeakerTap;
  final EdgeInsetsGeometry margin;

  static const promptKey = Key('babySheetPrompt');

  @override
  Widget build(BuildContext context) {
    final key = narrationKey;
    final Widget body = key == null
        ? _build(context, text, onSpeakerTap, false)
        : BabyNarration(
            narrationKey: key,
            fallbackText: text,
            builder: (context, state) => _build(
              context,
              state.text,
              state.onSpeakerTap,
              state.speaking,
            ),
          );
    return BabyOnScreen(child: body);
  }

  Widget _build(
    BuildContext context,
    String label,
    VoidCallback? speakerTap,
    bool speaking,
  ) {
    final p = context.palette;
    const rose = Color(0xFFFF4E6A);
    return Container(
      key: promptKey,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: p.pick(const Color(0xFFFFF1F4), rose.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: p.pick(const Color(0xFFFFD3DC), rose.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.pick(Colors.white, p.card),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rose.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded, color: rose, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label.replaceAll('\n', ' '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: p.pick(const Color(0xFF2D3142), p.textPrimary),
                height: 1.4,
              ),
            ),
          ),
          if (speakerTap != null) ...[
            const SizedBox(width: 10),
            NarrationSpeakerButton(onTap: speakerTap, speaking: speaking),
          ],
        ],
      ),
    );
  }
}
