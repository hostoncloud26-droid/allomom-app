import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/widgets/baby_speech_avatar.dart';
import 'package:allomom/features/auth/register_flow/join_family_code_page.dart';
import 'package:allomom/features/auth/register_flow/register_partner_details_page.dart';

class DadFamilySetupPage extends StatelessWidget {
  final String userName;
  final String phone;
  final String countryCode;
  final String selectedLanguage;

  const DadFamilySetupPage({
    super.key,
    required this.userName,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF5277);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP APP BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF1E2024),
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Family Setup',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── BABY SPEECH AVATAR ───
            BabySpeechAvatar(
              speechText: 'Welcome Daddy! 🌟\nDo you already have a Family Code?',
              onSpeakerTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing family guide...'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
            ),

            const Spacer(),

            // ─── BOTTOM CARD CONTAINER ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAMILY GROUP',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8E95A5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connect with Mom',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A 6-character family code lets you link directly with Mommy to access shared vitals, timeline, and pregnancy records.',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: const Color(0xFF6B7280),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Option A: Yes, I have a code
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JoinFamilyCodePage(
                              userName: userName,
                              phone: phone,
                              countryCode: countryCode,
                              selectedLanguage: selectedLanguage,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'I have a Family Code',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Option B: No code, create new family
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterPartnerDetailsPage(
                              userName: userName,
                              status: 'notpregnant',
                              eddDate: DateTime.now().add(const Duration(days: 280)),
                              lmpDate: null,
                              phone: phone,
                              countryCode: countryCode,
                              selectedRole: 'Dad',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.family_restroom_rounded, color: Color(0xFF4B5563), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "No, I'll set up Mommy's details",
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
