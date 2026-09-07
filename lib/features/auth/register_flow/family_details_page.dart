// ignore_for_file: unused_import, unused_local_variable, unused_field
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/widgets/baby_speech_avatar.dart';
import 'package:allomom/features/auth/register_flow/kids_details_page.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/services/api/auth_api.dart';
import 'package:allomom/services/api/api_base.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class FamilyDetailsPage extends StatefulWidget {
  final String userName;
  final String status;
  final DateTime eddDate;
  final DateTime? lmpDate;
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

  Future<void> _handleNext() async {
    if (_hasKids) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KidsDetailsPage(
            userName: widget.userName,
            status: widget.status,
            eddDate: widget.eddDate,
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
        final isDad = widget.selectedRole.trim().toLowerCase() == 'dad';
        final isPregnant = !isDad &&
            widget.status.toLowerCase().contains("pregnant") &&
            !widget.status.toLowerCase().contains("pre");

        final payload = {
          "name": widget.userName.trim(),
          "phone": widget.phone.trim(),
          "countryCode": widget.countryCode,
          "userRole": widget.selectedRole,
          "gender": isDad ? "male" : "female",
          "userType": isDad ? "dad" : "patient",
          "pregnancyStatus": isDad
              ? (widget.registerPregnancyForPartner ? "pregnant" : "notpregnant")
              : (isPregnant ? "pregnant" : "notpregnant"),
          "edDate": widget.eddDate.toIso8601String(),
          "lmpDate": widget.lmpDate?.toIso8601String(),
          if (widget.partnerName != null && widget.partnerName!.trim().isNotEmpty)
            "partnerName": widget.partnerName!.trim(),
          if (widget.partnerPhone != null && widget.partnerPhone!.trim().isNotEmpty)
            "partnerPhone": widget.partnerPhone!.trim(),
          if (widget.familyCode != null && widget.familyCode!.trim().isNotEmpty)
            "familyCode": widget.familyCode!.trim(),
          "registerPregnancyForPartner": widget.registerPregnancyForPartner,
        };

        String? registeredUserId;
        String? jwt;
        String? refresh;
        String? healthDataId;

        final res = await AuthApi.registerMother(payload);
        if (!res.success) {
          throw Exception(res.detail.isNotEmpty ? res.detail : "Registration failed. Please try again.");
        }

        if (res.item is Map) {
          final item = res.item as Map;
          registeredUserId = item["user_id"]?.toString() ?? res.id?.toString();
          jwt = item["jwt"]?.toString() ?? item["access_token"]?.toString();
          refresh = item["refresh"]?.toString();
          healthDataId = item["healthDataID"]?.toString();
        } else if (res.id != null) {
          registeredUserId = res.id.toString();
        }

        await UserSessionManager.instance.saveRegistration(
          name: widget.userName,
          phone: widget.phone,
          countryCode: widget.countryCode,
          pregnancyStatus: isPregnant ? "pregnant" : "notpregnant",
          eddDate: widget.eddDate,
          lmpDate: widget.lmpDate,
          partnerName: widget.partnerName,
          partnerPhone: widget.partnerPhone,
          hasKids: false,
          kidsCount: 0,
          userId: registeredUserId,
          jwt: jwt,
          refresh: refresh,
          healthDataId: healthDataId,
        );

        if (!mounted) return;
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
            BabySpeechAvatar(
              speechText:
                  'Do you already have sweet little\nbrothers or sisters for me? 👶',
              onSpeakerTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing siblings voice prompt...'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
            ),

            const Spacer(),

            // ─── BOTTOM CARD CONTAINER ───
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
                    onTap: () => setState(() => _hasKids = true),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: No
                  _buildKidOption(
                    title: 'No',
                    subtitle: 'This is my first baby 💕',
                    isSelected: !_hasKids,
                    icon: Icons.favorite_rounded,
                    onTap: () => setState(() => _hasKids = false),
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
