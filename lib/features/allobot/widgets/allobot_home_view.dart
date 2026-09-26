/// The pieces of AlloKonnect's AlloBot "Ask AI" screen, ported for Allomom:
/// the animated Gemini orb, the "Try asking" chips and the Features slider.
///
/// The layout is AlloKonnect's `AllobotEmptyState` part for part. Only the
/// contents are Allomom's own — the baby sits in the orb's glass core where
/// AlloKonnect has its 3D bot, the chips carry icons for Allomom's topics, and
/// the slider opens the helpers in [AlloBotFeatureCatalog].
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/components/baby_animations.dart';
import 'package:allomom/components/baby_bottom_avatar.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/allobot/data/allobot_feature_catalog.dart';
import 'package:allomom/features/allobot/widgets/allobot_welcome_view.dart'
    show GradientText;
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

// ── Opening suggestions ───────────────────────────────────────────────────

/// The "Try asking" questions shown before she has asked anything: a random
/// draw from the downloaded catalogue's triggers, or a few standing questions
/// while it has too few.
List<String> alloBotOpeningSuggestions(OfflineChatbotController controller) {
  final triggers = controller.sampleTriggers(limit: 10, randomize: true);
  if (triggers.length >= 3) return triggers;

  final pool = <String>[
    'How is my baby this week?',
    'What should I eat today?',
    'Show my health vitals',
    'When is my next checkup?',
    'Open my reports',
    'My baby is kicking',
    'My baby is crying',
    'What can you do?',
  ]..shuffle();
  return pool.take(6).toList();
}

// ── Hero line ─────────────────────────────────────────────────────────────

/// The blue-violet-rose wash the baby's words are painted in.
const LinearGradient alloBotHeroGradient = LinearGradient(
  colors: [Color(0xFF4285F4), Color(0xFF9B51E0), Color(0xFFE25584)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Markdown markers read as noise in the heading style, and the gradient
/// mask flattens emoji into solid blobs, so both are dropped.
final RegExp _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}]',
  unicode: true,
);

String alloBotPlainText(String markdown) => markdown
    .replaceAll(_emoji, '')
    .replaceAll(RegExp(r'[*_`#>]+'), '')
    .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1) ?? '')
    .trim();

/// What the baby is saying, as a gradient headline under the orb — Ask Allo's
/// reply and Home's weekly lines alike. Short lines read as a headline; longer
/// ones step down to fit, and scroll past [maxHeight].
class AlloBotHeroLine extends StatelessWidget {
  const AlloBotHeroLine({super.key, required this.text, this.maxHeight = 220});

  final String text;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final plain = alloBotPlainText(text);
    final fontSize = plain.length <= 60
        ? 24.0
        : plain.length <= 140
        ? 20.0
        : 17.0;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: GradientText(
          text: plain,
          gradient: alloBotHeroGradient,
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

// ── Gemini orb ────────────────────────────────────────────────────────────

/// The nebula of four blurred discs, turning slowly behind the baby — the
/// same baby as the Home banner, standing straight on the glow rather than in
/// a disc. While she is thinking or speaking the nebula spins and breathes
/// faster, glows harder and ripples outward, and the baby plays the Home
/// banner's own animations.
class AlloBotGeminiOrb extends StatefulWidget {
  const AlloBotGeminiOrb({
    super.key,
    this.isSpeaking = false,
    this.isThinking = false,
  });

  /// A line is being read out: the baby's mouth moves.
  final bool isSpeaking;

  /// A reply is being worked out: the baby idles and blinks.
  final bool isThinking;

  bool get isTalking => isSpeaking || isThinking;

  @override
  State<AlloBotGeminiOrb> createState() => _AlloBotGeminiOrbState();
}

class _AlloBotGeminiOrbState extends State<AlloBotGeminiOrb>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  late final AnimationController _blobController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  );
  late final AnimationController _talkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _blobScale = Tween<double>(
    begin: 0.8,
    end: 1.2,
  ).animate(CurvedAnimation(parent: _blobController, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _applyTalking();
  }

  @override
  void didUpdateWidget(covariant AlloBotGeminiOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTalking != widget.isTalking) _applyTalking();
  }

