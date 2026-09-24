// Stand-in for flutter_slidable's `Slidable` + `ActionPane(motion: BehindMotion)`
// that AlloConnect's meal history tiles use (the package isn't in Allomom).
import 'package:flutter/material.dart';

class MealSwipeAction {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const MealSwipeAction({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });
}

class MealSwipeActions extends StatefulWidget {
  final Widget child;
  final List<MealSwipeAction> actions;
  final double extentRatio;

  const MealSwipeActions({
    super.key,
    required this.child,
    required this.actions,
    this.extentRatio = 0.44,
  });

  @override
  State<MealSwipeActions> createState() => _MealSwipeActionsState();
}

class _MealSwipeActionsState extends State<MealSwipeActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => _controller.animateTo(0, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.maxWidth * widget.extentRatio;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (d) {
            _controller.value =
                (_controller.value - d.primaryDelta! / extent).clamp(0.0, 1.0);
          },
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            final open = v < -300 || (v <= 300 && _controller.value > 0.5);
            _controller.animateTo(open ? 1 : 0, curve: Curves.easeOut);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: extent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final action in widget.actions)
                          Expanded(
                            child: Material(
                              color: action.backgroundColor,
                              child: InkWell(
                                onTap: () {
                                  _close();
                                  action.onPressed();
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(action.icon,
                                        color: action.foregroundColor),
                                    const SizedBox(height: 4),
                                    Text(
                                      action.label,
                                      style: TextStyle(
                                        color: action.foregroundColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  offset: Offset(-_controller.value * extent, 0),
                  child: child,
                ),
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}
