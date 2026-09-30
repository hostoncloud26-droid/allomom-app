import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:allomom/allowear/entry/allowear_device_summary_flow.dart';

/// The AlloWear card AlloConnect shows when the app opens: reconnecting to the
/// band and syncing it, or offering to pair one.
///
/// Ported from AlloConnect's `AppOpenPopupRoute` — the same slide-up sheet,
/// drag-to-dismiss and tap-outside-to-close — without the AlloBot button, TTS
/// and popup queue that only AlloConnect's home has.
class AllowearAppOpenPopup extends PopupRoute<void> {
  AllowearAppOpenPopup({required this.child});

  final Widget child;

  /// Once per launch, as on AlloConnect.
  static bool _shownThisLaunch = false;

  /// Shows the card over [context]'s screen, the first time it is asked in
  /// this launch and only while that screen is the one on top — a page opened
  /// from a notification tap keeps the screen to itself.
  static void showOnAppOpen(BuildContext context) {
    if (_shownThisLaunch || !context.mounted) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _shownThisLaunch = true;

    final navigator = Navigator.of(context);
    navigator.push(
      AllowearAppOpenPopup(
        child: AppOpenDeviceSummaryFlow(
          onClose: () {
            if (navigator.canPop()) navigator.pop();
          },
        ),
      ),
    );
  }

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.48);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss popup';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 520);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 340);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _AllowearPopupSheet(animation: animation, child: child);
  }
}

class _AllowearPopupSheet extends StatefulWidget {
  const _AllowearPopupSheet({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_AllowearPopupSheet> createState() => _AllowearPopupSheetState();
}

class _AllowearPopupSheetState extends State<_AllowearPopupSheet> {
  double _dragOffsetY = 0.0;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticFeedback.lightImpact();
    }
  }

  void _dismiss() {
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardSlideCurve = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium?.copyWith(
              decoration: TextDecoration.none,
            ) ??
            const TextStyle(decoration: TextDecoration.none),
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            final cardSlideY = (1.0 - cardSlideCurve.value) * 420.0;
            final maxHeight = mediaQuery.size.height * 0.88;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Tapping outside closes it.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _dismiss,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Transform.translate(
                    offset: Offset(0, _dragOffsetY + cardSlideY),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        final delta = details.primaryDelta ?? 0;
                        if (delta > 0 || _dragOffsetY > 0) {
                          setState(() {
                            _dragOffsetY = math.max(0.0, _dragOffsetY + delta);
                          });
                        }
                      },
                      onVerticalDragEnd: (details) {
                        if (_dragOffsetY > 70 ||
                            (details.primaryVelocity ?? 0) > 260) {
                          _dismiss();
                        } else {
                          setState(() => _dragOffsetY = 0.0);
                        }
                      },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E222D)
                                : Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.10),
                                width: 1.2,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.45 : 0.16,
                                ),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Container(
                                    width: 38,
                                    height: 4.5,
                                    margin: const EdgeInsets.only(
                                      top: 10,
                                      bottom: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                widget.child,
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
