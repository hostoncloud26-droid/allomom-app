import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:allomom/services/part_of_day.dart';

/// The room behind the baby — a morning, afternoon, evening or night scene
/// by the clock — reaching from the very top of the screen (under the status
/// bar and the shell's transparent app bar) down to [anchorKey]'s bottom
/// edge (or its own bottom, if that comes first), fading into the page's
/// backdrop over the last [fade] of it.
///
/// The scene is placed so its bed runs exactly where the baby sits — [seatLift]
/// above the top of [seatKey], the speech card — on any screen size, scaling
/// up only when it has to so it still reaches the top of the screen.
///
/// Sits behind Home's scroll view and moves with [scroll], so it reads as
/// part of the first screen rather than a fixed wallpaper. Its parent Stack
/// must not clip, since the scene deliberately paints above its own bounds.
class TimeOfDayScene extends StatefulWidget {
  const TimeOfDayScene({
    super.key,
    required this.scroll,
    required this.anchorKey,
    required this.seatKey,
    this.seatLift = 16,
    this.fade = 64,
  });

  final ScrollController scroll;

  /// The scene ends at this widget's bottom edge — the whole hero.
  final GlobalKey anchorKey;

  /// The speech card the baby sits just above.
  final GlobalKey seatKey;

  /// How far above [seatKey]'s top the baby's bottom rests.
  final double seatLift;

  /// How tall the fade into the page is.
  final double fade;

  @override
  State<TimeOfDayScene> createState() => _TimeOfDaySceneState();
}

class _TimeOfDaySceneState extends State<TimeOfDayScene>
    with WidgetsBindingObserver {
  /// How far below the top of the screen this widget starts.
  double _screenTop = 0;

  /// The anchor's bottom edge and the seat's top edge, in scroll-content
  /// coordinates.
  double? _anchorBottom;
  double? _seatTop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Timers may not have fired while the app was in the background.
    if (state == AppLifecycleState.resumed) PartOfDayClock.instance.refresh();
  }

  double get _offset =>
      widget.scroll.hasClients ? math.max(0.0, widget.scroll.offset) : 0.0;

  RenderBox? _box(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize && box.attached ? box : null;
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final self = context.findRenderObject();
    final anchor = _box(widget.anchorKey);
    final seat = _box(widget.seatKey);
    if (self is! RenderBox || !self.hasSize || anchor == null || seat == null) {
      return;
    }

    final top = self.localToGlobal(Offset.zero).dy;
    double toContent(RenderBox box, double dy) =>
        box.localToGlobal(Offset(0, dy)).dy - top + _offset;
    final anchorBottom = toContent(anchor, anchor.size.height);
    final seatTop = toContent(seat, 0);

    bool moved(double? a, double b) => a == null || (a - b).abs() > 0.5;
    if ((top - _screenTop).abs() > 0.5 ||
        moved(_anchorBottom, anchorBottom) ||
        moved(_seatTop, seatTop)) {
      setState(() {
        _screenTop = top;
        _anchorBottom = anchorBottom;
        _seatTop = seatTop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-measured after every rebuild of Home: the card can grow when the
    // baby's choices appear under her line.
    WidgetsBinding.instance.addPostFrameCallback(_measure);

    final anchorBottom = _anchorBottom;
    final seatTop = _seatTop;
    if (anchorBottom == null || seatTop == null) return const SizedBox.shrink();

    // Everything below is measured from the top of the screen.
    final height = _screenTop + anchorBottom;
    final seat = _screenTop + seatTop - widget.seatLift;
    final width = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return ListenableBuilder(
      listenable: widget.scroll,
      builder: (context, _) {
        final offset = _offset;
        // Scrolled wholly out of view.
        if (height - offset <= 0) return const SizedBox.shrink();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -_screenTop - offset,
              left: 0,
              right: 0,
              height: height,
              child: IgnorePointer(
                child: ClipRect(
                  child: ValueListenableBuilder<PartOfDay>(
                    valueListenable: PartOfDayClock.instance,
                    builder: (context, part, _) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, ?current],
                      ),
                      child: _SeatedScene(
                        key: ValueKey(part),
                        part: part,
                        areaWidth: width,
                        areaHeight: height,
                        seat: seat,
                        fade: widget.fade,
                        devicePixelRatio: dpr,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One scene, sized and shifted so its [PartOfDay.bedLine] lands on [seat],
/// fading out over [fade] at the area's bottom or its own, whichever is
/// higher.
class _SeatedScene extends StatelessWidget {
  const _SeatedScene({
    super.key,
    required this.part,
    required this.areaWidth,
    required this.areaHeight,
    required this.seat,
    required this.fade,
    required this.devicePixelRatio,
  });

  final PartOfDay part;
  final double areaWidth;
  final double areaHeight;
  final double seat;
  final double fade;
  final double devicePixelRatio;

  @override
  Widget build(BuildContext context) {
    final bed = part.bedLine;
    final naturalHeight = areaWidth * PartOfDay.sceneAspect;

    // At screen width the scene must still reach the top of the screen above
    // the bed; grow it if it falls short, trimming the extra width evenly
    // from both sides. Below the bed it simply fades out where it ends.
    final scale = math.max(1.0, seat / (bed * naturalHeight));
    final w = areaWidth * scale;
    final h = naturalHeight * scale;
    final top = seat - bed * h;
    final end = math.min(areaHeight, top + h);
    final fadeStart = ((end - fade) / areaHeight).clamp(0.0, 1.0);
    final fadeEnd = (end / areaHeight).clamp(fadeStart, 1.0);

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Colors.black,
          Colors.black,
          Colors.transparent,
          Colors.transparent,
        ],
        stops: [0, fadeStart, fadeEnd, 1],
      ).createShader(rect),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (areaWidth - w) / 2,
            top: top,
            width: w,
            height: h,
            child: Image(
              image: ResizeImage(
                AssetImage(part.backgroundAsset),
                width: (w * devicePixelRatio).round(),
              ),
              fit: BoxFit.fill,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
