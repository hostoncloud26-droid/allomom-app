import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                        color: const Color(0xFF1E2024),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSpeakerTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F3),
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
                painter: _BubblePointerPainter(),
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
            color: const Color(0xFFFFF0F5),
            border: Border.all(
              color: const Color(0xFFFFD2DC),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
