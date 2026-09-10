import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/services/app_language.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String _selectedLanguageCode = 'en';

  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'name': 'English', 'iconType': 'globe_pink'},
    {'code': 'hi', 'name': 'Hindi', 'char': 'हि', 'iconType': 'char'},
    {'code': 'ta', 'name': 'Tamil', 'char': 'த', 'iconType': 'char'},
    {'code': 'kn', 'name': 'Kannada', 'char': 'ಕ', 'iconType': 'char'},
    {'code': 'te', 'name': 'Telugu', 'char': 'తె', 'iconType': 'char'},
    {'code': 'other', 'name': 'Other', 'iconType': 'globe_blue'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fills the viewport so the Spacer can push the card to the
            // bottom, and scrolls instead of overflowing on a short screen.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ─── TOP TITLE ───
                  Text(
                    'Please Select Your Language',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── BABY SPEECH AVATAR ───
                  BabyHeroBanner(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    speechText:
                        'Hello there! Which language should\nwe speak together? 💬',
                    onSpeakerTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Playing voice greeting in selected language...',
                          ),
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // ─── BOTTOM SELECTION CONTAINER ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
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
                          'Select Language',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3x2 Grid
                        Row(
                          children: [
                            Expanded(child: _buildLanguageCard(_languages[0])),
                            const SizedBox(width: 10),
                            Expanded(child: _buildLanguageCard(_languages[1])),
                            const SizedBox(width: 10),
                            Expanded(child: _buildLanguageCard(_languages[2])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildLanguageCard(_languages[3])),
                            const SizedBox(width: 10),
                            Expanded(child: _buildLanguageCard(_languages[4])),
                            const SizedBox(width: 10),
                            Expanded(child: _buildLanguageCard(_languages[5])),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ─── PROCEED BUTTON ───
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Persisted as well as passed on: the rest of
                              // registration takes it as an argument, but
                              // AlloBot needs to read it long after this page
                              // is gone.
                              await AppLanguage.save(_selectedLanguageCode);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ContactNumberPage(
                                    selectedLanguage: _selectedLanguageCode,
                                  ),
                                ),
                              );
                            },
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
                                    'Proceed',
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

  Widget _buildLanguageCard(Map<String, dynamic> lang) {
    final code = lang['code'] as String;
    final isSelected = _selectedLanguageCode == code;
    final iconType = lang['iconType'] as String;
    final char = lang['char'] as String?;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguageCode = code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E6A)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon / Character badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFFD8E0)
                    : const Color(0xFFF3F4F6),
              ),
              child: Center(
                child: iconType == 'char'
                    ? Text(
                        char ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFFFF4E6A)
                              : const Color(0xFF4B5563),
                        ),
                      )
                    : Icon(
                        Icons.language_rounded,
                        color: isSelected
                            ? const Color(0xFFFF4E6A)
                            : (iconType == 'globe_blue'
                                  ? const Color(0xFF3898EC)
                                  : const Color(0xFFFF4E6A)),
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang['name'] as String,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFFF4E6A)
                    : const Color(0xFF1E2024),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
