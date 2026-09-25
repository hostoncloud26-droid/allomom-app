import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:allomom/components/baby_animations.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';

/// Marks a baby that is already drawn on the screen — the hero card, the slim
/// prompt bar, AlloBot's baby — so [BabyBottomAvatar] stays out of the way.
///
/// Only counts while its route is the one in front and its subtree is ticking:
/// a Home card under a pushed My Health page, or an AlloBot tab hidden in an
/// `IndexedStack`, is still mounted but is not something she can see.
class BabyOnScreen extends StatefulWidget {
  const BabyOnScreen({
    super.key,
    required this.child,
    this.wholeScreen = false,
  });

  final Widget child;

  /// Keeps the popup away for the whole screen this sits in, whichever of its
  /// tabs is showing. The AlloBot section passes true: it is the baby's own
  /// screen, so a second baby popping up over it is never wanted.
  final bool wholeScreen;

  static final Set<_BabyOnScreenState> _mounted = {};

  /// Bumped whenever a baby comes or goes, so the popup can look again.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  /// Tracks the root navigator's stack, so a sheet or dialog opened over a
  /// screen still counts as that screen. Registered in `GetMaterialApp`.
  static final NavigatorObserver observer = _RouteStackObserver();

  /// Whether a baby is visible on the screen in front of her right now.
  static bool get anyVisible => _mounted.any((s) => s._isVisible);

  @override
  State<BabyOnScreen> createState() => _BabyOnScreenState();
}

/// The root navigator's routes, bottom to top.
class _RouteStackObserver extends NavigatorObserver {
  final List<Route<dynamic>> stack = [];

  /// The top route that is a screen rather than a sheet, dialog or menu.
  Route<dynamic>? get topScreen {
    for (final route in stack.reversed) {
      if (route is! PopupRoute) return route;
    }
    return null;
  }

  void _changed() => BabyOnScreen.changes.value++;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : stack.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) {
      stack[index] = newRoute;
    } else if (newRoute != null) {
      stack.add(newRoute);
    }
    _changed();
  }
}

