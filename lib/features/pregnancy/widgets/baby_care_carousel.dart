import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/pregnancy/widgets/baby_growth_track.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';

const _pink = Color(0xFFFF3B5C);
const _vaccineAccent = Color(0xFF8B5CF6);
const _milestoneAccent = Color(0xFFF59E0B);
const _green = Color(0xFF10B981);

/// Every vaccination as a swipeable card, in date order: what is past sits to
/// the left, what is still to come to the right, and the carousel opens on the
/// latest dose due.
class VaccinationCarousel extends StatelessWidget {
  const VaccinationCarousel({
    super.key,
    required this.doses,
    required this.onDoseGiven,
    this.onShowAll,
    this.focus,
  });

  /// A month picked on the train, with the birth it counts from: the pager
  /// swipes to that month's first dose. [BabyCarouselFocus.seq] tells a
  /// second tap on the same wagon from no tap.
  final BabyCarouselFocus? focus;

  final List<BabyImmunizationRecord> doses;

  /// Marks a dose given (true) or not given yet (false).
  final Future<void> Function(BabyImmunizationRecord dose, bool given)
  onDoseGiven;

  /// Opens the full Vaccination page.
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final sorted = [...doses]..sort(_byDate((d) => d.expectedDate));

    return CareCarousel<BabyImmunizationRecord>(
      title: 'Vaccinations',
      accent: _vaccineAccent,
      onShowAll: onShowAll,
      focus: _monthFocus(focus),
      monthOf: (d) => babyMonthOf(focus!.birth, d.expectedDate),
      height: 150,
      items: sorted,
      dateOf: (d) => d.expectedDate,
      card: (d, isCurrent) {
        final due = d.expectedDate;
        final given = d.vaccinationDate;
        final status = CareStatus.resolve(
          status: given != null ? 'done' : 'pending',
          date: due,
        );
        final canMark = careIsDue(due);
        return CareCarouselCard(
          isCurrent: isCurrent,
          pill: switch (status) {
            CareStatus.completed => const CarePill(
              status: CareStatus.completed,
              label: 'Given',
            ),
            CareStatus.overdue => const CarePill(
              status: CareStatus.overdue,
              label: 'Overdue',
            ),
            CareStatus.scheduled => const CarePill(
              status: CareStatus.scheduled,
              label: 'Upcoming',
            ),
            _ => CarePill(status: status),
          },
          eyebrow: given != null
              ? 'Given ${careDateFmt.format(given)}'
              : due == null
              ? 'No due date set'
              : 'Due ${careDateFmt.format(due)} · ${relativeDayLabel(due)}',
          title: d.vaccineName,
          done: given != null,
          actionLabel: canMark
              ? 'Mark as completed'
              : 'Can mark from ${careDateFmt.format(due!)}',
          actionEnabled: canMark,
          onAction: (value) => onDoseGiven(d, value),
          onTap: () => showCareDetailSheet(
            context,
            eyebrow: 'Vaccination',
            title: d.vaccineName,
            status: status,
            facts: [
              (
                Icons.event_rounded,
                due == null
                    ? 'Date to be decided'
                    : 'Due ${careDateFmt.format(due)}',
              ),
              if (given != null)
                (Icons.verified_rounded, 'Given ${careDateFmt.format(given)}'),
            ],
            primaryLabel: given != null ? 'Mark as not given' : 'Mark as given',
            primaryIcon: given != null
                ? Icons.undo_rounded
                : Icons.check_circle_outline_rounded,
            primaryQuiet: given != null,
            primaryEnabled: given != null || canMark,
            disabledNote: 'You can mark it once the due date arrives.',
            onPrimary: () => onDoseGiven(d, given == null),
          ),
        );
      },
    );
  }
}

/// Every milestone as a swipeable card, in date order, opening on the latest
/// one due. A card opens its details in a sheet, where it is marked reached. A late milestone is a guide, not a deadline, so it says
/// "Not reached yet" rather than "Overdue".
class MilestoneCarousel extends StatelessWidget {
  const MilestoneCarousel({
    super.key,
    required this.milestones,
    required this.onMilestoneReached,
    this.onShowAll,
    this.focus,
  });

