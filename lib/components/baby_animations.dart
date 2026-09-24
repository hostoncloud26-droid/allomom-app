/// The baby's animated clips, built from the current still
/// (`assets/allobaby/AlloMombabySquare.png`) by `tool/make_baby_animations.py`.
///
/// Same canvas and framing as the still, so switching between the still and a
/// clip never moves or resizes the baby. Animated WebP, played by
/// `Image.asset` — pass `gaplessPlayback: true` so a swap does not flash.
abstract final class BabyAnimations {
  /// The mouth opening and closing in a speech rhythm, with a blink.
  static const String speaking = 'assets/allobaby/baby_speaking.webp';

  /// Breathing, with a blink — for while a reply is being worked out.
  static const String idle = 'assets/allobaby/baby_idle.webp';
}
