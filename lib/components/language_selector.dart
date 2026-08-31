import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageSelector extends StatefulWidget {
  final String initialAppLanguage;
  final String initialSpeechLanguage;
  final ValueChanged<String>? onAppLanguageChanged;
  final ValueChanged<String>? onSpeechLanguageChanged;
  final ValueChanged<bool>? onAutoDetectChanged;

  const LanguageSelector({
    super.key,
    this.initialAppLanguage = 'en',
    this.initialSpeechLanguage = 'ta',
    this.onAppLanguageChanged,
    this.onSpeechLanguageChanged,
    this.onAutoDetectChanged,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String _selectedAppLang;
  late String _selectedSpeechLang;
  bool _autoDetectDialect = true;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'symbol': 'E', 'name': 'English'},
    {'code': 'ta', 'symbol': 'த', 'name': 'தமிழ்'},
    {'code': 'hi', 'symbol': 'ह', 'name': 'हिंदी'},
    {'code': 'te', 'symbol': 'తె', 'name': 'తెలుగు'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAppLang = widget.initialAppLanguage;
    _selectedSpeechLang = widget.initialSpeechLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── SECTION HEADER ───
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6FFFA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Color(0xFF0D9488),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LANGUAGE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2024),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Choose what you read and what I speak',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 16),

          // ─── 1. APP LANGUAGE ───
          Text(
            'APP LANGUAGE',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8E95A5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _languages.map((lang) {
              final isSelected = _selectedAppLang == lang['code'];
              return _buildLanguageCircle(
                symbol: lang['symbol']!,
                name: lang['name']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedAppLang = lang['code']!);
                  widget.onAppLanguageChanged?.call(lang['code']!);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 16),

          // ─── 2. SPEECH LANGUAGE ───
          Text(
            'SPEECH LANGUAGE',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8E95A5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _languages.map((lang) {
              final isSelected = _selectedSpeechLang == lang['code'];
              return _buildLanguageCircle(
                symbol: lang['symbol']!,
                name: lang['name']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedSpeechLang = lang['code']!);
                  widget.onSpeechLanguageChanged?.call(lang['code']!);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 14),

          // ─── 3. AUTO-DETECT DIALECT ───
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Detect Dialect',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    Text(
                      'Understand mixed language questions (Tanglish/Hinglish)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: _autoDetectDialect,
                activeColor: const Color(0xFF0D9488),
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) {
                  setState(() => _autoDetectDialect = val ?? false);
                  widget.onAutoDetectChanged?.call(_autoDetectDialect);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCircle({
    required String symbol,
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF0F3) : const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFFFF4E6A).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: Text(
                symbol,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF374151),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