  /// A month picked on the train: the pager swipes to its first milestone.
  final BabyCarouselFocus? focus;

  final List<BabyMilestone> milestones;

  /// Marks a milestone reached (true) or not yet (false).
  final Future<void> Function(BabyMilestone milestone, bool reached)
  onMilestoneReached;

  /// Opens the full Milestones page.
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final sorted = [...milestones]..sort(_byDate((m) => m.expectedDate));

    return CareCarousel<BabyMilestone>(
      title: 'Milestones',
      accent: _milestoneAccent,
      height: 150,
      onShowAll: onShowAll,
      focus: _monthFocus(focus),
      monthOf: (m) => babyMonthOf(focus!.birth, m.expectedDate),
      items: sorted,
      dateOf: (m) => m.expectedDate,
      card: (m, isCurrent) {
        final expected = m.expectedDate;
        final isPast =
            expected != null &&
            DateUtils.dateOnly(
              expected,
            ).isBefore(DateUtils.dateOnly(DateTime.now()));
        return CareCarouselCard(
          isCurrent: isCurrent,
          pill: m.achieved
              ? const CarePill(status: CareStatus.completed, label: 'Reached')
              : isPast
              ? const CarePill(
                  status: CareStatus.overdue,
                  label: 'Not reached yet',
                )
              : const CarePill(status: CareStatus.scheduled, label: 'Upcoming'),
          eyebrow: m.completedAt != null
              ? 'Reached ${careDateFmt.format(m.completedAt!)}'
              : expected == null
              ? 'Any time now'
              : 'Usually around ${careDateFmt.format(expected)}',
          title: m.milestone,
          subtitle: m.description,
          onTap: () => showCareDetailSheet(
            context,
            eyebrow: 'Milestone',
            title: m.milestone,
            status: CareStatus.resolve(
              status: m.achieved ? 'done' : 'pending',
              date: expected,
            ),
            statusLabel: m.achieved ? null : 'Watch for it',
            facts: [
              if (m.description.isNotEmpty)
                (Icons.info_outline_rounded, m.description),
              if (expected != null)
                (
                  Icons.event_rounded,
                  'Usually around ${careDateFmt.format(expected)}',
                ),
              if (m.completedAt != null)
                (
                  Icons.emoji_events_rounded,
                  'Reached ${careDateFmt.format(m.completedAt!)}',
                ),
            ],
            primaryLabel: m.achieved ? 'Mark as not yet' : 'Mark as reached',
            primaryIcon: m.achieved
                ? Icons.undo_rounded
                : Icons.emoji_events_rounded,
            primaryQuiet: m.achieved,
            onPrimary: () => onMilestoneReached(m, !m.achieved),
          ),
        );
      },
    );
  }
}

// ── Shared ──────────────────────────────────────────────────────────────────

/// A month picked on the train for the pagers to swipe to. [seq] goes up on
/// every tap, so picking the same wagon again still brings the pager back.
typedef BabyCarouselFocus = ({DateTime birth, int month, int seq});

/// A month picked on a train — the baby's or the pregnancy's — for a
/// [CareCarousel] to swipe to. [seq] goes up on every tap.
typedef CareCarouselFocus = ({int month, int seq});

CareCarouselFocus? _monthFocus(BabyCarouselFocus? f) =>
    f == null ? null : (month: f.month, seq: f.seq);

int Function(T, T) _byDate<T>(DateTime? Function(T) dateOf) => (a, b) {
  final da = dateOf(a), db = dateOf(b);
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
};

/// A section title with "Show all", over a full-width
/// pager whose next card peeks in from the right. Shared by the baby's
/// vaccinations and milestones and the pregnancy's checklist.
class CareCarousel<T> extends StatefulWidget {
  const CareCarousel({
    super.key,
    required this.title,
    required this.accent,
    required this.height,
    required this.items,
    required this.dateOf,
    required this.card,
    required this.monthOf,
    this.onShowAll,
    this.focus,
  });

