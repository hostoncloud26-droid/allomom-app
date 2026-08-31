import 'package:flutter/material.dart';

enum SpeechBubblePosition { left, right, topCenter, none }

class BabyHeroBanner extends StatelessWidget {
  final String speechText;
  final String greetingText;
  final SpeechBubblePosition bubblePosition;
  final double height;
  final double? babyHeight;
  final VoidCallback? onTap;

  const BabyHeroBanner({
    super.key,
    required this.speechText,
    this.greetingText = "",
    this.bubblePosition = SpeechBubblePosition.topCenter,
    this.height = 270,
    this.babyHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFFFFF2F5),
          border: Border.all(color: const Color(0xFFFFE2E8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A9E).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Background pattern image with hearts/clouds
              Positioned.fill(
                child: Image.asset(
                  'assets/allobaby/AllomomBg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF5F7), Color(0xFFFFE6ED)],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Baby Character at bottom (moderate proportional size)
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: babyHeight ?? (height <= 270 ? 160 : 180),
                    child: Image.asset(
                      'assets/allobaby/AlloMombaby.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 110,
                          color: Color(0xFFFF6584),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Speech Bubble - Top Center positioned (Chat bubble with tail pointing down)
              if (bubblePosition == SpeechBubblePosition.topCenter && speechText.isNotEmpty)
                Positioned(
                  top: 22,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: _buildSpeechBubble(context, speechText),
                  ),
                ),

              // Speech Bubble - Left positioned
              if (bubblePosition == SpeechBubblePosition.left && speechText.isNotEmpty)
                Positioned(
                  top: 22,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: _buildSpeechBubble(context, speechText),
                  ),
                ),

              // Speech Bubble - Right positioned
              if (bubblePosition == SpeechBubblePosition.right && speechText.isNotEmpty)
                Positioned(
                  top: 22,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: _buildSpeechBubble(context, speechText),
                  ),
                ),

              // Optional Bottom Greeting text (only shown if non-empty)
              if (greetingText.isNotEmpty)
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 16,
                  child: Text(
                    greetingText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(BuildContext context, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: CustomPaint(
        painter: _ChatBubbleTailPainter(
          color: Colors.white,
          shadowColor: const Color(0xFFFF8A9E).withValues(alpha: 0.16),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3142),
              height: 1.45,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubbleTailPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _ChatBubbleTailPainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 22.0;
    const double tailWidth = 16.0;
    const double tailHeight = 8.0;

    final Path path = Path();
    final bubbleRect = Rect.fromLTWH(0, 0, size.width, size.height - tailHeight);
    path.addRRect(RRect.fromRectAndRadius(bubbleRect, const Radius.circular(radius)));

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
