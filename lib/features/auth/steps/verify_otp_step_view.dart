import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyOtpStepView extends StatelessWidget {
  final String phone;
  final String countryCode;
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
                    ],
                  ),
                ),
                if (isTest) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      otpControllers[0].text = '9';
                      otpControllers[1].text = '9';
                      otpControllers[2].text = '9';
                      otpControllers[3].text = '7';
                      otpControllers[4].text = '7';
                      otpControllers[5].text = '7';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F3),
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
                SizedBox(height: isKeyboardOpen ? 8 : 14),

                // ─── 6 DIGIT OTP BOXES ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => _buildOtpBox(index),
                  ),
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

  Widget _buildOtpBox(int index) {
    final bool isFocused = focusedIndex == index;
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
        child: TextField(
          controller: otpControllers[index],
          focusNode: otpFocusNodes[index],
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
              otpFocusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
