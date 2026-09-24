/// The voice input popup, opened by the docked mic.
///
/// A port of AlloKonnect's `AllobotVoicePopup`: a transparent sheet that fades
/// up from the bottom carrying one capsule — `+` on the left, a prominent mic
/// in the middle, keyboard on the right — and nothing else. Listening starts
/// the moment it opens, closing it mid-listen cancels cleanly, and the keyboard
/// control hands the screen over to the text composer.
///
/// Like AlloKonnect it records a clip and transcribes it with Whisper on the
/// device, so nothing she says is sent anywhere: the mic shows a timer while
/// she talks and a spinner while the model reads it back.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/speech/allobot_speech_controller.dart';
import 'package:allomom/features/offline_chatbot/speech/allobot_speech_service.dart';
import 'package:allomom/services/app_language.dart';

class AlloBotVoicePopup extends StatefulWidget {
  const AlloBotVoicePopup({
    super.key,
    required this.controller,
    this.onEnableKeyboardMode,
    this.onTopicsRequested,
    this.autoStartListening = true,
    this.speakReply = true,
  });

  final OfflineChatbotController controller;

  /// Called after the sheet closes because the keyboard control was tapped, so
  /// the screen behind it can focus its composer.
  final VoidCallback? onEnableKeyboardMode;

  /// What the `+` opens while no turn is running. AlloKonnect leaves it inert
  /// there; in AlloMom it is the topics list, which is what the `+` on the Ask
  /// Allo bar has always meant.
  final VoidCallback? onTopicsRequested;

  final bool autoStartListening;

  /// Whether the answer to this turn is read back. False from the transcript,
  /// which is a screen being read rather than a conversation being held.
  final bool speakReply;

  /// Shows the popup.
  static Future<void> show(
    BuildContext context, {
    required OfflineChatbotController controller,
    VoidCallback? onEnableKeyboardMode,
    VoidCallback? onTopicsRequested,
    bool autoStartListening = true,
    bool speakReply = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => AlloBotVoicePopup(
        controller: controller,
        onEnableKeyboardMode: onEnableKeyboardMode,
        onTopicsRequested: onTopicsRequested,
        autoStartListening: autoStartListening,
        speakReply: speakReply,
      ),
    );
  }

  @override
  State<AlloBotVoicePopup> createState() => _AlloBotVoicePopupState();
}

