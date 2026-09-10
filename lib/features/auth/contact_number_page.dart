// ignore_for_file: unused_import, unused_local_variable, unused_field
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/verify_otp_page.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/services/google_auth_service.dart';
import 'package:allomom/api/otp_api.dart';
import 'package:allomom/api/auth_api.dart';
import 'package:allomom/api/api_base.dart';
import 'package:allomom/repositories/user_session_manager.dart';

/// Step 2 of onboarding, straight after the language choice.
///
/// The role is deliberately not asked for here: an existing user signs
/// straight in after the OTP, so only someone the backend does not recognise
/// is ever asked whether she is Mom or Dad.
class ContactNumberPage extends StatefulWidget {
  final String selectedLanguage;

  const ContactNumberPage({super.key, this.selectedLanguage = 'en'});

  @override
  State<ContactNumberPage> createState() => _ContactNumberPageState();
}

class _ContactNumberPageState extends State<ContactNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = '+91';
  bool _isLoading = false;

  final List<String> _testNumbers = const [
    '9999999999',
    '8888888888',
    '7639744744',
    '1111122222',
    '9363286517',
    '9876543210',
    '1234567890',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '');
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await OtpApi.sendOtp(phone, _countryCode);
      if (!mounted) return;

      final otpId = res.id;
      final isTest = _testNumbers.contains(phone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTest
                ? 'OTP sent to $_countryCode $phone! (Test number OTP: 999777)'
                : (res.detail.isNotEmpty
                      ? res.detail
                      : 'OTP sent successfully to $_countryCode $phone'),
          ),
          backgroundColor: const Color(0xFFFF4E6A),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpPage(
            phoneNumber: '$_countryCode $phone',
            rawPhone: phone,
            countryCode: _countryCode,
            otpId: otpId,
            selectedLanguage: widget.selectedLanguage,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notice: $e - proceeding with verification'),
            backgroundColor: const Color(0xFFFF4E6A),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpPage(
              phoneNumber: '$_countryCode $phone',
              rawPhone: phone,
              countryCode: _countryCode,
              otpId: null,
              selectedLanguage: widget.selectedLanguage,
            ),
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

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
              // Fills the viewport so the Spacer below can push the form card
              // to the bottom, yet still scrolls when the keyboard leaves less
              // room than the content needs. `IntrinsicHeight` cannot do this:
              // it does not support flex children, which is why the card used
              // to stretch and leave a large blank area.
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
                              'Set Your Contact Number',
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
                    SizedBox(height: isKeyboardOpen ? 4 : 12),

                    // ─── BABY SPEECH AVATAR ───
                    BabyPrompt(
                      compact: isKeyboardOpen,
                      text:
                          "What's your mobile number\nso I can stay close? 📱",
                      onSpeakerTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Playing voice prompt...'),
                            duration: Duration(milliseconds: 1000),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // ─── BOTTOM INPUT CONTAINER ───
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: isKeyboardOpen ? 16 : 24,
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
                            'Your Contact Number:',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          SizedBox(height: isKeyboardOpen ? 8 : 14),

                          // Phone Input Field Box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Country code badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🇮🇳',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _countryCode,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E2024),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                const SizedBox(width: 12),

                                // Phone Number TextField
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E2024),
                                      letterSpacing: 0.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '1234567890',
                                      hintStyle: GoogleFonts.poppins(
                                        color: const Color(0xFF9CA3AF),
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),

                                // Phone icon
                                const Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFFFF7E95),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isKeyboardOpen ? 14 : 20),

                          // ─── SEND OTP BUTTON ───
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSendOtp,
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
                                      'Send OTP Code',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          SizedBox(height: isKeyboardOpen ? 10 : 14),

                          // ─── OR GOOGLE SIGN IN ───
                          Center(
                            child: GestureDetector(
                              onTap: () => _handleGoogleSignIn(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'G',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF4285F4),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Flexible so a narrow screen or a wide
                                    // font fallback ellipsises instead of
                                    // overflowing the pill.
                                    Flexible(
                                      child: Text(
                                        'Continue with Google',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF374151),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final account = await GoogleAuthService.signIn();
      if (account != null && context.mounted) {
        final auth = await account.authentication;
        if (auth.idToken != null) {
          final res = await AuthApi.authGoogle(auth.idToken!);
          if (res.success && res.item is Map) {
            final item = res.item as Map;
            final jwt = item["jwt"]?.toString() ?? "";
            if (jwt.isNotEmpty) {
              await ApiBase.setJwt(jwt);
            }
            if (item["refresh"] != null) {
              await ApiBase.setRefreshToken(item["refresh"].toString());
            }
            await UserSessionManager.instance.fetchUser();
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome, ${account.displayName ?? account.email}!',
              ),
              backgroundColor: const Color(0xFFFF4E6A),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainLayout()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
