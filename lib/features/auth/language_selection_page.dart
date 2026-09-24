import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/auth_flow_page.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFlowPage(initialStep: AuthFlowStep.language);
  }
}

class LanguageStepView extends StatelessWidget {
  final String selectedLanguageCode;
  final ValueChanged<String> onLanguageSelected;
  final VoidCallback onProceed;

  const LanguageStepView({
    super.key,
    required this.selectedLanguageCode,
    required this.onLanguageSelected,
    required this.onProceed,
  });

  static const List<Map<String, dynamic>> languages = [
    {'code': 'en', 'name': 'English', 'iconType': 'globe_pink'},
    {'code': 'hi', 'name': 'Hindi', 'char': 'हि', 'iconType': 'char'},
    {'code': 'ta', 'name': 'Tamil', 'char': 'த', 'iconType': 'char'},
    {'code': 'kn', 'name': 'Kannada', 'char': 'ಕ', 'iconType': 'char'},
    {'code': 'te', 'name': 'Telugu', 'char': 'తె', 'iconType': 'char'},
    {'code': 'other', 'name': 'Other', 'iconType': 'globe_blue'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 12),

              // 3x2 Grid
              Row(
                children: [
                  Expanded(child: _buildLanguageCard(languages[0])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildLanguageCard(languages[1])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildLanguageCard(languages[2])),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildLanguageCard(languages[3])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildLanguageCard(languages[4])),
                  const SizedBox(width: 10),
                  Expanded(child: _buildLanguageCard(languages[5])),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ─── PINNED BOTTOM PROCEED BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5277),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> lang) {
    final isSelected = selectedLanguageCode == lang['code'];

    return GestureDetector(
      onTap: () => onLanguageSelected(lang['code'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E6A)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF4E6A).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLeadingIcon(lang, isSelected),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                lang['name'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFFFF4E6A)
                      : const Color(0xFF1E2024),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(Map<String, dynamic> lang, bool isSelected) {
    final type = lang['iconType'] as String;

    if (type == 'globe_pink') {
      return const Icon(
        Icons.public_rounded,
        size: 18,
        color: Color(0xFFFF4E6A),
      );
    } else if (type == 'globe_blue') {
      return const Icon(
        Icons.language_rounded,
        size: 18,
        color: Color(0xFF3B82F6),
      );
    } else {
      return Text(
        lang['char'] as String,
        style: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF6B7280),
        ),
      );
    }
  }
}