class _BabyOnScreenState extends State<BabyOnScreen> {
  bool get _isVisible {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      // Under a sheet or dialog is still on screen; under another page is not.
      final observer = BabyOnScreen.observer as _RouteStackObserver;
      if (observer.topScreen != route) return false;
    }
    // A whole-screen marker holds across its tabs; a baby only counts in the
    // tab that is showing.
    return widget.wholeScreen || TickerMode.of(context);
  }

  void _notify() => BabyOnScreen.changes.value++;

  @override
  void initState() {
    super.initState();
    BabyOnScreen._mounted.add(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    BabyOnScreen._mounted.remove(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The baby popping up at the bottom of the screen to say her line, on the
/// screens that have no baby card of their own — My Health, reminders,
/// settings, sheets.
///
/// Mounted once, above the navigator, from `GetMaterialApp.builder`. It shows
/// while a narration clip is playing and no [BabyOnScreen] is visible, lingers
/// a moment after the clip ends so the last words can be read, then slides
/// away. The ✕ stops the baby and closes it; the speaker stops or replays.
class BabyBottomAvatar extends StatefulWidget {
  const BabyBottomAvatar({super.key});

  /// Room left under the popup for the shell's bottom bar and its mic button.
  static const bottomClearance = 96.0;

  /// How far the dark wash behind the popup reaches above [bottomClearance]:
  /// the popup's own height plus a long fade so it has no visible edge.
  static const scrimRise = 220.0;

  /// How long the line stays up after the clip ends.
  static const linger = Duration(milliseconds: 2500);

  static const popupKey = Key('babyBottomAvatar');

  @override
  State<BabyBottomAvatar> createState() => _BabyBottomAvatarState();
}

class _BabyBottomAvatarState extends State<BabyBottomAvatar> {
  final List<Worker> _workers = [];
  Timer? _lingerTimer;

  bool _visible = false;
  bool _speaking = false;
  String _text = '';

  /// The line on show, kept after the clip ends so the speaker can replay it.
  String _lastKey = '';

  @override
  void initState() {
    super.initState();
    BabyOnScreen.changes.addListener(_scheduleUpdate);
    _attach();
  }

  /// The audio controller is registered during start-up and may not exist on
  /// the first frame; wait for it rather than never showing.
  void _attach() {
    if (!mounted) return;
    if (!BackgroundAudioController.isReady) {
      Future.delayed(const Duration(milliseconds: 500), _attach);
      return;
    }
    final audio = BackgroundAudioController.to;
    _workers
      ..add(ever<bool>(audio.isPlaying, (_) => _scheduleUpdate()))
      ..add(ever<String>(audio.currentText, (_) => _scheduleUpdate()))
      ..add(ever<String>(audio.currentKey, (_) => _scheduleUpdate()));
    _scheduleUpdate();
  }

  @override
  void dispose() {
    BabyOnScreen.changes.removeListener(_scheduleUpdate);
    for (final worker in _workers) {
      worker.dispose();
    }
    _lingerTimer?.cancel();
    super.dispose();
  }

  /// After the frame: a route push fires the new screen's narration before
  /// the screen's own baby card has registered.
  void _scheduleUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted || !BackgroundAudioController.isReady) return;
    final audio = BackgroundAudioController.to;
    final text = audio.currentText.value.trim();
    final speaking = audio.isPlaying.value && audio.currentKey.value.isNotEmpty;

    // A card on screen is already saying it.
    if (BabyOnScreen.anyVisible || text.isEmpty) {
      _lingerTimer?.cancel();
      if (_visible || _speaking) {
        setState(() {
          _visible = false;
          _speaking = false;
        });
      }
      return;
    }

    if (speaking) {
      _lastKey = audio.currentKey.value;
      _lingerTimer?.cancel();
      setState(() {
        _visible = true;
        _speaking = true;
        _text = text;
      });
      return;
    }

    // Clip finished: keep the words up briefly, then go.
    if (_speaking) {
      setState(() => _speaking = false);
      _lingerTimer?.cancel();
      _lingerTimer = Timer(BabyBottomAvatar.linger, () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  void _toggleSpeech() {
    if (!BackgroundAudioController.isReady) return;
    final audio = BackgroundAudioController.to;
    if (_speaking) {
      audio.stop();
    } else if (_lastKey.isNotEmpty) {
      audio.replay(_lastKey);
    }
  }

  void _dismiss() {
    _lingerTimer?.cancel();
    setState(() {
      _visible = false;
      _speaking = false;
    });
    if (BackgroundAudioController.isReady) BackgroundAudioController.to.stop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).viewPadding.bottom +
        BabyBottomAvatar.bottomClearance;

    return Positioned.fill(
      child: Stack(
        children: [
          // A soft dark wash rising from the bottom edge, so the popup stands
          // off whatever card is under it. Never takes touches: the screen
          // stays usable while she talks.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottom + BabyBottomAvatar.scrimRise,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 280),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x33000000),
                        Color(0x66000000),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: bottom,
            child: IgnorePointer(
              ignoring: !_visible,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, 0.4),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  child: _BabyPopup(
                    key: BabyBottomAvatar.popupKey,
                    text: _text,
                    speaking: _speaking,
                    onSpeakerTap: _toggleSpeech,
                    onClose: _dismiss,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The baby on the theme's nebula, with her line in a bubble beside her.
class _BabyPopup extends StatelessWidget {
  const _BabyPopup({
    super.key,
    required this.text,
    required this.speaking,
    required this.onSpeakerTap,
    required this.onClose,
  });

  final String text;
  final bool speaking;

  /// Stops her mid-line, or says the line again once she has finished.
  final VoidCallback onSpeakerTap;

  /// Stops her and puts the popup away.
  final VoidCallback onClose;

  static const closeKey = Key('babyBottomAvatarClose');

  static const _babySize = 84.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Material(
      type: MaterialType.transparency,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // The baby, standing straight on the glow as she does on Home.
          SizedBox(
            width: _babySize,
            height: _babySize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: BabyThemeNebula()),
                Image.asset(
                  speaking ? BabyAnimations.speaking : BabyAnimations.idle,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/allobaby/AlloMombabySquare.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    painter: _SideTailPainter(
                      color: p.pick(Colors.white, p.card),
                      shadowColor: const Color(
                        0xFFFF8A9E,
                      ).withValues(alpha: 0.22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _SideTailPainter.tailWidth + 14,
                        12,
                        10,
                        12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              text,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: p.pick(
                                  const Color(0xFF2D3142),
                                  p.textPrimary,
                                ),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          NarrationSpeakerButton(
                            onTap: onSpeakerTap,
                            speaking: speaking,
                          ),
                          // Room for the close button over the corner.
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -6,
                    child: BabyBubbleCloseButton(key: closeKey, onTap: onClose),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded bubble with its tail on the left, pointing at the baby.
class _SideTailPainter extends CustomPainter {
  _SideTailPainter({required this.color, required this.shadowColor});

  final Color color;
  final Color shadowColor;

  static const tailWidth = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 20.0;
    const tailHeight = 16.0;

    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tailWidth, 0, size.width - tailWidth, size.height),
          const Radius.circular(radius),
        ),
      );

    // Tail at the middle of the left edge, pointing at the baby. It overlaps
    // the body by a couple of pixels and is unioned into it: drawn as a second
    // sub-path its winding cancelled the overlap and left a hole at the join.
    final tailY = size.height / 2;
    final tail = Path()
      ..moveTo(tailWidth + 2, tailY - tailHeight / 2)
      ..lineTo(0, tailY)
      ..lineTo(tailWidth + 2, tailY + tailHeight / 2)
      ..close();

    final path = Path.combine(PathOperation.union, body, tail);

    canvas.drawShadow(path, shadowColor, 8, true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SideTailPainter old) =>
      old.color != color || old.shadowColor != shadowColor;
}
