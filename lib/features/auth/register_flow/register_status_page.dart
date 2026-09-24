import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/register_flow/register_lmp_timeline_page.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class RegisterStatusPage extends StatefulWidget {
  final String userName;
  final String phone;
  final String countryCode;
  final String selectedLanguage;
  final String selectedRole;

  const RegisterStatusPage({
    super.key,
    required this.userName,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
    this.selectedRole = 'Mom',
  });

  @override
  State<RegisterStatusPage> createState() => _RegisterStatusPageState();
}

class _RegisterStatusPageState extends State<RegisterStatusPage> {
  AppPalette get _p => context.palette;

  String _selectedStatus = 'Pregnant'; // 'Pre Pregnancy', 'Pregnant', 'New Mom'

  /// The question, then the baby's reaction to where they are on the journey.
  String _narrationKey = NarrationKeys.onbStatus;

  /// The reaction line for a status option.
  static String narrationKeyForStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pre pregnancy':
        return NarrationKeys.onbStatusPrePregnancy;
      case 'new mom':
        return NarrationKeys.onbStatusNewMom;
      default:
        return NarrationKeys.onbStatusPregnant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fills the viewport so the Spacer can push the card to the
            // bottom, and scrolls instead of overflowing when the content or
            // an open keyboard needs more room than the screen has.
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
                            'Select Your Status',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
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
                      speechText:
                          'Tell me where we are on this magical journey! ✨',
                    ),
                  ),

                  // ─── BOTTOM CARD CONTAINER ───
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
                          'What describes you best?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Option 1: Pregnant
                        _buildStatusOption(
                          title: 'Pregnant',
                          subtitle: 'Expecting a Baby',
                          iconBg: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F3)),
                          iconColor: const Color(0xFFFF4E6A),
                          icon: Icons.pregnant_woman_rounded,
                        ),
                        const SizedBox(height: 12),

                        // Option 2: Pre Pregnancy
                        _buildStatusOption(
                          title: 'Pre Pregnancy',
                          subtitle: 'Planning for a Baby',
                          iconBg: _p.tint(const Color(0xFFC026D3), const Color(0xFFFAF5FF)),
                          iconColor: const Color(0xFFC026D3),
                          icon: Icons.child_care_rounded,
                        ),
                        const SizedBox(height: 12),

                        // Option 3: New Mom
                        _buildStatusOption(
                          title: 'New Mom',
                          subtitle: 'Caring for your Baby',
                          iconBg: _p.tint(const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                          iconColor: const Color(0xFF3B82F6),
                          icon: Icons.face_rounded,
                        ),

                        const SizedBox(height: 22),

                        // ─── NEXT BUTTON ───
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              speak(NarrationKeys.onbAlmostDone);
                              // Every status starts from the LMP: pregnant users get
                              // a due date from it, everyone else gets a next-period
                              // prediction. New Mom used to skip straight ahead with
                              // fabricated dates.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterLmpTimelinePage(
                                    userName: widget.userName,
                                    status: _selectedStatus,
                                    phone: widget.phone,
                                    countryCode: widget.countryCode,
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
                                    'Next',
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

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = title;
          _narrationKey = narrationKeyForStatus(title);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F3))
              : _p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E6A)
                : _p.border,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF4E6A).withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF4E6A)
                      : _p.pick(const Color(0xFFD1D5DB), _p.border),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFFFF4E6A)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
