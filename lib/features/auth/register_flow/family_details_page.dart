// ignore_for_file: unused_import, unused_local_variable, unused_field
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/register_flow/kids_details_page.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/api/api_base.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class FamilyDetailsPage extends StatefulWidget {
  final String userName;
  final String status;

  /// Null when the mother is not pregnant — there is no due date to carry.
  final DateTime? eddDate;
  final DateTime? lmpDate;
  final int? averageCycleLength;
  final String? partnerName;
  final String? partnerPhone;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const FamilyDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.partnerName,
    this.partnerPhone,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  State<FamilyDetailsPage> createState() => _FamilyDetailsPageState();
}

class _FamilyDetailsPageState extends State<FamilyDetailsPage> {
  bool _hasKids = false; // default to No unless user taps Yes
  bool _isLoading = false;

  /// The journey she is on, which decides how the siblings question is asked
  /// and which "come, let's go home" plays at the end.
  late final NarrationFlow _flow = NarrationFlowKeys.of(widget.status);

  /// The line on the baby head card: the question, then the reaction to the
  /// answer she taps.
  late String _narrationKey = _flow.kids;

  Future<void> _handleNext() async {
    if (_hasKids) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KidsDetailsPage(
            userName: widget.userName,
            status: widget.status,
            eddDate: widget.eddDate,
            averageCycleLength: widget.averageCycleLength,
            lmpDate: widget.lmpDate,
            partnerName: widget.partnerName,
            partnerPhone: widget.partnerPhone,
            phone: widget.phone,
            countryCode: widget.countryCode,
            selectedRole: widget.selectedRole,
            familyCode: widget.familyCode,
            registerPregnancyForPartner: widget.registerPregnancyForPartner,
          ),
        ),
      );
    } else {
      setState(() {
        _isLoading = true;
      });

      try {
        // The account already exists — it was created when the OTP was
        // verified — so this completes the profile rather than signing up.
        // Partner details are deliberately not persisted: allomom-api-new has
        // no column for them.
        final isDad = widget.selectedRole.trim().toLowerCase() == 'dad';
        final main = MainController.instance;

        await main.saveRegistration(
          name: widget.userName,
          gender: isDad ? 'male' : 'female',
          markRegistered: false,
        );

        final isPregnant = pregnancyStatusForRegistration(
              widget.status,
              isDad: isDad,
              registeringForPartner: widget.registerPregnancyForPartner,
            ) ==
            pregnantStatus;

        if (isPregnant && widget.lmpDate != null) {
          // The server seeds the ANC, vaccination and report schedules off
          // this LMP.
          await PregnancyController.instance.createPregnancy(
            lmpDate: widget.lmpDate!,
            eddDate: widget.eddDate,
          );
        } else if (widget.lmpDate != null) {
          await main.updateHealthData({
            'lmp_date': SyncCodec.isoUtc(widget.lmpDate!),
          });
        }

        // Flipped last, so an interrupted run resumes the flow next sign-in
        // instead of landing on a home screen with no profile behind it.
        await main.completeRegistration();

        if (!mounted) return;
        // Plays across the jump to the home screen, which then greets her.
        speak(_flow.setupDone, force: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome, ${widget.userName}! Your family profile is ready.',
            ),
            backgroundColor: const Color(0xFFFF4E6A),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing registration: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

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
                    onTap: () => narratedPop(context),
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
                      'Family Details',
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
              narrationKey: _narrationKey,
              speechText:
                  'Do you already have sweet little\nbrothers or sisters for me? 👶',
            ),

            const SizedBox(height: 12),

            // ─── BOTTOM CARD CONTAINER ───
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DO YOU HAVE KIDS?',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8E95A5),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Option 1: Yes
                      _buildKidOption(
                        title: 'Yes',
                        subtitle: 'I have other children',
                        isSelected: _hasKids,
                        icon: Icons.child_care_rounded,
                        onTap: () => setState(() {
                          _hasKids = true;
                          _narrationKey = NarrationKeys.pregKidsYes;
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Option 2: No
                      _buildKidOption(
                        title: 'No',
                        subtitle: 'This is my first baby 💕',
                        isSelected: !_hasKids,
                        icon: Icons.favorite_rounded,
                        onTap: () => setState(() {
                          _hasKids = false;
                          _narrationKey = NarrationKeys.pregKidsNo;
                        }),
                      ),

                      const SizedBox(height: 24),

                      // ─── NEXT BUTTON ───
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5277),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _hasKids
                                      ? 'Next (Add Kids Details)'
                                      : 'Finish Setup',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKidOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E6A)
                : const Color(0xFFE5E7EB),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFD8E0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF4E6A), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
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
                      : const Color(0xFFD1D5DB),
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