  void _applyTalking() {
    final talking = widget.isTalking;
    _rotateController
      ..duration = Duration(seconds: talking ? 4 : 16)
      ..repeat();
    _blobController
      ..duration = Duration(milliseconds: talking ? 900 : 3500)
      ..repeat(reverse: true);
    if (talking) {
      _talkController.repeat();
    } else {
      _talkController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _blobController.dispose();
    _talkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotateController,
          _blobController,
          _talkController,
        ]),
        builder: (context, child) {
          final talking = widget.isTalking;
          final t = _talkController.value;
          // The glow swells on a quick beat while talking.
          final glowBoost = talking
              ? 1.25 + math.sin(t * 2 * math.pi) * 0.08
              : 1.0;
          final grow = _blobScale.value * glowBoost;
          final shrink = (2.0 - _blobScale.value) * glowBoost;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // The shifting nebula.
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 32.0, sigmaY: 32.0),
                  child: Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Stack(
                      children: [
                        _blob(
                          const Alignment(-0.5, -0.5),
                          90 * grow,
                          const Color(0xFF4285F4),
                          0.85,
                        ),
                        _blob(
                          const Alignment(0.5, 0.5),
                          85 * shrink,
                          const Color(0xFF9B51E0),
                          0.85,
                        ),
                        _blob(
                          const Alignment(0.5, -0.5),
                          80 * grow,
                          const Color(0xFFE25584),
                          0.85,
                        ),
                        _blob(
                          const Alignment(-0.5, 0.5),
                          75 * shrink,
                          const Color(0xFF2DD4BF),
                          0.75,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Ripples out of the core while talking.
              if (talking)
                for (final phase in const [0.0, 0.5])
                  Builder(
                    builder: (context) {
                      final p = (t + phase) % 1.0;
                      return Container(
                        width: 92 + p * 64,
                        height: 92 + p * 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: (1.0 - p) * 0.7,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),

              // The baby, as on the Home banner.
              SizedBox(
                width: 150,
                height: 150,
                child: BabyOnScreen(child: _buildBaby()),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The Home banner's baby: breathing and blinking at rest, talking while
  /// speaking. The square still shares the clips' framing and is only the
  /// fallback if a clip fails to decode.
  Widget _buildBaby() {
    final still = Image.asset(
      'assets/allobaby/AlloMombabySquare.png',
      fit: BoxFit.contain,
    );
    return Image.asset(
      widget.isSpeaking ? BabyAnimations.speaking : BabyAnimations.idle,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => still,
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

// ── Try asking chip ───────────────────────────────────────────────────────

/// One "Try asking" chip: a small topic icon and the question.
class AlloBotSuggestionChip extends StatelessWidget {
  const AlloBotSuggestionChip({
    super.key,
    required this.text,
    required this.onTap,
    this.large = false,
  });

  final String text;
  final ValueChanged<String> onTap;

  /// The bigger size a flow option is shown in, when the options are the
  /// only thing on screen to answer with.
  final bool large;

  /// Keyword → icon and colour. First match wins.
  static const List<(List<String>, IconData, Color)> _icons = [
    (['kick', 'move', 'moving'], Icons.child_care_rounded, Color(0xFFFF4E6A)),
    (['cry', 'crying'], Icons.hearing_rounded, Color(0xFFF59E0B)),
    (
      ['eat', 'food', 'diet', 'meal', 'nutrition', 'drink', 'water'],
      Icons.restaurant_rounded,
      Color(0xFF10B981),
    ),
    (
      ['feed', 'breast', 'bottle', 'milk'],
      Icons.local_drink_rounded,
      Color(0xFF0EA5E9),
    ),
    (['sleep', 'nap', 'rest'], Icons.bedtime_rounded, Color(0xFF8B5CF6)),
    (
      ['report', 'prescription', 'document', 'scan', 'test'],
      Icons.description_rounded,
      Color(0xFF6366F1),
    ),
    (
      ['checkup', 'appointment', 'doctor', 'visit', 'anc', 'vaccine'],
      Icons.event_available_rounded,
      Color(0xFF3B82F6),
    ),
    (
      [
        'vital',
        'health',
        'heart',
        'blood',
        'pressure',
        'sugar',
        'weight',
        'temperature',
        'oxygen',
      ],
      Icons.monitor_heart_rounded,
      Color(0xFFEF4444),
    ),
    (
      ['baby', 'week', 'pregnan'],
      Icons.pregnant_woman_rounded,
      Color(0xFFE25584),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final lower = text.toLowerCase();
    final match = _icons
        .where((entry) => entry.$1.any(lower.contains))
        .firstOrNull;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(text);
      },
      child: Container(
        padding: large
            ? const EdgeInsets.symmetric(horizontal: 26, vertical: 14)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(large ? 30 : 20),
          border: Border.all(
            color: large
                ? primaryColor.withValues(alpha: isDark ? 0.45 : 0.35)
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              match?.$2 ?? Icons.auto_awesome_rounded,
              size: large ? 20 : 14,
              color: match?.$3 ?? primaryColor,
            ),
            SizedBox(width: large ? 8 : 6),
            Text(
              text,
              style: TextStyle(
                color: large
                    ? (isDark ? Colors.white : Colors.grey.shade800)
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
                fontSize: large ? 16 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Features slider ───────────────────────────────────────────────────────

/// The row of square glass tiles under "Features", one per helper.
class AlloBotFeatureSlider extends StatelessWidget {
  const AlloBotFeatureSlider({
    super.key,
    this.itemSize = 108,
    this.onFeatureOpened,
  });

  /// Width and height of each tile; the icon and label scale with it.
  final double itemSize;

  /// Called once a feature's page has been closed.
  final VoidCallback? onFeatureOpened;

  @override
  Widget build(BuildContext context) {
    final features = AlloBotFeatureCatalog.all;
    return SizedBox(
      height: itemSize,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        itemCount: features.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: itemSize,
          child: _FeatureTile(
            feature: features[index],
            scale: itemSize / 115,
            onOpened: onFeatureOpened,
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.feature,
    required this.scale,
    this.onOpened,
  });

  final AlloBotFeature feature;

  /// Relative to AlloKonnect's default 115px card.
  final double scale;
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final image = feature.image;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? p.card.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: p.pick(Colors.black, Colors.white).withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            HapticFeedback.lightImpact();
            await AlloBotFeatureCatalog.open(context, feature);
            onOpened?.call();
          },
          child: Padding(
            padding: EdgeInsets.all(10 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 52 * scale,
                  width: 52 * scale,
                  child: Center(
                    child: image != null
                        ? Image.asset(
                            image,
                            height: 50 * scale,
                            width: 50 * scale,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              feature.icon,
                              size: 34 * scale,
                              color: feature.color,
                            ),
                          )
                        : Icon(
                            feature.icon,
                            size: 34 * scale,
                            color: feature.color,
                          ),
                  ),
                ),
                SizedBox(height: 10 * scale),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    feature.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
