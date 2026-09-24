import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/allocry/screens/cry_listening_page.dart';

/// Shown when a session ended without the models hearing a cry.
///
/// Framed as "nothing to analyse yet" rather than a failure — the usual cause
/// is a quiet room or a chatty one, both of which she can fix and retry.
class CryNotDetectedPage extends StatelessWidget {
  const CryNotDetectedPage({super.key});

  static const Color _pink = Color(0xFFFF4E6A);

  static const List<String> _reasons = [
    'Hold the phone within an arm’s length of your baby.',
    'Record while the baby is actually crying, not just fussing.',
    'Keep the room quiet — talking and TV can mask the cry.',
    'Give it a few seconds; AlloCry listens for up to 22 seconds.',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: _pink),
                ),
              ),
              Image.asset(
                'assets/babyicons/RecordAgain.webp',
                height: MediaQuery.of(context).size.height * 0.28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.mic_off_rounded,
                  size: 110,
                  color: _pink,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hearing_disabled_rounded,
                    color: _pink, size: 44),
              ),
              const SizedBox(height: 22),
              Text(
                'No baby cry detected',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: p.pick(const Color(0xFF1E2229), p.textPrimary),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "AlloCry listened but didn't hear a cry it could read. "
                'Nothing was saved — try once more.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.6,
                  color: p.pick(const Color(0xFF6B7280), p.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF6F7)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.pick(const Color(0xFFFFE3E8), p.accentBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            size: 17, color: _pink),
                        const SizedBox(width: 8),
                        Text(
                          'For a better reading',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: p.pick(const Color(0xFF2C2F38), p.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final reason in _reasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(Icons.circle, size: 6, color: _pink),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reason,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: p.pick(const Color(0xFF4A4E5A), p.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => Get.off(() => const CryListeningPage()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.mic_rounded, color: Colors.white),
                  label: Text(
                    'Listen again',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  'Back to AlloCry',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.pick(const Color(0xFF8C93A3), p.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
