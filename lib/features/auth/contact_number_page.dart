// ignore_for_file: unused_import, unused_local_variable, unused_field
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/verify_otp_page.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/services/google_auth_service.dart';
import 'package:allomom/controllers/auth_controller.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

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
  AppPalette get _p => context.palette;

  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = '+91';
  bool _isLoading = false;

  /// What the baby head card is saying. Starts as the ask, and is swapped for
  /// the matching line when the number is short, the network is down, or she
  /// reaches for Google instead.
  String _narrationKey = NarrationKeys.onbMobile;

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
      _say(NarrationKeys.onbMobileInvalid);
      _showMessage('Please enter a valid 10-digit mobile number');
      return;
    }

    // The only step of the whole flow that needs a network. Say so before the
    // request times out, rather than after.
    if (!ConnectionController.instance.isInternetAvailable) {
      _say(NarrationKeys.onbMobileInternet);
      _showMessage(
        'This step needs the internet. Please check your connection.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthController.instance.sendOtp(
      phone,
      countryCode: _countryCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // A failed send used to fall through to the OTP screen anyway, which left
    // her typing a code that was never issued. Stay put and say what happened.
    if (error != null) {
      _say(
        ConnectionController.instance.isInternetAvailable
            ? NarrationKeys.onbMobileInvalid
            : NarrationKeys.onbMobileInternet,
      );
      _showMessage(error, isError: true);
      return;
    }

    final isTest = _testNumbers.contains(phone);
    _showMessage(
      isTest
          ? 'OTP sent to $_countryCode $phone (test code: 999777)'
          : 'OTP sent to $_countryCode $phone',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyOtpPage(
          phoneNumber: '$_countryCode $phone',
          rawPhone: phone,
          countryCode: _countryCode,
          selectedLanguage: widget.selectedLanguage,
        ),
      ),
    );
  }

  /// Swaps the line on the baby head card, replaying it even if that key has
  /// already been heard — an error the mother just hit is worth repeating.
  void _say(String key) {
    if (!mounted) return;
    setState(() => _narrationKey = key);
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(key, force: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFFFF4E6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
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
                              'Set Your Contact Number',
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
                    SizedBox(height: isKeyboardOpen ? 4 : 12),

                    // ─── BABY SPEECH AVATAR ───
                    Expanded(
                      child: BabyPrompt(
                        compact: isKeyboardOpen,
                        expand: true,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        narrationKey: _narrationKey,
                        text:
                            "What's your mobile number\nso I can stay close? 📱",
                      ),
                    ),

                    // ─── BOTTOM INPUT CONTAINER ───
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isKeyboardOpen ? 16 : 24,
                        24,
                        (isKeyboardOpen ? 16 : 24) +
                            MediaQuery.paddingOf(context).bottom,
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
                            'Your Contact Number:',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
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
                              color: _p.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _p.border,
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
                                    color: _p.inputFill,
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
                                          color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18,
                                        color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: _p.border,
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
                                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                      letterSpacing: 0.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '1234567890',
                                      hintStyle: GoogleFonts.poppins(
                                        color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
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
                              onTap: () {
                                _say(NarrationKeys.onbMobileGoogle);
                                _handleGoogleSignIn(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _p.pick(const Color(0xFFF3F4F6), _p.surface),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _p.border,
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
                                          color: _p.pick(const Color(0xFF374151), _p.textSecondary),
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

  /// Google sign-in is not wired up.
  ///
  /// allomom-api-new has no Google route: the only credential it accepts is a
  /// verified phone. The button is left in place for when one is added, but it
  /// says so plainly rather than failing silently against an endpoint that does
  /// not exist.
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Google sign-in is not available yet. Please continue with your '
          'mobile number.',
        ),
        backgroundColor: Color(0xFFFF4E6A),
      ),
    );
  }
}
