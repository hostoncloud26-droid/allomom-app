import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/register_flow/register_partner_details_page.dart';
import 'package:allomom/features/auth/register_flow/family_details_page.dart';

class RegisterEddDueDatePage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime lmpDate;
  final DateTime eddDate;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? partnerName;
  final String? partnerPhone;
  final bool registerPregnancyForPartner;

  const RegisterEddDueDatePage({
    super.key,
    required this.userName,
    required this.status,
    required this.lmpDate,
    required this.eddDate,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.partnerName,
    this.partnerPhone,
    this.registerPregnancyForPartner = false,
  });

  String _formatEddDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final eddString = _formatEddDate(eddDate);
    final daysRemaining = eddDate
        .difference(DateTime.now())
        .inDays
        .clamp(0, 280);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
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
                            'Your Due Date',
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
                  BabyHeroBanner(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    speechText:
                        'Yay! I can\'t wait to meet you on\n$eddString! 👶🎉',
                    onSpeakerTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing Due Date voice cheer...'),
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // ─── BOTTOM DUE DATE CARD CONTAINER ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
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
                          'ESTIMATED DUE DATE (EDD)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8E95A5),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Due Date Display Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF0F3), Color(0xFFFFE4E8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFFFD1DC),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.cake_rounded,
                                  color: Color(0xFFFF4E6A),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                eddString,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E2024),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4E6A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$daysRemaining Days to go!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── CONFIRM DUE DATE BUTTON ───
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedRole.trim().toLowerCase() == 'dad') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FamilyDetailsPage(
                                      userName: userName,
                                      status: 'pregnant',
                                      eddDate: eddDate,
                                      lmpDate: lmpDate,
                                      phone: phone,
                                      countryCode: countryCode,
                                      selectedRole: 'Dad',
                                      partnerName: partnerName,
                                      partnerPhone: partnerPhone,
                                      registerPregnancyForPartner: true,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterPartnerDetailsPage(
                                      userName: userName,
                                      status: status,
                                      eddDate: eddDate,
                                      lmpDate: lmpDate,
                                      phone: phone,
                                      countryCode: countryCode,
                                      selectedRole: selectedRole,
                                    ),
                                  ),
                                );
                              }
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
                                    'Confirm & Next',
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
}