  final String title;
  final Color accent;
  final double height;

  /// Already in date order.
  final List<T> items;
  final DateTime? Function(T) dateOf;
  final Widget Function(T item, bool isCurrent) card;
  final VoidCallback? onShowAll;
  final CareCarouselFocus? focus;

  /// The train month an item falls in; asked only while [focus] is set.
  final int Function(T) monthOf;

  @override
  State<CareCarousel<T>> createState() => CareCarouselState<T>();
}

class CareCarouselState<T> extends State<CareCarousel<T>> {
  late final PageController _controller;

  /// The latest item by date: the last one due on or before today, the
  /// first of its day when several share it. Before anything is due, the
  /// first item.
  int get _currentIndex {
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime? latest;
    for (final item in widget.items) {
      final date = widget.dateOf(item);
      if (date == null) continue;
      final day = DateUtils.dateOnly(date);
      if (!day.isAfter(today)) latest = day;
    }
    if (latest == null) return 0;
    final i = widget.items.indexWhere((e) {
      final date = widget.dateOf(e);
      return date != null && DateUtils.dateOnly(date) == latest;
    });
    return i == -1 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.9,
      initialPage: widget.items.isEmpty ? 0 : _currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant CareCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focus = widget.focus;
    if (focus == null || focus.seq == oldWidget.focus?.seq) return;
    final index = _indexForMonth(focus);
    if (index == null || !_controller.hasClients) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  /// The first item in [focus]'s month; failing that, the first one after
  /// it, or the last one before it.
  int? _indexForMonth(CareCarouselFocus focus) {
    if (widget.items.isEmpty) return null;
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (widget.dateOf(item) != null && widget.monthOf(item) >= focus.month) {
        return i;
      }
    }
    return widget.items.length - 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final current = _currentIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CareSectionLabel(widget.title, color: widget.accent),
            ),
            if (widget.onShowAll != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: TextButton(
                  onPressed: widget.onShowAll,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.accent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Show all'),
                ),
              ),
          ],
        ),
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            clipBehavior: Clip.none,
            itemCount: widget.items.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 6),
              child: widget.card(widget.items[i], i == current),
            ),
          ),
        ),
      ],
    );
  }
}

/// One item: its status, when it is due and what it is. With [onAction], a
/// round tick in the bottom-right corner marks it done — or, once done,
/// undoes it. The status sits in the top-right corner.
class CareCarouselCard extends StatelessWidget {
  const CareCarouselCard({
    super.key,
    required this.isCurrent,
    required this.pill,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.done = false,
    this.actionLabel = '',
    this.actionEnabled = false,
    this.onAction,
    this.onTap,
  });

  final bool isCurrent;
  final Widget pill;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool done;
  final String actionLabel;
  final bool actionEnabled;

  /// Called with the new done state; null for a card without the tick.
  final void Function(bool done)? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sub = subtitle?.trim() ?? '';

    final onAction = this.onAction;

    return CareCard(
      highlighted: isCurrent,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCurrent) ...[
                const Text(
                  'CURRENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: _pink,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // The status sits in the top-right corner.
              const Spacer(),
              pill,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eyebrow,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: p.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: p.textSecondary,
              ),
            ),
          ],
          if (onAction != null) ...[
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: done
                      ? const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 17,
                              color: _green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _green,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                ),
                if (done)
                  _RoundButton(
                    tooltip: 'Undo',
                    icon: Icons.undo_rounded,
                    background: p.pick(const Color(0xFFF3F4F6), p.surface),
                    foreground: p.textSecondary,
                    onTap: () => onAction(false),
                  )
                else
                  _RoundButton(
                    tooltip: actionEnabled ? 'Mark as completed' : actionLabel,
                    icon: Icons.check_rounded,
                    background: actionEnabled
                        ? _green
                        : p.pick(const Color(0xFFF3F4F6), p.surface),
                    foreground: actionEnabled ? Colors.white : p.textMuted,
                    onTap: actionEnabled ? () => onAction(true) : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The round tick or undo button in a card's bottom-right corner.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}
