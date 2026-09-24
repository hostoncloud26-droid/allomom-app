/// The face of Ask Allo — AlloBaby's AlloBot screen, part for part.
///
/// A port of `allobotold/allobot.dart` from AlloBaby: the nebula orb, the
/// gradient greeting, the "Try asking:" chip row and the shimmer-bordered card
/// strip. Only the strip's contents differ — AlloBaby offers pregnancy tips,
/// and here the cards open the app's own helpers (see
/// [AlloBotFeatureCatalog]), which is what she came to this screen for.
///
/// Nothing here talks to the chatbot. The view is handed its line and its
/// taps; the tab it sits in keeps every bit of the voice and flow logic.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/allobot/data/allobot_feature_catalog.dart';

/// The headline half of Ask Allo: the orb, the greeting and, under them, the
/// [AlloBotTryAskingBlock] shared with the conversation view.
class AlloBotWelcomeView extends StatelessWidget {
  const AlloBotWelcomeView({
    super.key,
    required this.title,
    required this.message,
    required this.suggestions,
    required this.onSuggestionTap,
    this.onFeatureOpened,
  });

  /// The gradient headline — "Hello! I am AlloBaby".
  final String title;

  /// The grey line under it: her opening words when she has said something,
  /// otherwise the standing description of what she is for.
  final String message;

  /// The prompt chips: the quick replies a flow is waiting on, or the opening
  /// questions drawn from the downloaded catalogue.
  final List<String> suggestions;

  /// Asks the chip's question.
  final ValueChanged<String> onSuggestionTap;

  /// Called after a card's page has been closed, so the tab can refresh.
  final VoidCallback? onFeatureOpened;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Centred, as AlloBaby has it: on a tall phone the whole block sits in the
    // middle of the screen, and on a short one it scrolls instead.
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AlloBotOrb(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientText(
                text: title,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4285F4),
                    Color(0xFF9B51E0),
                    Color(0xFFE25584),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  color: p.pick(const Color(0xFF6B7280), p.textSecondary),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            AlloBotTryAskingBlock(
              suggestions: suggestions,
              onSuggestionTap: onSuggestionTap,
              onFeatureOpened: onFeatureOpened,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Try asking ────────────────────────────────────────────────────────────

/// The heading, the category chips, the feature cards and the prompt chips.
///
/// Shown in both states of the tab, not just the welcome one: she came here to
/// reach these, and they used to disappear the moment a conversation started.
/// It sizes to its contents so the conversation view can sit it under the
/// reply card.
class AlloBotTryAskingBlock extends StatefulWidget {
  const AlloBotTryAskingBlock({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    this.onFeatureOpened,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback? onFeatureOpened;

  @override
  State<AlloBotTryAskingBlock> createState() => _AlloBotTryAskingBlockState();
}

class _AlloBotTryAskingBlockState extends State<AlloBotTryAskingBlock> {
  FeatureCategory _selected = FeatureCategory.all;

  /// The gutter the rows start at. The lists themselves run the full width, so
  /// a strip that overflows is cut off by the screen edge rather than by a
  /// margin — which is what shows there is more of it to scroll.
  static const EdgeInsets _gutter = EdgeInsets.symmetric(horizontal: 24);

  Future<void> _open(AlloBotFeature feature) async {
    await AlloBotFeatureCatalog.open(context, feature);
    if (!mounted) return;
    widget.onFeatureOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final features = AlloBotFeatureCatalog.inCategory(_selected);
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: _gutter,
          child: Text(
            'Try asking:',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: p.pick(const Color(0xFF374151), p.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Category chips ──
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: _gutter,
            itemCount: FeatureCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = FeatureCategory.values[index];
              return _CategoryChip(
                label: category.chipLabel,
                selected: _selected == category,
                onTap: () => setState(() => _selected = category),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── The cards ──
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: _gutter,
            itemCount: features.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final feature = features[index];
              return FeatureSuggestionCard(
                feature: feature,
                onTap: () => _open(feature),
              );
            },
          ),
        ),

        // ── The questions she can tap instead of speaking ──
        //
        // The cards open a page; these ask her something, which is the other
        // half of "try asking".
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          AskSuggestionStrip(
            suggestions: widget.suggestions,
            onTap: widget.onSuggestionTap,
            padding: _gutter,
          ),
        ],
      ],
    );
  }
}

// ── Prompt chips ──────────────────────────────────────────────────────────

/// The questions she can tap instead of speaking.
///
/// Shared: the welcome view puts them under its cards, and the conversation
/// view keeps them where they have always been, just above the mic.
class AskSuggestionStrip extends StatelessWidget {
  const AskSuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = suggestions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap(prompt);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: p.pick(const Color(0xFFFFD2DC), p.accentBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      prompt,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.pick(const Color(0xFF474A57), p.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFFFF4E6A);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_primary, Color(0xFFFF7A8B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : p.pick(const Color(0xFFE5E7EB), p.border),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? Colors.white : p.pick(const Color(0xFF4B5563), p.textSecondary),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gradient text ─────────────────────────────────────────────────────────

class GradientText extends StatelessWidget {
  const GradientText({
    super.key,
    required this.text,
    required this.gradient,
    required this.style,
  });

  final String text;
  final Gradient gradient;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

// ── The orb ───────────────────────────────────────────────────────────────

/// Four coloured blobs blurred into one glow, with the baby sitting on it.
///
/// Still: AlloBaby turns the nebula and breathes the figure in and out, and
/// this screen does neither — the orb is a picture, not a performance.
///
/// [size] lets the tab shrink it once the conversation has started, where the
/// reply needs the room more than the orb does.
class AlloBotOrb extends StatelessWidget {
  const AlloBotOrb({super.key, this.size = 200});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Everything inside is drawn against the 200px original, so a smaller orb
    // is the same picture rather than a re-tuned one.
    final scale = size / 200;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The nebula: four discs, blurred until they read as one wash.
          Positioned.fill(
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
                    const Color(0xFF4285F4),
                    0.85,
                  ),
                  _blob(
                    const Alignment(0.5, 0.5),
                    85 * scale,
                    const Color(0xFF9B51E0),
                    0.85,
                  ),
                  _blob(
                    const Alignment(0.5, -0.5),
                    80 * scale,
                    const Color(0xFFE25584),
                    0.85,
                  ),
                  _blob(
                    const Alignment(-0.5, 0.5),
                    75 * scale,
                    const Color(0xFF2DD4BF),
                    0.75,
                  ),
                ],
              ),
            ),
          ),

          // The baby. No disc behind her: she sits straight on the nebula,
          // which is why she can be bigger than the 92px core used to allow.
          Image.asset(
            'assets/allobaby/AlloMombabySquare.png',
            width: 108 * scale,
            height: 108 * scale,
            fit: BoxFit.contain,
          ),
        ],
      ),
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

// ── Shimmering gradient border ────────────────────────────────────────────

class ShimmerGradientBorder extends StatefulWidget {
  const ShimmerGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
  });

  final Widget child;
  final double borderRadius;

  @override
  State<ShimmerGradientBorder> createState() => _ShimmerGradientBorderState();
}

