import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/register_flow/family_details_page.dart';
import 'package:allomom/features/auth/register_flow/register_lmp_timeline_page.dart';

class RegisterPartnerDetailsPage extends StatefulWidget {
  final String userName;
  final String status;

  /// Null when the mother is not pregnant — there is no due date to carry.
  final DateTime? eddDate;
  final DateTime? lmpDate;

  /// Her average cycle length, captured on the cycle screen when she is not
  /// pregnant.
  final int? averageCycleLength;
  final String phone;
  final String countryCode;
  final String selectedRole;

  const RegisterPartnerDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
  });

  @override
  State<RegisterPartnerDetailsPage> createState() =>
      _RegisterPartnerDetailsPageState();
}

class _RegisterPartnerDetailsPageState
    extends State<RegisterPartnerDetailsPage> {
  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _partnerPhoneController = TextEditingController();
  final String _countryCode = '+91';

  bool get _isDad => widget.selectedRole.trim().toLowerCase() == 'dad';

  @override
  void dispose() {
    _partnerNameController.dispose();
    _partnerPhoneController.dispose();
    super.dispose();
  }

  void _promptRegisterPregnancy(String partnerName, String partnerPhone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE7F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF5277),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Register Mommy's Pregnancy?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Would you like to record Mommy's pregnancy timeline (LMP & expected due date) so you can track her journey together?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterLmpTimelinePage(
                          userName: widget.userName,
                          status: 'pregnant',
                          phone: widget.phone,
                          countryCode: widget.countryCode,
                          selectedRole: 'Dad',
                          partnerName: partnerName,
                          partnerPhone: partnerPhone,
                          registerPregnancyForPartner: true,
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
                  child: Text(
                    'Yes, Record Pregnancy',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FamilyDetailsPage(
                          userName: widget.userName,
                          status: 'notpregnant',
                          eddDate: widget.eddDate,
                          averageCycleLength: widget.averageCycleLength,
                          lmpDate: null,
                          partnerName: partnerName,
                          partnerPhone: partnerPhone,
                          phone: widget.phone,
                          countryCode: widget.countryCode,
                          selectedRole: 'Dad',
                          registerPregnancyForPartner: false,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'No, Continue Without Pregnancy',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onNext() {
    final pName = _partnerNameController.text.trim();
    final pPhone = _partnerPhoneController.text.trim();

    if (_isDad) {
      if (pName.isNotEmpty) {
        _promptRegisterPregnancy(pName, pPhone);
      } else {
        _goToFamilyDetails();
      }
    } else {
      _goToFamilyDetails();
    }
  }

  void _goToFamilyDetails() {
    final pName = _partnerNameController.text.trim();
    final pPhone = _partnerPhoneController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyDetailsPage(
          userName: widget.userName,
          status: _isDad ? 'notpregnant' : widget.status,
          eddDate: widget.eddDate,
          averageCycleLength: widget.averageCycleLength,
          lmpDate: widget.lmpDate,
          partnerName: pName.isNotEmpty ? pName : null,
          partnerPhone: pPhone.isNotEmpty ? pPhone : null,
          phone: widget.phone,
          countryCode: widget.countryCode,
          selectedRole: widget.selectedRole,
          registerPregnancyForPartner: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final speechText = _isDad
        ? 'Tell me about Mommy so she can be\npart of our journey too! 🌸'
        : 'Tell me about Daddy so he can be\npart of our journey too! 👨‍👩‍👦';

    final nameLabel = _isDad ? "MOMMY'S FULL NAME" : 'PARTNER FULL NAME';
    final nameHint = _isDad ? 'e.g. Ananya Kumar' : 'e.g. Anand Kumar';
    final phoneLabel = _isDad
        ? "MOMMY'S MOBILE NUMBER"
        : 'PARTNER MOBILE NUMBER';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // Fills the viewport so the Spacer can push the form card to the
              // bottom, and scrolls instead of overflowing once the keyboard
              // takes the space away.
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
                              'Partner Details',
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
                      height: isKeyboardOpen ? 150 : 260,
                      speechText: speechText,
                      onSpeakerTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Playing ${_isDad ? "Mommy" : "Daddy"} prompt...',
                            ),
                            duration: const Duration(milliseconds: 1000),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // ─── BOTTOM CARD CONTAINER ───
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
                            nameLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8E95A5),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Partner Name Input
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite_outline_rounded,
                                  color: Color(0xFFFF4E6A),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _partnerNameController,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E2024),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: nameHint,
                                      hintStyle: GoogleFonts.poppins(
                                        color: const Color(0xFF9CA3AF),
                                        fontSize: 14.5,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            phoneLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8E95A5),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Partner Phone Input
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _countryCode,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E2024),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _partnerPhoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E2024),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '9876543210',
                                      hintStyle: GoogleFonts.poppins(
                                        color: const Color(0xFF9CA3AF),
                                        fontSize: 14.5,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ─── NEXT & SKIP ROW ───
                          Row(
                            children: [
                              // Skip Button
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: _goToFamilyDetails,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                    child: Text(
                                      'Skip',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Next Button
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _onNext,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5277),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Next',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
