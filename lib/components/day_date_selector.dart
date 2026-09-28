import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:allomom/components/app_backdrop.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Horizontal day strip, styled after the selector on the prescription
/// timings screen.
///
/// Today sits in the middle of the strip, with a fortnight either side of it.
/// The days ahead are drawn but dimmed and inert: there is nothing to show for
/// a day that has not happened yet.
class DayDateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DayDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  static const double height = 120;

  /// Days shown either side of today.
  static const int daysEitherSide = 14;

  @override
  State<DayDateSelector> createState() => _DayDateSelectorState();
}

class _DayDateSelectorState extends State<DayDateSelector> {
  static const int _dateItemCount = DayDateSelector.daysEitherSide * 2 + 1;
  static const double _dateTileWidth = 58;
  static const double _dateTileGap = 12;

  final ScrollController _dateScrollController = ScrollController();

  late DateTime _dateStart;

  int get _selectedDateIndex => DateUtils.dateOnly(
    widget.selectedDate,
  ).difference(_dateStart).inDays.clamp(0, _dateItemCount - 1);

  @override
  void initState() {
    super.initState();
    _dateStart = DateUtils.dateOnly(
      DateTime.now(),
    ).subtract(const Duration(days: DayDateSelector.daysEitherSide));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(jump: true);
    });
  }

  @override
  void didUpdateWidget(covariant DayDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate();
      });
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate({bool jump = false}) {
    if (!_dateScrollController.hasClients) return;

    final viewportWidth = _dateScrollController.position.viewportDimension;
    final rawOffset =
        (_selectedDateIndex * (_dateTileWidth + _dateTileGap)) -
        ((viewportWidth - _dateTileWidth) / 2);

    final targetOffset = math.max<double>(
      0.0,
      math.min<double>(
        rawOffset,
        _dateScrollController.position.maxScrollExtent,
      ),
    );

    if (jump) {
      _dateScrollController.jumpTo(targetOffset);
    } else {
      _dateScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateUtils.dateOnly(DateTime.now());
    // Over Home's pastel backdrop the strip takes the wash's colours (see
    // [StickyDateSelectorOverlay]), so it and its tiles go translucent.
    final onBackdrop = AppBackdrop.isActive(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: DayDateSelector.height,
      decoration: BoxDecoration(
        color: onBackdrop
            ? Colors.transparent
            : Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: onBackdrop
                ? primary.withOpacity(isDark ? 0.12 : 0.10)
                : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(widget.selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onDateSelected(today);
                    _scrollToSelectedDate();
                  },
                  child: Text(
                    'Go to Today'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _dateItemCount,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final date = _dateStart.add(Duration(days: index));
                final isSelected = DateUtils.isSameDay(
                  date,
                  widget.selectedDate,
                );
                final isToday = DateUtils.isSameDay(date, today);
                final isFuture = date.isAfter(today);
                final dayName = DateFormat('E').format(date).toUpperCase();
                final dayNum = DateFormat('d').format(date);

                final Color labelColor;
                final Color numberColor;
                if (isSelected) {
                  labelColor = Colors.white.withOpacity(0.8);
                  numberColor = Colors.white;
                } else if (isFuture) {
                  labelColor = Colors.grey.shade500.withOpacity(0.35);
                  numberColor =
                      (isDark ? Colors.white : const Color(0xFF1E293B))
                          .withOpacity(0.28);
                } else {
                  labelColor = Colors.grey.shade500;
                  numberColor = isDark ? Colors.white : const Color(0xFF1E293B);
                }

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _dateItemCount - 1 ? 0 : _dateTileGap,
                  ),
                  child: GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                            if (!DateUtils.isSameDay(
                              widget.selectedDate,
                              date,
                            )) {
                              widget.onDateSelected(date);
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _dateTileWidth,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isDark
                            ? Colors.white.withOpacity(isFuture ? 0.02 : 0.05)
                            : onBackdrop
                            ? Colors.white.withOpacity(isFuture ? 0.35 : 0.75)
                            : (isFuture
                                  ? const Color(0xFFF8FAFF).withOpacity(0.5)
                                  : const Color(0xFFF8FAFF)),
                        boxShadow: isSelected && onBackdrop
                            ? [
                                BoxShadow(
                                  color: primary.withOpacity(0.30),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isToday
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3)
                              : isDark
                              ? Colors.white.withOpacity(isFuture ? 0.04 : 0.12)
                              : onBackdrop
                              ? Colors.white.withOpacity(isFuture ? 0.4 : 0.9)
                              : const Color(
                                  0xFFE2E8F0,
                                ).withOpacity(isFuture ? 0.5 : 1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: numberColor,
                            ),
                          ),
                          if (isToday && !isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Drops a [DayDateSelector] in from under [top] when [visible] turns on.
///
/// Clipped to exactly its own height, so while hidden nothing at all paints --
/// no strip, and no shadow bleeding past the clip. Meant to sit in a [Stack]
/// over a scroll view, never inside the scrolled content.
class StickyDateSelectorOverlay extends StatelessWidget {
  final bool visible;

  /// Where the strip itself begins.
  final double top;

  /// Opaque band painted immediately above the strip, in the same colour.
  /// A page with no app bar needs this to be the status bar height, so the
  /// scrolling content does not show through behind the status bar; a page
  /// whose app bar already covers that area leaves it at zero.
  final double scrimHeight;

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const StickyDateSelectorOverlay({
    super.key,
    required this.visible,
    required this.top,
    required this.selectedDate,
    required this.onDateSelected,
    this.scrimHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top - scrimHeight,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: SizedBox(
          height: DayDateSelector.height + scrimHeight,
          child: ClipRect(
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _surface(
                context,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (scrimHeight > 0)
                      SizedBox(height: scrimHeight, width: double.infinity),
                    DayDateSelector(
                      selectedDate: selectedDate,
                      onDateSelected: onDateSelected,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Solid in the page colour normally; over Home's backdrop, an opaque
  /// blush-to-lavender band matching the wash, so it belongs to the page and
  /// nothing shows through it.
  Widget _surface(BuildContext context, Widget child) {
    if (!AppBackdrop.isActive(context)) {
      return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        child: child,
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? const [Color(0xff1E1519), Color(0xff17151F)]
                : const [Color(0xFFFFF1F3), Color(0xFFFBF6FF)],
          ),
        ),
        child: child,
      ),
    );
  }
}
