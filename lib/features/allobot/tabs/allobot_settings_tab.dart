/// AlloBot settings — three things, all of them real.
///
/// The persona cards, model pickers and creativity sliders that used to live
/// here configured nothing: AlloBot answers from a downloaded intent catalogue
/// and a Whisper model on the phone. So this screen is the language that
/// catalogue is in, the voice model she listens with, and the voice she
/// answers in.
///
/// Picking a language already downloads the catalogue, so the sync at the
/// bottom is for the other case: the topics changed on the server and the
/// phone is still answering from the ones it downloaded last time.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/colors.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/speech/allobot_speech_controller.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/omnivoice_service.dart';
import 'package:allomom/services/online_tts_settings.dart';

const Color _inkLight = Color(0xFF1E2024);
const Color _mutedLight = Color(0xFF8E95A5);
const Color _cardBorderLight = Color(0xFFF2E4E7);

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
  final OnlineTtsSettings onlineVoice = OnlineTtsSettings.instance;

  // Surfaces and neutral text follow light / dark mode.
  AppPalette get _p => context.palette;
  Color get _ink => _p.pick(_inkLight, _p.textPrimary);
  Color get _muted => _p.pick(_mutedLight, _p.textMuted);
  Color get _cardBorder => _p.pick(_cardBorderLight, _p.border);

  final TextEditingController _baseUrlField = TextEditingController();
  final FocusNode _baseUrlFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Only reaches the network when the phone has no catalogue to read the
    // list from.
    chatbot.loadLanguages();

    // The field is filled once the stored URL is back, not on every rebuild:
    // typing into it must not be overwritten by what is still saved.
    onlineVoice.load().then((_) {
      if (!mounted) return;
      _baseUrlField.text = onlineVoice.baseUrl.value;
      _fieldReady = true;
    });

    // Also saved on the way out, for the keystroke that lands in the same
    // frame as the field losing focus.
    _baseUrlFocus.addListener(() {
      if (!_baseUrlFocus.hasFocus) _saveBaseUrl();
    });
  }

  @override
  void dispose() {
    _baseUrlField.dispose();
    _baseUrlFocus.dispose();
    super.dispose();
  }

  /// Whether the field holds the stored URL yet.
  ///
  /// Until it does, an empty field means "not read back", not "cleared" —
  /// saving it would point the online voice at nothing.
  bool _fieldReady = false;

  String _testResult = '';
  bool _testing = false;

  /// Keeps the stored address in step with the field.
  ///
  /// Saved as it is typed rather than when the field is left: a mother who
  /// types an address and taps the mic never gave the field a chance to lose
  /// focus, and the reply she got was read by the phone.
  void _saveBaseUrl() {
    if (!_fieldReady) return;
    onlineVoice.setBaseUrl(_baseUrlField.text);
  }

  void _onBaseUrlChanged(String _) {
    // The old verdict belongs to the old address.
    if (_testResult.isNotEmpty) setState(() => _testResult = '');
    _saveBaseUrl();
  }

  /// Asks the address in the field whether it is there, so "it still sounds
  /// like the phone" has an answer other than reading the logs.
  Future<void> _testConnection() async {
    _saveBaseUrl();
    final url = onlineVoice.resolvedBaseUrl;
    if (url.isEmpty) {
      setState(() => _testResult = 'Add the server address first.');
      return;
    }

    setState(() {
      _testing = true;
      _testResult = '';
    });

    OmniVoiceService.instance.setBaseUrl(url);
    final reachable = await OmniVoiceService.instance.ping();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = reachable
          ? 'Reached $url — her answers will be spoken from there.'
          : 'No answer from $url. Her answers will be read by this phone '
                'until it responds.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            'Configure the voice AlloBot listens with, the language she '
            'answers in, and the voice she answers with.',
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
          const SizedBox(height: 16),
          _buildOnlineVoiceCard(),
          const SizedBox(height: 16),
          _buildSyncCard(),
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
        final ready = speech.isReady.value;
        final error = speech.errorMessage.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpeechStatusTile(
              downloading: downloading,
              ready: ready,
              progress: progress,
              error: error,
            ),
            if (error.isNotEmpty && !downloading) ...[
              const SizedBox(height: 10),
              _notice(error, isError: true),
            ],
            const SizedBox(height: 10),
            Text(
              'Whisper Base runs entirely on this device. What you say is transcribed locally and never uploaded to any server.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.4,
                color: _muted,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSpeechStatusTile({
    required bool downloading,
    required bool ready,
    required double progress,
    required String error,
  }) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();

    final String title;
    final String subtitle;
    final Color borderColor;
    final Color bgColor;
    final Color titleColor;
    final Widget trailingWidget;
    final IconData iconData;
    final Color iconColor;
    final Color iconBgColor;
    final VoidCallback? onTap;

    if (downloading) {
      title = 'Training Speech';
      subtitle = 'Downloading Whisper Base model… $percent%';
      borderColor = primaryColor;
      bgColor = _p.accentSoft;
      titleColor = primaryColor;
      iconData = Icons.graphic_eq_rounded;
      iconColor = primaryColor;
      iconBgColor = _p.card;
      trailingWidget = Text(
        '$percent%',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      );
      onTap = null;
    } else if (ready) {
      title = 'Speech Ready';
      subtitle = 'Whisper Base (145 MB) is active on this phone';
      borderColor = const Color(0xFF10B981);
      bgColor = _p.tint(const Color(0xFF10B981), const Color(0xFFF0FDF4));
      titleColor = _p.pick(const Color(0xFF065F46), const Color(0xFF6EE7B7));
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF10B981);
      iconBgColor = _p.tint(const Color(0xFF10B981), const Color(0xFFD1FAE5));
      trailingWidget = const Icon(
        Icons.check_circle_rounded,
        size: 22,
        color: Color(0xFF10B981),
      );
      onTap = null;
    } else {
      title = 'Speech Not Ready';
      subtitle = error.isNotEmpty
          ? error
          : 'Tap to download Whisper Base (145 MB)';
      borderColor = error.isNotEmpty
          ? dangerRed.withValues(alpha: 0.5)
          : _p.divider;
      bgColor = error.isNotEmpty
          ? _p.tint(dangerRed, const Color(0xFFFEF2F2))
          : _p.card;
      titleColor = error.isNotEmpty ? dangerRed : _ink;
      iconData = Icons.mic_off_rounded;
      iconColor = error.isNotEmpty ? dangerRed : _muted;
      iconBgColor = _p.pick(const Color(0xFFF3F4F6), _p.surface);
      trailingWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded, size: 14, color: primaryColor),
            const SizedBox(width: 4),
            Text(
              'Download',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );
      onTap = () => speech.startDownload();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: (ready || downloading) ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: downloading
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            ),
                          )
                        : Icon(iconData, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailingWidget,
                ],
              ),
              if (downloading) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress <= 0 ? null : progress,
                    minHeight: 6,
                    backgroundColor: _p.card,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The microphone waits until this finishes.',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: _muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Online voice ─────────────────────────────────────────────────────────

  Widget _buildOnlineVoiceCard() {
    return _card(
      icon: Icons.record_voice_over_rounded,
      title: 'SPEAKING VOICE',
      subtitle: 'How her answers are read out loud',
      child: Obx(() {
        final enabled = onlineVoice.isEnabled.value;
        final missingUrl = enabled && onlineVoice.resolvedBaseUrl.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toggleRow(
              title: 'Use the online voice',
              subtitle: enabled
                  ? 'Answers are synthesised on the server below'
                  : 'Answers are read by this phone\'s own voice',
              value: enabled,
              onChanged: (value) {
                // Whatever is in the field belongs to the switch being
                // flipped, so it is saved before the setting it configures.
                _saveBaseUrl();
                onlineVoice.setEnabled(value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baseUrlField,
              focusNode: _baseUrlFocus,
              enabled: enabled,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onChanged: _onBaseUrlChanged,
              onSubmitted: (_) => _saveBaseUrl(),
              style: GoogleFonts.poppins(fontSize: 13, color: _ink),
              decoration: InputDecoration(
                labelText: 'Voice server address',
                hintText: OnlineTtsSettings.defaultBaseUrl,
                labelStyle: GoogleFonts.poppins(fontSize: 12.5, color: _muted),
                hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: _muted),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                filled: true,
                fillColor: enabled
                    ? _p.card
                    : _p.pick(const Color(0xFFF7F7F9), _p.surface),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _p.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _p.divider),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _p.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primaryColor, width: 1.4),
                ),
              ),
            ),
            if (missingUrl) ...[
              const SizedBox(height: 10),
              _notice(
                'Add the server address, or her answers will keep being read '
                'by this phone.',
                isError: true,
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (!enabled || _testing) ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                    : const Icon(Icons.wifi_tethering_rounded, size: 17),
                label: Text(
                  _testing ? 'Checking…' : 'Test this server',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            if (_testResult.isNotEmpty) ...[
              const SizedBox(height: 4),
              _notice(
                _testResult,
                isGood: _testResult.startsWith('Reached'),
                isError: !_testResult.startsWith('Reached'),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'A topic that was recorded is always played as recorded. The '
              'online voice is only for the answers that have no recording, '
              'and this phone reads them whenever the server cannot be '
              'reached.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.4,
                color: _muted,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: value ? _p.accentSoft : _p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? primaryColor : _p.divider,
          width: value ? 1.4 : 1,
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
                    color: value ? primaryColor : _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 11.5, color: _muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: primaryColor,
          ),
        ],
      ),
    );
  }

  // ── Topics ───────────────────────────────────────────────────────────────

  /// Re-downloads the intent catalogue in the language already chosen.
  ///
  /// The conversation survives it — [OfflineChatbotController.sync] only drops
  /// a half-walked flow, which belongs to the catalogue being replaced.
  Widget _buildSyncCard() {
    return _card(
      icon: Icons.cloud_sync_rounded,
      title: 'TOPICS',
      subtitle: 'What she can answer with no connection',
      child: Obx(() {
        final syncing = chatbot.isSyncing.value;
        final synced = chatbot.lastSynced.value;
        final count = chatbot.intentCount;
        final error = chatbot.error.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _notice(
              count > 0
                  ? '$count topics on this phone'
                        '${synced == null ? '' : ', synced '
                              '${DateFormat('d MMM, h:mm a').format(synced)}'}.'
                  : 'No topics downloaded yet — sync once and AlloBot can '
                        'answer offline.',
              isGood: count > 0,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // Two downloads writing into the same cache is one too many,
                // and a language switch is a sync of its own.
                onPressed: syncing ? null : () => chatbot.sync(),
                icon: syncing
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(
                  syncing ? 'Syncing…' : 'Sync intents',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 10),
              _notice(error, isError: true),
            ],
            const SizedBox(height: 10),
            Text(
              'Sync when the topics have changed on the server. The ones '
              'already here keep answering until the new ones arrive.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.4,
                color: _muted,
              ),
            ),
          ],
        );
      }),
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
        color: _p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _p.pick(Colors.black.withValues(alpha: 0.03), _p.shadow),
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
                  color: _p.accentSoft,
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
              color: selected ? _p.accentSoft : _p.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? primaryColor : _p.divider,
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
                  color: selected
                      ? primaryColor
                      : _p.pick(const Color(0xFFCFD3DC), _p.textMuted),
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