class _ShimmerGradientBorderState extends State<ShimmerGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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
        return Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              colors: [
                const Color(0xFF4285F4).withValues(alpha: 0.8),
                const Color(0xFF9B51E0).withValues(alpha: 0.8),
                const Color(0xFFE25584).withValues(alpha: 0.8),
                const Color(0xFF4285F4).withValues(alpha: 0.8),
              ],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - 1.5),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ── Feature card ──────────────────────────────────────────────────────────

/// One card in the strip: the same shape and shimmer as AlloBaby's tip cards,
/// filled with a feature instead.
///
/// AlloBaby lays white text over a photograph. The features have no
/// photographs — a few have a 3D illustration on a transparent background, the
/// rest only an icon — so the card is a wash in the feature's own colour with
/// dark text, which reads the same either way.
class FeatureSuggestionCard extends StatefulWidget {
  const FeatureSuggestionCard({
    super.key,
    required this.feature,
    required this.onTap,
  });

  final AlloBotFeature feature;
  final VoidCallback onTap;

  @override
  State<FeatureSuggestionCard> createState() => _FeatureSuggestionCardState();
}

class _FeatureSuggestionCardState extends State<FeatureSuggestionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;
    final p = context.palette;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: ShimmerGradientBorder(
        borderRadius: 18.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..scaleByDouble(
              _pressed ? 0.98 : 1.0,
              _pressed ? 0.98 : 1.0,
              1.0,
              1.0,
            ),
          transformAlignment: Alignment.center,
          width: 165,
          height: 145,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16.5),
          ),
          child: Stack(
            children: [
              // The feature's colour, washing out towards the text.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        feature.color.withValues(alpha: 0.22),
                        feature.color.withValues(alpha: 0.06),
                        p.card,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Center(child: _artwork(feature))),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                feature.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                feature.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  height: 1.25,
                                  color: p.pick(const Color(0xFF8E95A5), p.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 14,
                          color: feature.color.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The illustration where there is one, and a tinted icon where there is not.
  Widget _artwork(AlloBotFeature feature) {
    final p = context.palette;
    final image = feature.image;
    if (image != null) {
      return Image.asset(image, height: 62, fit: BoxFit.contain);
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: p.pick(Colors.white, p.surface).withValues(alpha: 0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: feature.color.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(feature.icon, size: 26, color: feature.color),
    );
  }
}
