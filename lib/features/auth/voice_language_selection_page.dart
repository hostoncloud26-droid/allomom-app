import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';

class VoiceLanguageStepView extends StatefulWidget {
  final String selectedVoiceLanguageCode;
  final ValueChanged<String> onVoiceLanguageSelected;
  final VoidCallback onProceed;

  const VoiceLanguageStepView({
    super.key,
    required this.selectedVoiceLanguageCode,
    required this.onVoiceLanguageSelected,
    required this.onProceed,
  });

  @override
  State<VoiceLanguageStepView> createState() => _VoiceLanguageStepViewState();
}

class _VoiceLanguageStepViewState extends State<VoiceLanguageStepView> {
  static const List<Map<String, dynamic>> _knownLanguages = [
    {'code': 'en', 'name': 'English', 'iconType': 'globe_pink'},
    {'code': 'ta', 'name': 'Tamil', 'char': 'த', 'iconType': 'char'},
    {'code': 'hi', 'name': 'Hindi', 'char': 'हि', 'iconType': 'char'},
    {'code': 'kn', 'name': 'Kannada', 'char': 'ಕ', 'iconType': 'char'},
    {'code': 'te', 'name': 'Telugu', 'char': 'తె', 'iconType': 'char'},
    {'code': 'mr', 'name': 'Marathi', 'char': 'म', 'iconType': 'char'},
    {'code': 'gu', 'name': 'Gujarati', 'char': 'ગુ', 'iconType': 'char'},
  ];

  @override
  void initState() {
    super.initState();
    OfflineChatbotController.instance.loadLanguages();
  }

  List<Map<String, dynamic>> _getAvailableLanguages() {
    final chatbot = OfflineChatbotController.instance;
    final List<BotLanguage> serverLangs = chatbot.availableLanguages;

    final List<Map<String, dynamic>> list = List.from(_knownLanguages);
    for (final sLang in serverLangs) {
      final code = sLang.code.toLowerCase().trim();
      if (code.isEmpty) continue;
      final exists = list.any(
        (l) => (l['code'] as String).toLowerCase().trim() == code,
      );
      if (!exists) {
        list.add({
          'code': code,
          'name': sLang.name.isNotEmpty ? sLang.name : code.toUpperCase(),
          'char': code.substring(0, 1).toUpperCase(),
          'iconType': 'char',
        });
      }
    }
    return list;
  }

  void _handleSelect(String code) {
    widget.onVoiceLanguageSelected(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Voice Language',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 12),

              // Available languages rendered in identical 3-column rows
              GetBuilder<OfflineChatbotController>(
                builder: (_) {
                  final list = _getAvailableLanguages();
                  final rows = <List<Map<String, dynamic>>>[];
                  for (int i = 0; i < list.length; i += 3) {
                    rows.add(list.sublist(i, (i + 3).clamp(0, list.length)));
                  }

                  return Column(
                    children: [
                      for (int r = 0; r < rows.length; r++) ...[
                        if (r > 0) const SizedBox(height: 10),
                        Row(
                          children: [
                            for (int c = 0; c < 3; c++) ...[
                              if (c > 0) const SizedBox(width: 10),
                              if (c < rows[r].length)
                                Expanded(child: _buildLanguageCard(rows[r][c]))
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          ],
                        ),
                      ],
                    ],
                  );
                },
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
            onPressed: widget.onProceed,
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
    final code = lang['code'] as String;
    final isSelected =
        widget.selectedVoiceLanguageCode.toLowerCase().trim() ==
            code.toLowerCase().trim();

    return GestureDetector(
      onTap: () => _handleSelect(code),
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
    final type = (lang['iconType'] as String?) ?? 'char';

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
        (lang['char'] as String?) ?? (lang['code'] as String).toUpperCase(),
        style: GoogleFonts.notoSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color:
              isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF6B7280),
        ),
      );
    }
  }
}
