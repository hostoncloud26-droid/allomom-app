import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_catalog.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';

/// What a narrated widget needs to know to draw itself.
class NarrationState {
  const NarrationState({
    required this.text,
    required this.speaking,
    required this.voiceEnabled,
    required this.onSpeakerTap,
  });

  /// The line to show in the speech bubble.
  final String text;

  /// True while this widget's own clip is the one playing.
  final bool speaking;

  /// False when the mother has muted the baby; the text still shows.
  final bool voiceEnabled;

  /// Replays the line, or stops it if it is already playing.
  final VoidCallback onSpeakerTap;
}

/// Plays a narration key while its subtree is on screen, and hands the subtree
/// the line to display.
///
/// This is AlloMom's stand-in for AlloBaby's floating `BabyAvatarWidget`. The
/// text lands in the baby head card that is already part of every screen rather
/// than in a bubble hovering over the app, so there is one baby on screen
/// instead of two — but the lifecycle is the same: the line plays when the
/// screen opens, is spoken once per session, and stops when the screen goes.
class BabyNarration extends StatefulWidget {
  const BabyNarration({
    super.key,
    required this.narrationKey,
    required this.builder,
    this.autoPlay = true,
    this.stopOnDispose = true,
    this.bindText = true,
    this.fallbackText = '',
  });

  /// A constant from `NarrationKeys`.
  final String narrationKey;

  /// Whether the line plays on its own when the widget appears. Screens that
  /// speak only in response to a tap pass false.
  final bool autoPlay;

  /// Whether leaving the screen cuts the line off. Screens that end by
  /// navigating onward while the baby is still talking pass false.
  final bool stopOnDispose;

  /// Whether the line replaces the subtree's own text for good.
  ///
  /// True through onboarding, where the baby's script *is* the copy. False on a
  /// feature screen whose card says something the script cannot — this week's
  /// number, the last cry it heard — so the line shows while it plays and the
  /// screen's own words come back afterwards.
  final bool bindText;

  /// Shown when the key has no catalogue entry, or, with [bindText] false,
  /// whenever the line is not playing — the screen's own copy.
  final String fallbackText;

  final Widget Function(BuildContext context, NarrationState state) builder;

  @override
  State<BabyNarration> createState() => _BabyNarrationState();
}

class _BabyNarrationState extends State<BabyNarration> {
  @override
  void initState() {
    super.initState();
    _schedulePlay();
  }

  @override
  void didUpdateWidget(covariant BabyNarration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.narrationKey != widget.narrationKey) {
      _schedulePlay();
    }
  }

  void _schedulePlay() {
    if (!widget.autoPlay || !BackgroundAudioController.isReady) return;
    // After the frame: the screen that pushed this one is still being disposed
    // during the build, and its `stopKey` would otherwise land on our clip.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      BackgroundAudioController.to.playByKey(widget.narrationKey, queue: true);
    });
  }

  @override
  void dispose() {
    if (widget.stopOnDispose && BackgroundAudioController.isReady) {
      BackgroundAudioController.to.stopKey(widget.narrationKey);
    }
    super.dispose();
  }

  String get _staticText =>
      NarrationCatalog.textFor(widget.narrationKey) ?? widget.fallbackText;

  @override
  Widget build(BuildContext context) {
    if (!BackgroundAudioController.isReady) {
      return widget.builder(
        context,
        NarrationState(
          text: widget.bindText ? _staticText : widget.fallbackText,
          speaking: false,
          voiceEnabled: false,
          onSpeakerTap: () {},
        ),
      );
    }

    final controller = BackgroundAudioController.to;

    return Obx(() {
      final isCurrent = controller.currentKey.value == widget.narrationKey;
      final speaking = isCurrent && controller.isPlaying.value;

      final live = controller.currentText.value;
      final scripted = isCurrent && live.isNotEmpty
          ? live
          : controller.textFor(widget.narrationKey);

      final showScripted = widget.bindText || speaking;
      final text = showScripted && scripted.isNotEmpty
          ? scripted
          : widget.fallbackText;

      return widget.builder(
        context,
        NarrationState(
          text: text,
          speaking: speaking,
          voiceEnabled: controller.isVoiceEnabled.value,
          onSpeakerTap: () => controller.replay(widget.narrationKey),
        ),
      );
    });
  }
}

/// Fire-and-forget narration for places with no card to hang text on — a
/// snackbar path, a permission prompt, a save that just succeeded.
void speak(String key, {bool force = false}) {
  if (!BackgroundAudioController.isReady) return;
  BackgroundAudioController.to.playByKey(key, force: force);
}

/// Speaks [keys] back to back. Used by the home screens, which greet, explain
/// the mic, and then ask their first question.
void speakAll(List<String> keys, {bool force = false}) {
  if (!BackgroundAudioController.isReady) return;
  BackgroundAudioController.to.playSequence(keys, force: force);
}

/// Pops an onboarding screen with the baby acknowledging it.
///
/// Not forced, so "Going back." is heard once and then the back button is
/// silent for the rest of the session — the line is reassurance the first time
/// and noise every time after.
void narratedPop(BuildContext context) {
  speak(NarrationKeys.onbBack);
  Navigator.maybePop(context);
}
