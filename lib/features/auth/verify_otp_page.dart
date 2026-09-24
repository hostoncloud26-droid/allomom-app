// ignore_for_file: unused_element, unused_field, unused_import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/auth/role_selection_page.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/controllers/auth_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class VerifyOtpPage extends StatefulWidget {
  final String phoneNumber;
  final String rawPhone;
  final String countryCode;
  final String selectedLanguage;

  const VerifyOtpPage({
    super.key,
    required this.phoneNumber,
    this.rawPhone = '9876543210',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  AppPalette get _p => context.palette;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _focusedIndex = 0;
  bool _isVerifying = false;
  bool _isResending = false;

  /// The line on the baby head card: the "I sent you a code" opener, then
  /// whichever of the OTP lines the mother's next step calls for.
  String _narrationKey = NarrationKeys.onbOtp;

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
  void initState() {
    super.initState();

    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() {
            _focusedIndex = i;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text.trim()).join();

  /// Puts [key] on the card and replays it even if it has been heard before.
  void _say(String key) {
    if (!mounted) return;
    setState(() => _narrationKey = key);
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(key, force: true);
    }
  }

  /// Verifies the code and routes on what the server says about registration.
  ///
  /// `is_registered` is the only thing that decides where she lands: false
  /// means the account exists but the profile was never completed, so she goes
  /// into the registration flow — including when she is returning to a sign-up
  /// she abandoned halfway. True goes straight to the main screen.
  Future<void> _handleVerifyOtp() async {
    final otpCode = _enteredOtp;
    if (otpCode.length < 6) {
      _say(NarrationKeys.onbOtpWrong);
      _showMessage('Please enter the full 6-digit code');
      return;
    }

    setState(() => _isVerifying = true);

    final outcome = await AuthController.instance.verifyOtp(
      phone: widget.rawPhone,
      otp: otpCode,
      countryCode: widget.countryCode,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    // A wrong or expired code keeps her on this screen. The old flow sent her
    // into registration on any failure, which quietly created a second profile
    // for someone who had simply mistyped a digit.
    if (!outcome.success) {
      _say(NarrationKeys.onbOtpWrong);
      _showMessage(outcome.message, isError: true);
      return;
    }

    // Fire-and-forget rather than `_say`: this line plays over the transition
    // to the next screen, and the card is about to go. Leaving the bound key
    // alone is also what keeps `dispose` from cutting it off — it only stops
    // the key the card is showing.
    speak(NarrationKeys.onbOtpSuccess, force: true);

    if (outcome.isRegistered) {
      _showMessage(
        'Welcome back${_greetingName.isEmpty ? '' : ', $_greetingName'}!',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
      return;
    }

    _showMessage("Verified! Let's set up your profile.");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RoleSelectionPage(
          phone: widget.rawPhone,
          countryCode: widget.countryCode,
          selectedLanguage: widget.selectedLanguage,
        ),
      ),
      (route) => false,
    );
  }

  String get _greetingName {
    final name = MainController.instance.userName;
    return name.trim();
  }

  Future<void> _handleResendOtp() async {
    setState(() => _isResending = true);

    final error = await AuthController.instance.resendOtp(
      widget.rawPhone,
      countryCode: widget.countryCode,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    _say(NarrationKeys.onbOtpResend);

    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    _showMessage('A new code is on its way.');
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isEmpty ? 'Something went wrong. Please try again.' : message,
        ),
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
                                    offset: const Offset(0, 2),
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
                              'Verify Your OTP',
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
                            'I just sent a secret 6-digit code to\nyour phone! 🔑',
                      ),
                    ),

                    // ─── BOTTOM OTP INPUT CONTAINER ───
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        isKeyboardOpen ? 16 : 24,
                        20,
                        (isKeyboardOpen ? 16 : 24) +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      decoration: BoxDecoration(
                        color: _p.card,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _p.pick(Colors.black12, _p.shadow),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'Enter 6-Digit OTP sent to ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _p.pick(const Color(0xFF5A5D64), _p.textSecondary),
                              ),
                              children: [
                                TextSpan(
                                  text: widget.phoneNumber,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_testNumbers.contains(widget.rawPhone)) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _controllers[0].text = '9';
                                  _controllers[1].text = '9';
                                  _controllers[2].text = '9';
                                  _controllers[3].text = '7';
                                  _controllers[4].text = '7';
                                  _controllers[5].text = '7';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F3)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFF8FA3),
                                  ),
                                ),
                                child: Text(
                                  '⚡ Test Number: Tap to fill 999777',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF4E6A),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: isKeyboardOpen ? 12 : 20),

                          // ─── 6 DIGIT OTP BOXES ───
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => _buildOtpBox(index),
                            ),
                          ),

                          SizedBox(height: isKeyboardOpen ? 12 : 18),

                          // ─── RESEND OTP ROW ───
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Tapping the question is how she asks where the
                              // code went; the baby answers on the card above.
                              GestureDetector(
                                onTap: () => _say(NarrationKeys.onbOtpWhere),
                                child: Text(
                                  "Didn't receive the code?",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _isResending ? null : _handleResendOtp,
                                child: Text(
                                  _isResending ? 'Sending...' : 'Resend OTP',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF5277),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isKeyboardOpen ? 14 : 24),

                          // ─── VERIFY BUTTON ───
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isVerifying ? null : _handleVerifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5277),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: _isVerifying
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Verify & Continue',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final bool isFocused = _focusedIndex == index;
    final bool isFilled = _controllers[index].text.isNotEmpty;

    return Container(
      width: 48,
      height: 54,
      decoration: BoxDecoration(
        color: isFocused ? _p.card : _p.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? const Color(0xFFFF5277)
              : isFilled
              ? const Color(0xFFFF8FA3)
              : _p.border,
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
