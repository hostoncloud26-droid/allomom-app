import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:allomom/config/app_theme.dart';

const _pink = Color(0xFFFF3B5C);

/// One wagon on a [JourneyTrain].
class TrainWagon {
  const TrainWagon({
    required this.value,
    required this.number,
    required this.label,
  });

  /// What [JourneyTrain.onSelected] is called with.
  final int value;

  /// The big figure on the wagon: "0", "14", "All".
  final String number;

  /// The small word under it: "Newborn", "Months", "Week".
  final String label;
}

/// `babytrain.png` pulling a row of wagons along a rail — the milestone train
/// on the baby view, the week train on the pregnancy view. Sits straight on
/// the page, no card, and scrolls the selected wagon into view.
class JourneyTrain extends StatefulWidget {
  const JourneyTrain({
    super.key,
    required this.title,
    required this.wagons,
    required this.selected,
    required this.onSelected,
    this.current,
    this.chip,
  });

  final String title;
  final List<TrainWagon> wagons;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Where the journey is today: outlined even when not selected.
  final int? current;

  /// The small pink tag on the right of the heading: "Day 373", "Week 14".
  final String? chip;

  @override
  State<JourneyTrain> createState() => _JourneyTrainState();
}

class _JourneyTrainState extends State<JourneyTrain> {
  final _selectedKey = GlobalKey();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(covariant JourneyTrain old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _scrollToSelected();
  }

  /// Centres the selected wagon in the train's own horizontal scroll only.
  /// `Scrollable.ensureVisible` would also scroll the page it sits on,
  /// pulling the screen down so the top of it opened cut off.
  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wagon = _selectedKey.currentContext?.findRenderObject();
      if (wagon == null || !_scroll.hasClients) return;
      final viewport = RenderAbstractViewport.maybeOf(wagon);
      if (viewport == null) return;
      final target = viewport
          .getOffsetToReveal(wagon, 0.5)
          .offset
          .clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _pink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: p.textSecondary,
                  ),
                ),
              ),
              if (widget.chip != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.tint(_pink, const Color(0xFFFFEEF1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.chip!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Stack(
              children: [
                // The rail the wheels sit on.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 4,
                  child: Container(
                    height: 2,
                    color: p.pick(const Color(0xFFE5E7EB), p.border),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Image.asset(
                        'assets/Quick Actions/babytrain.png',
                        height: 74,
                        fit: BoxFit.contain,
                      ),
                    ),
                    for (final w in widget.wagons) ...[
                      _coupler(p),
                      _wagon(w, p),
                    ],
                    const SizedBox(width: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coupler(AppPalette p) => Padding(
    padding: const EdgeInsets.only(bottom: 30),
    child: Container(
      width: 8,
      height: 3,
      color: p.pick(const Color(0xFFCBD5E1), p.border),
    ),
  );

  Widget _wagon(TrainWagon w, AppPalette p) {
    final selected = w.value == widget.selected;
    final now = w.value == widget.current;

    return GestureDetector(
      key: selected ? _selectedKey : null,
      onTap: () => widget.onSelected(w.value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: selected ? _pink : p.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? _pink
                    : now
                    ? _pink.withValues(alpha: 0.5)
                    : p.pick(const Color(0xFFE2E8F0), p.border),
                width: selected || now ? 1.6 : 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _pink.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The label sits over the number.
                Text(
                  w.label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.9)
                        : p.textMuted,
                  ),
                ),
                Text(
                  w.number,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: selected ? Colors.white : p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // The wagon's wheels.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 2; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? _pink
                        : p.pick(const Color(0xFF94A3B8), p.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
