import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:allomom/config/app_theme.dart';

class BabySpeechAvatar extends StatelessWidget {
  final String speechText;
  final VoidCallback? onSpeakerTap;
  final double avatarSize;

  const BabySpeechAvatar({
    super.key,
    required this.speechText,
    this.onSpeakerTap,
    this.avatarSize = 190,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = avatarSize < 140;
    final p = context.palette;

    return Column(
      children: [
        // ─── SPEECH BUBBLE ───
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: isCompact ? 10 : 14,
              ),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: p.pick(Colors.black.withValues(alpha: 0.04), p.shadow),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      speechText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isCompact ? 12.5 : 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSpeakerTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F3)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: Color(0xFFFF4E6A),
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Speech Bubble Pointer (Down Arrow)
            Positioned(
              bottom: -6,
              child: CustomPaint(
                size: const Size(14, 7),
                painter: _BubblePointerPainter(p.card),
              ),
            ),
          ],
        ),

        SizedBox(height: isCompact ? 8 : 16),

        // ─── CIRCULAR BABY HALO ───
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F5)),
            border: Border.all(
              color: p.pick(const Color(0xFFFFD2DC), p.accentBorder),
              width: isCompact ? 3.5 : 5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4E6A).withValues(alpha: 0.08),
                blurRadius: isCompact ? 14 : 24,
                offset: Offset(0, isCompact ? 4 : 8),
              ),
            ],
          ),
          child: Center(
            child: ClipOval(
              child: SizedBox(
                width: avatarSize * (150 / 190),
                height: avatarSize * (150 / 190),
                child: Lottie.asset(
                  'assets/animations/Baby Speaking F.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/allobaby/Baby3D.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.child_care_rounded,
                      size: avatarSize * 0.45,
                      color: const Color(0xFFFF4E6A),
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

class _BubblePointerPainter extends CustomPainter {
  final Color color;

  _BubblePointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
