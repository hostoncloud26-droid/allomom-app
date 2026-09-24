import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/register_flow/register_name_page.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

/// Asked only of someone the backend did not recognise after OTP
/// verification — an existing user is signed straight in and never sees this.
/// The verified [phone] is carried through so registration does not have to
/// ask for it a second time.
class RoleSelectionPage extends StatefulWidget {
  final String selectedLanguage;
  final String phone;
  final String countryCode;

  const RoleSelectionPage({
    super.key,
    this.selectedLanguage = 'en',
    this.phone = '',
    this.countryCode = '+91',
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  AppPalette get _p => context.palette;

  String _selectedRole = 'Mom'; // 'Mom' or 'Dad'

  /// The question until she answers it, then the baby's delight at the answer.
  String _narrationKey = NarrationKeys.onbRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fills the viewport so the baby can expand into whatever the card
            // below does not claim, and scrolls instead of overflowing when the
            // card needs more room than the screen has.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // ─── TOP APP BAR ───
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => narratedPop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _p.card,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _p.pick(Colors.black12, _p.shadow),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
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
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), // Balance left arrow
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── BABY SPEECH AVATAR ───
                  Expanded(
                    child: BabyHeroBanner(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      expand: true,
                      narrationKey: _narrationKey,
                      speechText: 'Yay! Are you my Mommy or my\nDaddy? 👶✨',
                    ),
                  ),

                  // ─── BOTTOM SELECTION CONTAINER ───
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    decoration: BoxDecoration(
                      color: _p.card,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _p.pick(Colors.black12, _p.shadow),
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
                            color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
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
                                iconBg: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFE4E9)),
                                avatarColor: const Color(0xFFFF4E6A),
                                isFemale: true,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Dad Card
                            Expanded(
                              child: _buildRoleCard(
                                role: 'Dad',
                                iconBg: _p.tint(const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
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
                                  builder: (_) => RegisterNamePage(
                                    phone: widget.phone,
                                    countryCode: widget.countryCode,
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
                                Flexible(
                                  child: Text(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    'Proceed',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
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
          _narrationKey = role.trim().toLowerCase() == 'dad'
              ? NarrationKeys.onbRoleDad
              : NarrationKeys.onbRoleMom;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isSelected
              ? _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F3))
              : _p.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E6A)
                : _p.border,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF4E6A).withValues(alpha: 0.08)
                  : _p.pick(Colors.black.withValues(alpha: 0.02), _p.shadow),
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
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
                color: isSelected
                    ? const Color(0xFFFF4E6A)
                    : _p.pick(const Color(0xFF1E2024), _p.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
