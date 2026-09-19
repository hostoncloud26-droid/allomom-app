/// AlloBot settings — two things, both of them real.
///
/// The persona cards, model pickers and creativity sliders that used to live
/// here configured nothing: AlloBot answers from a downloaded intent catalogue
/// and a Whisper model on the phone. So this screen is the language that
/// catalogue is in, and the voice model she listens with.
///
/// Fetching the catalogue is not a control here — picking a language already
/// downloads it, and the explicit sync lives in Ask Allo's own menu.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/colors.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/speech/allobot_speech_controller.dart';
import 'package:allomom/services/app_language.dart';

const Color _ink = Color(0xFF1E2024);
const Color _muted = Color(0xFF8E95A5);
const Color _cardBorder = Color(0xFFF2E4E7);

/// What a language code is called, for codes the server ships without a name.
const Map<String, String> _languageNames = {
  'en': 'English',
  'hi': 'हिन्दी · Hindi',
  'ta': 'தமிழ் · Tamil',
  'kn': 'ಕನ್ನಡ · Kannada',
  'te': 'తెలుగు · Telugu',
  'mr': 'मराठी · Marathi',
  'gu': 'ગુજરાતી · Gujarati',
};

class AlloBotSettingsTab extends StatefulWidget {
  const AlloBotSettingsTab({super.key});

  @override
  State<AlloBotSettingsTab> createState() => _AlloBotSettingsTabState();
}

class _AlloBotSettingsTabState extends State<AlloBotSettingsTab> {
  final OfflineChatbotController chatbot = OfflineChatbotController.instance;
  final AlloBotSpeechController speech = AlloBotSpeechController.instance;

  @override
  void initState() {
    super.initState();
    // Only reaches the network when the phone has no catalogue to read the
    // list from.
    chatbot.loadLanguages();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF6F7),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            'Configure the voice AlloBot listens with, and the language she '
            'answers in.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: _muted,
            ),
          ),
          const SizedBox(height: 18),
          _buildLanguageCard(),
          const SizedBox(height: 16),
          _buildVoiceModelCard(),
          const SizedBox(height: 20),
          _buildFootnote(),
        ],
      ),
    );
  }

  // ── Language ─────────────────────────────────────────────────────────────

  Widget _buildLanguageCard() {
    return _card(
      icon: Icons.translate_rounded,
      title: 'LANGUAGE',
      subtitle: 'The language her answers are written in',
      child: Obx(() {
        final languages = chatbot.availableLanguages;
        final current = chatbot.langCode.value.isEmpty
            ? AppLanguage.cachedOrFallback
            : chatbot.langCode.value;
        final syncing = chatbot.isSyncing.value;

        if (languages.isEmpty) {
          return _notice(
            'Sync the intents once and the languages AlloBot has been taught '
            'will appear here.',
          );
        }

        return Column(
          children: [
            for (final language in languages)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _selectableRow(
                  title: language.name.isNotEmpty
                      ? language.name
                      : (_languageNames[language.code] ?? language.code),
                  subtitle: language.code.toUpperCase(),
                  selected: language.code == current,
                  // Switching re-downloads the catalogue, so it waits for the
                  // one in flight rather than racing it.
                  onTap: syncing
                      ? null
                      : () => chatbot.setLanguage(language.code),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              'Changing the language downloads that catalogue and starts a '
              'fresh conversation.',
              style: GoogleFonts.poppins(fontSize: 11.5, color: _muted),
            ),
          ],
        );
      }),
    );
  }

  // ── Voice model ──────────────────────────────────────────────────────────

  Widget _buildVoiceModelCard() {
    return _card(
      icon: Icons.graphic_eq_rounded,
      title: 'VOICE MODEL',
      subtitle: 'Runs on this phone — what you say is never uploaded',
      child: Obx(() {
        final downloading = speech.isDownloading.value;
        final progress = speech.downloadProgress.value;
        final activeId = speech.activeModelId.value;
        final ready = speech.isReady.value;
        final error = speech.errorMessage.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (downloading) ...[
              _buildDownloadProgress(progress),
              const SizedBox(height: 12),
            ] else if (ready) ...[
              _notice(
                'Ready — ${speech.activeModel?.name ?? 'the voice model'} is on '
                'this phone.',
                isGood: true,
              ),
              const SizedBox(height: 12),
            ],
            for (final model in speech.supportedModels)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _selectableRow(
                  title: model.name,
                  subtitle: '${model.intelligence} · ${model.downloadSize}',
                  selected: model.id == activeId,
                  // One download at a time: starting a second would leave two
                  // writing into the same folder.
                  onTap: downloading ? null : () => speech.selectModel(model.id),
                ),
              ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 4),
              _notice(error, isError: true),
            ],
            if (!downloading && !ready && error.isEmpty) ...[
              const SizedBox(height: 4),
              _notice(
                'The voice model downloads by itself the first time it is '
                'needed. Until it is here, you can type to AlloBot.',
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildDownloadProgress(double progress) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Downloading ${speech.activeModel?.name ?? 'the voice model'}…',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress <= 0 ? null : progress,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The microphone waits until this finishes.',
            style: GoogleFonts.poppins(fontSize: 11.5, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildFootnote() {
    return Text(
      'AlloBot answers from the topics on this phone and listens with a model '
      'that also lives on it, so a conversation works with no connection at '
      'all.',
      style: GoogleFonts.poppins(fontSize: 11.5, height: 1.5, color: _muted),
    );
  }

  // ── Pieces ───────────────────────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _selectableRow({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: disabled && !selected ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? accentLight : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? primaryColor : dividerColor,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? primaryColor : _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color: selected ? primaryColor : const Color(0xFFCFD3DC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notice(String text, {bool isError = false, bool isGood = false}) {
    final color = isError
        ? dangerRed
        : (isGood ? successGreen : _muted);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : (isGood
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.4,
                color: isError ? dangerRed : _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
