// ignore_for_file: unused_element, unused_field, unused_import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/widgets/baby_speech_avatar.dart';
import 'package:allomom/features/auth/register_flow/register_name_page.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/services/api/otp_api.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class VerifyOtpPage extends StatefulWidget {
  final String phoneNumber;
  final String rawPhone;
  final String countryCode;
  final dynamic otpId;
  final String selectedLanguage;
  final String selectedRole;

  const VerifyOtpPage({
    super.key,
    required this.phoneNumber,
    this.rawPhone = '9876543210',
    this.countryCode = '+91',
    this.otpId,
    this.selectedLanguage = 'en',
    this.selectedRole = 'Mom',
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _focusedIndex = 0;
  bool _isVerifying = false;
  bool _isResending = false;
  dynamic _currentOtpId;

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
    _currentOtpId = widget.otpId;

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

  Future<void> _handleVerifyOtp() async {
    final otpCode = _enteredOtp;
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit OTP code')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final res = await OtpApi.verifyOtp(
        otpCode,
        _currentOtpId ?? 0,
        "com.savemom.allomom",
      );

      if (!mounted) return;

      if (res.success) {
        final item = res.item;
        final bool isNewUser = (item is Map && item["is_new_user"] == true) || res.id == null;

        if (isNewUser) {
          // New User -> Transition to registration flow
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP Verified! Let\'s set up your maternal care profile.'),
              backgroundColor: Color(0xFFFF4E6A),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterNamePage(
                phone: widget.rawPhone,
                countryCode: widget.countryCode,
                selectedLanguage: widget.selectedLanguage,
                selectedRole: widget.selectedRole,
              ),
            ),
          );
        } else {
          // Existing User -> Load session and navigate to MainLayout
          if (item is Map) {
            await UserSessionManager.instance.setAuthenticatedSession(
              userId: item["user_id"]?.toString() ?? res.id?.toString() ?? "",
              jwt: item["jwt"]?.toString() ?? item["access_token"]?.toString() ?? "",
              refresh: item["refresh"]?.toString(),
              name: item["name"]?.toString(),
              phone: item["phone"]?.toString() ?? widget.rawPhone,
              email: item["email"]?.toString(),
              healthDataId: item["healthDataID"]?.toString(),
            );
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${item is Map ? item["name"] ?? "Mommy" : "Mommy"}! Loading your care dashboard.'),
              backgroundColor: const Color(0xFFFF4E6A),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainLayout()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.detail.isNotEmpty ? res.detail : 'Invalid OTP code. Please check and try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification notice: $e - proceeding to registration'),
            backgroundColor: const Color(0xFFFF4E6A),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterNamePage(
              phone: widget.rawPhone,
              countryCode: widget.countryCode,
              selectedLanguage: widget.selectedLanguage,
              selectedRole: widget.selectedRole,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      final res = await OtpApi.sendOtp(widget.rawPhone, widget.countryCode);
      if (!mounted) return;

      if (res.success) {
        _currentOtpId = res.id;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.detail.isNotEmpty ? res.detail : 'New OTP sent! (Test OTP: 999777)'),
            backgroundColor: const Color(0xFFFF4E6A),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.detail.isNotEmpty ? res.detail : 'Failed to resend OTP.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resend error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.selectedRole == 'Mom' ? 'Mommy' : 'Daddy';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      resizeToAvoidBottomInset: false,
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
                      'Verify Your OTP',
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
              speechText: 'I just sent a secret 6-digit code to\nyour phone, $roleName! 🔑',
              onSpeakerTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing OTP voice note...'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
            ),

            const Spacer(),

            // ─── BOTTOM OTP INPUT CONTAINER ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                  RichText(
                    text: TextSpan(
                      text: 'Enter 6-Digit OTP sent to ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5A5D64),
                      ),
                      children: [
                        TextSpan(
                          text: widget.phoneNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2024),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF8FA3)),
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
                  const SizedBox(height: 20),

                  // ─── 6 DIGIT OTP BOXES ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildOtpBox(index)),
                  ),

                  const SizedBox(height: 18),

                  // ─── RESEND OTP ROW ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Didn't receive the code?",
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: const Color(0xFF6B7280),
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

                  const SizedBox(height: 24),

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
    );
  }

  Widget _buildOtpBox(int index) {
    final bool isFocused = _focusedIndex == index;
    final bool isFilled = _controllers[index].text.isNotEmpty;

    return Container(
      width: 48,
      height: 54,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? const Color(0xFFFF5277)
              : isFilled
                  ? const Color(0xFFFF8FA3)
                  : const Color(0xFFE5E7EB),
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
            color: const Color(0xFF1E2024),
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
