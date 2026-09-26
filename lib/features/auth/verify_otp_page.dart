import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/widgets/otp_channel_sheet.dart';
import 'package:allomom/features/auth/auth_flow_page.dart';

class VerifyOtpPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AuthFlowPage(
      initialStep: AuthFlowStep.verifyOtp,
      initialLanguage: selectedLanguage,
      initialPhone: rawPhone,
      initialCountryCode: countryCode,
    );
  }
}

class VerifyOtpStepView extends StatelessWidget {
  final String phone;
  final String countryCode;

  /// Where the code was sent, shown in the prompt. Null before the first send.
  final String? channel;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final int focusedIndex;
  final bool isVerifying;
  final bool isResending;
  final VoidCallback onVerifyOtp;
  final VoidCallback onResendOtp;
  final VoidCallback onWhereCodeTapped;
  final bool isKeyboardOpen;

  const VerifyOtpStepView({
    super.key,
    required this.phone,
    this.countryCode = '+91',
    this.channel,
    required this.otpControllers,
    required this.otpFocusNodes,
    this.focusedIndex = 0,
    required this.isVerifying,
    required this.isResending,
    required this.onVerifyOtp,
    required this.onResendOtp,
    required this.onWhereCodeTapped,
    this.isKeyboardOpen = false,
  });

  static const List<String> testNumbers = [
    '9999999999',
    '8888888888',
    '7639744744',
    '1111122222',
    '9363286517',
    '9876543210',
    '1234567890',
  ];

  @override
  Widget build(BuildContext context) {
    final cleanPhone = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    final isTest = testNumbers.contains(cleanPhone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
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
                          text: '$countryCode $phone',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                        if (channel != null)
                          TextSpan(text: ' via ${OtpChannel.label(channel!)}'),
                      ],
                    ),
                  ),
                  if (isTest) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        const code = '999777';
                        for (int i = 0; i < 6; i++) {
                          otpControllers[i].text = code[i];
                        }
                        otpFocusNodes[5].requestFocus();
                        otpControllers[5].selection =
                            const TextSelection.collapsed(offset: 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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
                  SizedBox(height: isKeyboardOpen ? 8 : 14),

                  // ─── 6 DIGIT OTP BOXES ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildOtpBox(index)),
                  ),

                  SizedBox(height: isKeyboardOpen ? 8 : 14),

                  // ─── RESEND OTP ROW ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: onWhereCodeTapped,
                        child: Text(
                          "Didn't receive the code?",
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: isResending ? null : onResendOtp,
                        child: Text(
                          isResending ? 'Sending...' : 'Resend OTP',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF5277),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── VERIFY BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isVerifying ? null : onVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5277),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: isVerifying
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
    );
  }

  void _onOtpChanged(String val, int index) {
    final digits = val.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      otpControllers[index].text = '';
      return;
    }

    // Case 1: Pasted 6 or more digits (e.g. from SMS autofill or clipboard)
    if (digits.length >= 6) {
      for (int i = 0; i < 6; i++) {
        otpControllers[i].text = digits[i];
      }
      otpFocusNodes[5].requestFocus();
      otpControllers[5].selection = const TextSelection.collapsed(offset: 1);
      return;
    }

    // Case 2: Pasted multiple digits (less than 6) or overwrote an existing digit
    if (digits.length > 1) {
      // If user typed one character while box already had a character
      if (digits.length == 2 && otpControllers[index].text.isNotEmpty) {
        final lastChar = digits.substring(digits.length - 1);
        otpControllers[index].value = TextEditingValue(
          text: lastChar,
          selection: const TextSelection.collapsed(offset: 1),
        );
        if (index < 5) {
          otpFocusNodes[index + 1].requestFocus();
        }
        return;
      }

      // Otherwise distribute digits across fields starting at current index
      for (int i = 0; i < digits.length && (index + i) < 6; i++) {
        otpControllers[index + i].text = digits[i];
      }
      final targetIndex = (index + digits.length).clamp(0, 5);
      otpFocusNodes[targetIndex].requestFocus();
      otpControllers[targetIndex].selection = const TextSelection.collapsed(
        offset: 1,
      );
      return;
    }

    // Case 3: Single digit typed into current field
    otpControllers[index].value = TextEditingValue(
      text: digits,
      selection: const TextSelection.collapsed(offset: 1),
    );
    if (index < 5) {
      otpFocusNodes[index + 1].requestFocus();
    }
  }

  Widget _buildOtpBox(int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        otpControllers[index],
        otpFocusNodes[index],
      ]),
      builder: (context, _) {
        final bool isFocused = otpFocusNodes[index].hasFocus;
        final bool isFilled = otpControllers[index].text.isNotEmpty;

        return Container(
          width: 46,
          height: 52,
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
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (otpControllers[index].text.isEmpty && index > 0) {
                    otpControllers[index - 1].clear();
                    otpFocusNodes[index - 1].requestFocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: otpControllers[index],
                focusNode: otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: true,
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
                onTap: () {
                  otpControllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: otpControllers[index].text.length,
                  );
                },
                onChanged: (val) => _onOtpChanged(val, index),
              ),
            ),
          ),
        );
      },
    );
  }
}
