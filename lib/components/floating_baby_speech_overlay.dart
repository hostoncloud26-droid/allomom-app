import 'dart:async';

import 'package:flutter/material.dart';

import 'package:allomom/components/baby_bottom_avatar.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_catalog.dart';
import 'package:allomom/features/home/allobaby_flow_controller.dart';
import 'package:allomom/services/screen_voice_hint_service.dart';
import 'package:allomom/services/tts_service.dart';

/// A self-contained, clean architecture floating baby speech overlay widget.
///
/// Encapsulates:
/// - Intent execution via [AlloBabyFlowController]
/// - Lifecycle-safe listener management (no setState during build or unmounted element errors)
/// - Auto-linger animation timer (slides out after speaking finishes)
/// - Smooth entrance and exit animations ([AnimatedSlide] & [AnimatedOpacity])
/// - User interaction (replay on speaker tap, dismiss on close tap)
/// - Optional bottom gradient scrim for bottom bar tabs
class FloatingBabySpeechOverlay extends StatefulWidget {
  const FloatingBabySpeechOverlay({
    super.key,
    this.intentKey,
    this.fallbackText = '',
    this.controller,
    this.bottom = 4.0,
    this.autoStart = true,
    this.playEveryVisit = false,
    this.showScrim = false,
    this.scrimHeight = 160.0,
    this.onDismissed,
  });

  /// Offline chatbot intent key to play on mount or replay.
  final String? intentKey;

  /// Default placeholder text shown before the chatbot produces its first line.
  final String fallbackText;

  /// Optional external [AlloBabyFlowController]. If null, one is created and managed internally.
  final AlloBabyFlowController? controller;

  /// Distance from the bottom of the safe area. Defaults to 4.0.
  final double bottom;

  /// Whether to automatically trigger [intentKey] on initial layout.
  final bool autoStart;

  /// If true, always plays on every visit regardless of session history and skips hint derivation.
  final bool playEveryVisit;

  /// Whether to render a dark bottom gradient scrim (e.g., above bottom navigation bar).
  final bool showScrim;

  /// Height of the scrim gradient. Defaults to 160.0.
  final double scrimHeight;

  /// Optional callback invoked when dismissed.
  final VoidCallback? onDismissed;

  @override
  State<FloatingBabySpeechOverlay> createState() =>
      FloatingBabySpeechOverlayState();
}

class FloatingBabySpeechOverlayState extends State<FloatingBabySpeechOverlay> {
  late AlloBabyFlowController _controller;
  bool _ownsController = false;

  Timer? _lingerTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _setupController();
    if (widget.autoStart && widget.intentKey != null) {
      final key = widget.intentKey!;
      if (widget.playEveryVisit || !ScreenVoiceHintService.hasPlayedInSession(key)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          start(key: widget.intentKey, isAutoStart: !widget.playEveryVisit);
        });
      }
    }
  }

  void _setupController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = AlloBabyFlowController();
      _ownsController = true;
    }
    _controller.addListener(_onFlowChanged);
  }

  @override
  void didUpdateWidget(covariant FloatingBabySpeechOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onFlowChanged);
      if (_ownsController) {
        _controller.dispose();
      }
      _setupController();
    }
    if (oldWidget.intentKey != widget.intentKey && widget.intentKey != null) {
      if (widget.playEveryVisit || !ScreenVoiceHintService.hasPlayedInSession(widget.intentKey!)) {
        start(key: widget.intentKey, isAutoStart: !widget.playEveryVisit);
      }
    }
  }

  void _onFlowChanged() {
    if (!mounted) return;
    if (_controller.isRunning) {
      _lingerTimer?.cancel();
      _lingerTimer = null;
      if (!_visible) {
        setState(() => _visible = true);
      } else {
        setState(() {});
      }
    } else {
      // Once speaking stops, linger for 600ms then slide out
      if (_visible && _lingerTimer == null) {
        _lingerTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() => _visible = false);
            _lingerTimer = null;
            widget.onDismissed?.call();
          }
        });
      }
      setState(() {});
    }
  }

  /// Starts or restarts speaking an intent.
  /// If [isAutoStart] is true, skips if already played in this app session.
  /// Manual calls (e.g. user tapping avatar / replay) will always play.
  void start({String? key, bool isAutoStart = false}) {
    final targetKey = key ?? widget.intentKey;
    if (targetKey != null &&
        isAutoStart &&
        !widget.playEveryVisit &&
        ScreenVoiceHintService.hasPlayedInSession(targetKey)) {
      return;
    }
    _lingerTimer?.cancel();
    _lingerTimer = null;
    if (!_visible && mounted) {
      setState(() => _visible = true);
    }
    _controller.start(
      intentKey: targetKey,
      resolveHint: !widget.playEveryVisit,
    );
  }

  /// Safely stops speaking, resets audio/TTS, and hides the overlay.
  void stop({bool updateUi = true}) {
    _lingerTimer?.cancel();
    _lingerTimer = null;
    if (updateUi && mounted) {
      setState(() => _visible = false);
    }
    _controller.stop();
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.stop();
    }
    TtsService().stop();
    if (updateUi) {
      widget.onDismissed?.call();
    }
  }

  @override
  void deactivate() {
    _controller.removeListener(_onFlowChanged);
    stop(updateUi: false);
    super.deactivate();
  }

  @override
  void dispose() {
    _lingerTimer?.cancel();
    _controller.removeListener(_onFlowChanged);
    stop(updateUi: false);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Widget _buildBubble(String displayText) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: widget.bottom,
      child: SafeArea(
        top: false,
        child: IgnorePointer(
          ignoring: !_visible,
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, 1.5),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 240),
              child: BabyLinePopup(
                text: displayText,
                speaking: _controller.isRunning,
                onSpeakerTap: () {
                  if (_controller.isRunning) {
                    stop();
                  } else {
                    start();
                  }
                },
                onClose: () => stop(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final line = _controller.line.trim();
    final catalogText = widget.intentKey != null
        ? NarrationCatalog.textFor(widget.intentKey!)
        : null;
    final displayText = line.isNotEmpty
        ? line
        : ((catalogText != null && catalogText.isNotEmpty)
            ? catalogText
            : widget.fallbackText.trim());

    if (!widget.showScrim) {
      return _buildBubble(displayText);
    }

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.scrimHeight,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 280),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x22000000),
                        Color(0x55000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildBubble(displayText),
        ],
      ),
    );
  }
}
