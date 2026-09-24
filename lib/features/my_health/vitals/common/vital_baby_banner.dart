import 'package:flutter/material.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/main_controller.dart';

/// The baby card every vital and nutrition screen opens with, as the old
/// detail pages did: the baby talks to her about the week she is in.
///
/// [narrationKey] plays that screen's recorded line (e.g.
/// `NarrationKeys.pgVitalsBp`) where one exists; without it the card stays
/// silent and shows [speechText] or the week greeting.
class VitalBabyBanner extends StatelessWidget {
  const VitalBabyBanner({
    super.key,
    this.narrationKey,
    this.speechText,
    this.height = 230,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  final String? narrationKey;
  final String? speechText;
  final double height;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final session = MainController.instance;
    final text =
        speechText ??
        (session.isPregnant
            ? "Week ${session.currentGestationalWeek}, Amma!\n"
                  "We're growing together. Can you feel the kicks?"
            : "Hi Amma! 💕\nLet's keep an eye on your health together.");

    return BabyHeroBanner(
      margin: margin,
      height: height,
      speechText: text,
      narrationKey: narrationKey,
      // The line plays, then the card returns to the week greeting.
      bindNarrationText: false,
      bubblePosition: SpeechBubblePosition.topCenter,
      greetingText: '',
    );
  }
}