class _AlloBotVoicePopupState extends State<AlloBotVoicePopup>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final AlloBotSpeechController _speech = AlloBotSpeechController.instance;

  // Not `p`: that name is taken by the `path` import.
  AppPalette get _pal => context.palette;

  // Built in initState rather than as late fields: a popup opened and closed
  // without ever pulsing would otherwise create its controller inside
  // dispose(), which looks up a ticker on an element that is already gone.
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool _isListening = false;

  /// True between the stop and the message reaching the controller — the
  /// spinner state AlloKonnect shows while Whisper is transcribing.
  bool _isSending = false;

  int _duration = 0;
  Timer? _timer;
  String? _clipPath;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.autoStartListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startListening();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    // Closing the sheet mid-recording must not leave the mic open, and must not
    // send whatever was picked up on the way out.
    try {
      _recorder.stop();
    } catch (_) {}
    _recorder.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _toggle() async {
    if (_isSending) return;
    if (_isListening) {
      await _stopAndSend();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isSending) return;

    // Whatever the baby is still saying belongs to the previous turn.
    await widget.controller.stopCurrentTurn();
    if (!mounted) return;

    if (_speech.isDownloading.value) {
      widget.controller.showVoiceNotice(
        'I am still learning to listen — the voice model is downloading.',
      );
      return;
    }

    if (!_speech.canListen) {
      widget.controller.showVoiceNotice(
        'My voice model is not ready yet. Type to me, or start the download '
        'from Settings.',
      );
      unawaited(_switchToKeyboard());
      return;
    }

    try {
      if (!await _recorder.hasPermission()) {
        widget.controller.showVoiceNotice(
          'I need permission to use the microphone before I can listen.',
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final path = p.join(
        tempDir.path,
        'ask_allo_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      _clipPath = path;

      // 16 kHz mono WAV is what Whisper expects.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
    } catch (e) {
      debugPrint('Ask Allo recording failed to start: $e');
      widget.controller.showVoiceNotice('I could not start listening just now.');
      _resetListeningState();
      return;
    }

    if (!mounted) {
      unawaited(_recorder.stop());
      return;
    }

    widget.controller.clearVoiceNotice();
    _startedAt = DateTime.now();
    setState(() {
      _isListening = true;
      _duration = 0;
    });
    _pulseController.repeat(reverse: true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration++);
      // A minute is far longer than a question, and the clip has to be held in
      // memory to transcribe it.
      if (_duration >= 60) unawaited(_stopAndSend());
    });
  }

  /// Stops the recording, transcribes it on the device, sends what it heard and
  /// closes the sheet.
  Future<void> _stopAndSend() async {
    if (!_isListening || _isSending) return;

    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isListening = false;
      _isSending = true;
    });

    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      debugPrint('Ask Allo recording failed to stop: $e');
    }
    path ??= _clipPath;

    final spokenFor = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    _startedAt = null;
    _clipPath = null;

    if (path == null || spokenFor < const Duration(milliseconds: 500)) {
      // An accidental tap rather than a question.
      if (path != null) unawaited(_deleteClip(path));
      if (mounted) {
        setState(() => _isSending = false);
        widget.controller.showVoiceNotice('That was too short for me to hear.');
      }
      return;
    }

    String heard = '';
    try {
      final selectedLanguage = widget.controller.langCode.value.isNotEmpty
          ? widget.controller.langCode.value
          : await AppLanguage.current();
      heard = await AlloBotSpeechService.instance.transcribe(
        path,
        language: selectedLanguage,
      );
    } catch (e) {
      debugPrint('Ask Allo transcription failed: $e');
    } finally {
      unawaited(_deleteClip(path));
    }

    // Whisper marks what it could not make out with bracketed notes such as
    // [BLANK_AUDIO]; they are not words she said.
    final spoken = heard
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .trim();

    if (spoken.isEmpty) {
      // Nothing to send: stay open so she can simply try again.
      if (mounted) {
        setState(() => _isSending = false);
        // Said in her bubble, behind the sheet, where she does her talking.
        widget.controller.showVoiceNotice(
          'I did not catch that, Amma. Please say it again.',
        );
      }
      return;
    }

    widget.controller.send(spoken, speak: widget.speakReply);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Ends listening without sending — the path every close takes.
  Future<void> _cancelListening() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final path = _clipPath;
    _clipPath = null;
    _startedAt = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (path != null) unawaited(_deleteClip(path));

    if (mounted) _resetListeningState();
  }

  Future<void> _deleteClip(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A stray temp file is harmless.
    }
  }

  void _resetListeningState() {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _isSending = false;
      _duration = 0;
    });
  }

  /// Closes the sheet, then tidies up.
  ///
  /// The dismissal is not held behind the recorder: stopping it is a platform
  /// round-trip, and a sheet that lingers while the microphone is handed back
  /// reads as a tap that did not land.
  Future<void> _close() async {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    unawaited(_cancelListening());
  }

  Future<void> _switchToKeyboard() async {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    unawaited(_cancelListening());
    widget.controller.isKeyboardMode.value = true;
    widget.onEnableKeyboardMode?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (_isListening) await _cancelListening();
      },
      child: Obx(() {
        final isBusy = widget.controller.isTyping.value;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: const [0.0, 0.45, 1.0],
              colors: _pal.pick(
                const [
                  Color(0xF2FAF6F7),
                  Color(0xA6FAF6F7),
                  Colors.transparent,
                ],
                const [
                  Color(0xF2121212),
                  Color(0xA6121212),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDragPill(),
                  if (_isListening || _isSending) _buildStatusLine(),
                  _buildCapsule(isBusy),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDragPill() {
    return Center(
      child: GestureDetector(
        onTap: _close,
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _pal.pick(
              Colors.black.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.10),
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pal.pick(
                Colors.black.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.12),
              ),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.remove_rounded,
            color: _pal.pick(Colors.black54, _pal.textSecondary),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// What is happening, in her own words.
  ///
  /// Whisper only sees the clip once it is finished, so unlike a streaming
  /// recogniser there is nothing to show word by word — this says whether she
  /// is still listening or already reading it back.
  Widget _buildStatusLine() {
    final text = _isSending ? 'Let me read that back…' : 'Listening, Amma…';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _pal.card.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pal.pick(const Color(0xFFF2E4E7), _pal.accentBorder),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: _pal.pick(const Color(0xFF8E95A5), _pal.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildCapsule(bool isBusy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _pal.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: _pal.pick(const Color(0xFFF2E4E7), _pal.accentBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left: the topics `+`, or a stop while a turn is being answered.
          _sideButton(
            icon: isBusy ? Icons.stop_rounded : Icons.add_rounded,
            tooltip: isBusy ? 'Stop' : 'Topics',
            foreground: isBusy ? dangerRed : _pal.textSecondary,
            background: isBusy
                ? dangerRed.withValues(alpha: 0.12)
                : _pal.pick(const Color(0xFFF1F2F6), _pal.surface),
            onTap: () {
              HapticFeedback.lightImpact();
              if (isBusy) {
                widget.controller.stopCurrentTurn();
                return;
              }
              final topics = widget.onTopicsRequested;
              if (topics == null) return;
              unawaited(_close().then((_) => topics()));
            },
          ),
          const SizedBox(width: 45),
          _buildMicButton(),
          const SizedBox(width: 45),
          _sideButton(
            icon: Icons.keyboard_alt_outlined,
            tooltip: 'Type a message',
            foreground: _pal.textSecondary,
            background: _pal.pick(const Color(0xFFF1F2F6), _pal.surface),
            onTap: () {
              HapticFeedback.lightImpact();
              unawaited(_switchToKeyboard());
            },
          ),
        ],
      ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required String tooltip,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: foreground, size: 24),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMicButton() {
    const size = 58.0;

    if (_isSending) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryColor.withValues(alpha: 0.12),
          border: Border.all(color: primaryColor, width: 2),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
        ),
      );
    }

    if (_isListening) {
      return GestureDetector(
        onTap: _toggle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dangerRed,
                  boxShadow: [
                    BoxShadow(
                      color: dangerRed.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: dangerRed,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: primaryGradient,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
