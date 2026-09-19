/// The voice input popup, opened by the docked mic.
///
/// A port of AlloKonnect's `AllobotVoicePopup`: a transparent sheet that fades
/// up from the bottom carrying one capsule — `+` on the left, a prominent mic
/// in the middle, keyboard on the right — and nothing else. Listening starts
/// the moment it opens, closing it mid-listen cancels cleanly, and the keyboard
/// control hands the screen over to the text composer.
///
/// The one substitution: AlloKonnect records a clip and transcribes it with
/// Whisper afterwards, so its mic can only show a timer. AlloMom recognises on
/// device as she speaks, so the words appear above the capsule while she is
/// still talking.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:allomom/config/colors.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

class AlloBotVoicePopup extends StatefulWidget {
  const AlloBotVoicePopup({
    super.key,
    required this.controller,
    this.onEnableKeyboardMode,
    this.onTopicsRequested,
    this.autoStartListening = true,
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

  /// Shows the popup.
  static Future<void> show(
    BuildContext context, {
    required OfflineChatbotController controller,
    VoidCallback? onEnableKeyboardMode,
    VoidCallback? onTopicsRequested,
    bool autoStartListening = true,
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
      ),
    );
  }

  @override
  State<AlloBotVoicePopup> createState() => _AlloBotVoicePopupState();
}

class _AlloBotVoicePopupState extends State<AlloBotVoicePopup>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Built in initState rather than as late fields: a popup opened and closed
  // without ever pulsing would otherwise create its controller inside
  // dispose(), which looks up a ticker on an element that is already gone.
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool _isListening = false;

  /// True between the stop and the message reaching the controller — the
  /// spinner state AlloKonnect shows while Whisper is transcribing.
  bool _isSending = false;

  bool _speechReady = false;
  int _duration = 0;
  Timer? _timer;
  String _heard = '';

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
    // Closing the sheet mid-listen must not leave recognition running, and must
    // not send whatever was picked up on the way out.
    try {
      _speech.cancel();
    } catch (_) {}
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

    if (!_speechReady) {
      try {
        _speechReady = await _speech.initialize(
          onError: (SpeechRecognitionError error) {
            debugPrint('Ask Allo voice error: ${error.errorMsg}');
            if (mounted) _resetListeningState();
          },
          onStatus: (status) {
            if (!mounted) return;
            // The engine stops itself after a pause. Whatever it heard by then
            // is the message, so it is sent rather than dropped.
            if (status == 'done' || status == 'notListening') {
              if (_isListening) unawaited(_stopAndSend());
            }
          },
        );
      } catch (e) {
        debugPrint('Ask Allo voice init failed: $e');
        _speechReady = false;
      }
    }
    if (!mounted) return;

    if (!_speechReady) {
      _showNote('Voice input is not available — type instead.');
      _switchToKeyboard();
      return;
    }

    setState(() {
      _isListening = true;
      _duration = 0;
      _heard = '';
    });
    _pulseController.repeat(reverse: true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration++);
      if (_duration >= 60) unawaited(_stopAndSend());
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _heard = result.recognizedWords);
          if (result.finalResult) unawaited(_stopAndSend());
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('Ask Allo voice listen failed: $e');
      if (mounted) _resetListeningState();
    }
  }

  /// Ends the turn's listening, sends what was heard and closes the sheet.
  Future<void> _stopAndSend() async {
    if (!_isListening || _isSending) return;

    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isListening = false;
      _isSending = true;
    });

    try {
      await _speech.stop();
    } catch (_) {}

    final spoken = _heard.trim();
    if (spoken.isEmpty) {
      // Nothing to send: stay open so she can simply try again, which is what
      // AlloKonnect does when a clip transcribes to nothing.
      if (mounted) {
        setState(() => _isSending = false);
        _showNote('I did not catch that. Please try again.');
      }
      return;
    }

    widget.controller.send(spoken);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Ends listening without sending — the path every close takes.
  Future<void> _cancelListening() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    try {
      await _speech.cancel();
    } catch (_) {}
    if (mounted) _resetListeningState();
  }

  void _resetListeningState() {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _isSending = false;
      _duration = 0;
      _heard = '';
    });
  }

  void _showNote(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _close() async {
    await _cancelListening();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _switchToKeyboard() async {
    await _cancelListening();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.0, 0.45, 1.0],
              colors: [
                Color(0xF2FAF6F7),
                Color(0xA6FAF6F7),
                Colors.transparent,
              ],
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
                  if (_isListening || _heard.isNotEmpty) _buildHeardLine(),
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
            color: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
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
          child: const Icon(
            Icons.remove_rounded,
            color: Colors.black54,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// What has been recognised so far — the part AlloKonnect cannot show,
  /// because Whisper only sees the clip once it is over.
  Widget _buildHeardLine() {
    final text = _heard.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF2E4E7)),
        ),
        child: Text(
          text.isEmpty ? 'Listening, Amma…' : text,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: text.isEmpty ? FontWeight.w400 : FontWeight.w500,
            color: text.isEmpty ? const Color(0xFF8E95A5) : textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildCapsule(bool isBusy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFF2E4E7)),
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
            foreground: isBusy ? dangerRed : textMedium,
            background: isBusy
                ? dangerRed.withValues(alpha: 0.12)
                : const Color(0xFFF1F2F6),
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
            foreground: textMedium,
            background: const Color(0xFFF1F2F6),
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
