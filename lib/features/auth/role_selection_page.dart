import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/widgets/baby_speech_avatar.dart';
import 'package:allomom/features/auth/contact_number_page.dart';

class RoleSelectionPage extends StatefulWidget {
  final String selectedLanguage;

  const RoleSelectionPage({
    super.key,
    this.selectedLanguage = 'en',
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String _selectedRole = 'Mom'; // 'Mom' or 'Dad'

  @override
  Widget build(BuildContext context) {
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
                      'Select Your Role',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance left arrow
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── BABY SPEECH AVATAR ───
            BabySpeechAvatar(
              speechText: 'Yay! Are you my Mommy or my\nDaddy? 👶✨',
              onSpeakerTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing baby voice...'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
            ),

            const Spacer(),

            // ─── BOTTOM SELECTION CONTAINER ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                    'I am a:',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2 Large Role Cards
                  Row(
                    children: [
                      // Mom Card
                      Expanded(
                        child: _buildRoleCard(
                          role: 'Mom',
                          iconBg: const Color(0xFFFFE4E9),
                          avatarColor: const Color(0xFFFF4E6A),
                          isFemale: true,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Dad Card
                      Expanded(
                        child: _buildRoleCard(
                          role: 'Dad',
                          iconBg: const Color(0xFFDBEAFE),
                          avatarColor: const Color(0xFF2563EB),
                          isFemale: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ─── PROCEED BUTTON ───
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContactNumberPage(
                              selectedLanguage: widget.selectedLanguage,
                              selectedRole: _selectedRole,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5277),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Proceed',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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

  Widget _buildRoleCard({
    required String role,
    required Color iconBg,
    required Color avatarColor,
    required bool isFemale,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF4E6A).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Custom Avatar Icon Circle
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isFemale ? Icons.face_3_rounded : Icons.face_6_rounded,
                  color: isSelected ? const Color(0xFFFF4E6A) : avatarColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              role,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF1E2024),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
