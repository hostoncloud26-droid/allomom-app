import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinFamilyCodeStepView extends StatelessWidget {
  final TextEditingController codeController;
  final bool isChecking;
  final bool isJoining;
  final String? errorMessage;
  final VoidCallback onJoin;
  final VoidCallback onCancel;
  final bool isKeyboardOpen;

  const JoinFamilyCodeStepView({
    super.key,
    required this.codeController,
    required this.isChecking,
    required this.isJoining,
    this.errorMessage,
    required this.onJoin,
    required this.onCancel,
    this.isKeyboardOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENTER 6-CHARACTER FAMILY CODE',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8E95A5),
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: isKeyboardOpen ? 6 : 10),

                // Code Input Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: errorMessage != null
                          ? Colors.red.shade300
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        color: Color(0xFFFF4E6A),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: codeController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6),
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          ],
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: const Color(0xFF1E2024),
                          ),
                          decoration: InputDecoration(
                            hintText: 'ABC123',
                            hintStyle: GoogleFonts.outfit(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 18,
                              letterSpacing: 4,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (isChecking)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF4E6A),
                          ),
                        ),
                    ],
                  ),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Back',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── JOIN BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isJoining || isChecking ? null : onJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5277),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: isJoining
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Join Family',
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
}
