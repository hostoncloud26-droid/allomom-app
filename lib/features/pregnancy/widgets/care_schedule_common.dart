import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';

import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';

/// Shared look and helpers for the three care schedule screens (ANC visits,
/// vaccinations, lab reports), all of which read rows scheduled locally when
/// the pregnancy was registered.

/// How a scheduled item is presented, derived from its status and due date.
enum CareStatus {
  completed,
  overdue,
  dueSoon,
  scheduled,
  missed;

  /// Resolves the display status for a row.
  ///
  /// `done` and `missed` come straight from the stored status; a pending row is
  /// overdue once its date has passed and "due soon" inside the next week.
  static CareStatus resolve({
    required String status,
    required DateTime? date,
    DateTime? now,
  }) {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'done' || normalized == 'completed') {
      return CareStatus.completed;
    }
    if (normalized == 'missed') return CareStatus.missed;

    if (date == null) return CareStatus.scheduled;
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final due = DateTime(date.year, date.month, date.day);

    if (due.isBefore(startOfToday)) return CareStatus.overdue;
    if (due.difference(startOfToday).inDays <= 7) return CareStatus.dueSoon;
    return CareStatus.scheduled;
  }

  String get label => switch (this) {
    CareStatus.completed => 'Completed',
    CareStatus.overdue => 'Overdue',
    CareStatus.dueSoon => 'Due soon',
    CareStatus.scheduled => 'Scheduled',
    CareStatus.missed => 'Missed',
  };

  Color get color => switch (this) {
    CareStatus.completed => const Color(0xFF10B981),
    CareStatus.overdue => const Color(0xFFEF4444),
    CareStatus.dueSoon => const Color(0xFFFF3B5C),
    CareStatus.scheduled => const Color(0xFF3898EC),
    CareStatus.missed => const Color(0xFF8E95A5),
  };

  Color get background => switch (this) {
    CareStatus.completed => const Color(0xFFD1FAE5),
    CareStatus.overdue => const Color(0xFFFEE2E2),
    CareStatus.dueSoon => const Color(0xFFFFF0F4),
    CareStatus.scheduled => const Color(0xFFEDF6FF),
    CareStatus.missed => const Color(0xFFF6F7FA),
  };

  bool get isDone => this == CareStatus.completed;

  /// Highlighted with a heavier border — the thing to act on next.
  bool get needsAttention =>
      this == CareStatus.overdue || this == CareStatus.dueSoon;
}

/// Pill showing a [CareStatus].
class CareStatusChip extends StatelessWidget {
  const CareStatusChip({super.key, required this.status});

  final CareStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.palette.tint(status.color, status.background),
        borderRadius: BorderRadius.circular(10),
      ),
      // One line, always. A pill that breaks "Scheduled" into "Schedule / d"
      // is worse than one that runs a shade narrow.
      child: Text(
        status.label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}

/// Shown when the mother has no active pregnancy, so nothing was scheduled.
class CareScheduleEmpty extends StatelessWidget {
  const CareScheduleEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRegistered,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Called after the registration flow reports success, so the caller can
  /// reload the freshly scheduled rows.
  final VoidCallback? onRegistered;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: p.tint(const Color(0xFFFF3B5C), const Color(0xFFFFF0F4)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: const Color(0xFFFF3B5C)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: p.pick(const Color(0xFF1E2024), p.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: p.pick(const Color(0xFF6B707B), p.textSecondary),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const PregnancyConfirmationPage(),
                  ),
                );
                if (created == true) onRegistered?.call();
              },
              icon: const Icon(Icons.favorite_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B5C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: Text(
                'Register pregnancy',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── List building blocks ────────────────────────────────────────────────────
//
// The three schedule screens read as lists, not tables: what is done, what is
// next, what comes later. One card per item keeps the next thing to do the
// loudest thing on the screen, and a tap opens its details and actions.

const Color _carePink = Color(0xFFFF3B5C);
const Color _careGreen = Color(0xFF10B981);
const Color _careOrange = Color(0xFFF59E0B);
const Color _careRed = Color(0xFFEF4444);

final DateFormat careDateFmt = DateFormat('d MMM yyyy');

/// The gestational week [date] falls in, counted from the active LMP.
int? gestationalWeekOf(DateTime? date) {
  final lmp = PregnancyController.instance.lmpDate;
  if (date == null || lmp == null) return null;
  final week = date.difference(lmp).inDays ~/ 7;
  return week.clamp(1, 42);
}

/// "Week 16 – 20" for a window, "Week 24" for a single date, null without an
/// LMP to count from.
String? careWeekLabel(DateTime? from, DateTime? to) {
  final start = gestationalWeekOf(from);
  if (start == null) return null;
  final end = gestationalWeekOf(to);
  if (end == null || end <= start) return 'Week $start';
  return 'Week $start – $end';
}

/// Where an item sits in the list, which decides its marker.
enum CareMarker { done, next, later, missed }

/// The round marker at the start of a row: a green tick, an orange clock for
/// the next thing to do, an empty ring for what is still ahead.
class CareMarkerIcon extends StatelessWidget {
  const CareMarkerIcon({super.key, required this.marker, this.size = 26});

  final CareMarker marker;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color? fill, IconData? icon) = switch (marker) {
      CareMarker.done => (_careGreen, Icons.check_rounded),
      CareMarker.next => (_careOrange, Icons.schedule_rounded),
      CareMarker.missed => (_careRed, Icons.priority_high_rounded),
      CareMarker.later => (null, null),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill ?? p.card,
        border: fill == null
            ? Border.all(
                color: p.pick(const Color(0xFFD1D5DB), p.border),
                width: 1.6,
              )
            : null,
      ),
      child: icon == null
          ? null
          : Icon(icon, size: size * 0.62, color: Colors.white),
    );
  }
}

/// A small uppercase heading between groups: "COMPLETED", "FIRST TRIMESTER".
class CareSectionLabel extends StatelessWidget {
  const CareSectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color ?? context.palette.textMuted,
        ),
      ),
    );
  }
}

/// The white rounded card every item sits on. [highlighted] gives the next
/// thing to do its pink outline.
class CareCard extends StatelessWidget {
  const CareCard({
    super.key,
    required this.child,
    this.onTap,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool highlighted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? _carePink.withValues(alpha: p.isDark ? 0.55 : 0.35)
              : p.pick(const Color(0xFFF0F1F5), p.border),
          width: highlighted ? 1.4 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: p.pick(const Color(0x0A000000), p.shadow),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The pink outlined pill: "View details", "View", "Upload".
class CareOutlineButton extends StatelessWidget {
  const CareOutlineButton({
    super.key,
    required this.label,
    this.onTap,
    this.radius = 20,
  });

  final String label;
  final VoidCallback? onTap;

  /// 20 for the round "View details" pill, 8 for the squarer row buttons.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _carePink.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _carePink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A status pill with its own wording: ANC rows say "Upcoming" where the
/// status is only "Scheduled".
class CarePill extends StatelessWidget {
  const CarePill({super.key, required this.status, this.label});

  final CareStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.tint(status.color, status.background),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label ?? status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}

/// "2 of 4 Completed", with a green bar and a tick that fills once all are done.
class CareProgressCard extends StatelessWidget {
  const CareProgressCard({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = total == 0 ? 0.0 : done / total;
    final complete = total > 0 && done >= total;

    return CareCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done of $total Completed',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: p.pick(const Color(0xFFF0F2F5), p.surface),
                    valueColor: const AlwaysStoppedAnimation<Color>(_careGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: complete
                  ? _careGreen
                  : p.tint(_careGreen, const Color(0xFFE7F8F0)),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 24,
              color: complete ? Colors.white : _careGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal filter chips: "All", "1st Trimester", ...
class CareFilterChips extends StatelessWidget {
  const CareFilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
              child: Material(
                color: i == selected ? _carePink : p.card,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: i == selected
                            ? _carePink
                            : p.pick(const Color(0xFFE5E7EB), p.border),
                        width: 1.1,
                      ),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: i == selected ? Colors.white : p.textPrimary,
                      ),
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

/// One stop on a vertical timeline: the marker on a rail, the card beside it.
class CareTimelineTile extends StatelessWidget {
  const CareTimelineTile({
    super.key,
    required this.marker,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
  });

  final CareMarker marker;
  final Widget child;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final line = context.palette.pick(
      const Color(0xFFE5E7EB),
      context.palette.border,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : line,
                ),
                CareMarkerIcon(marker: marker, size: 18),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// The note at the foot of a list, e.g. how to upload a report not listed.
class CareFooterNote extends StatelessWidget {
  const CareFooterNote({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = _carePink,
    this.lightBackground,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;

  /// A pastel wash for the whole note; without one it sits on a plain card.
  final Color? lightBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final washed = lightBackground != null;
    return Material(
      color: washed ? p.tint(accent, lightBackground) : p.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: washed
                  ? accent.withValues(alpha: 0.18)
                  : p.pick(const Color(0xFFF0F1F5), p.border),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: washed
                      ? p.card
                      : p.tint(accent, const Color(0xFFFFF0F4)),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chevron that ends a tappable row.
class CareChevron extends StatelessWidget {
  const CareChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right_rounded,
    size: 22,
    color: context.palette.textMuted,
  );
}

/// One line of facts in the details sheet.
typedef CareFact = (IconData icon, String text);

/// The details of one item and what she can do about it.
///
/// The row itself stays quiet; the actions live here, so a list of fifteen
/// tests is not fifteen buttons. The sheet closes before an action runs, so
/// the list underneath reloads in view.
Future<void> showCareDetailSheet(
  BuildContext context, {
  required String title,
  String? eyebrow,
  required CareStatus status,
  String? statusLabel,
  List<CareFact> facts = const [],
  required String primaryLabel,
  IconData? primaryIcon,
  required VoidCallback onPrimary,
  bool primaryEnabled = true,
  bool primaryQuiet = false,
  String? disabledNote,
  String? secondaryLabel,
  IconData? secondaryIcon,
  VoidCallback? onSecondary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final p = ctx.palette;

      Widget button({
        required String label,
        IconData? icon,
        required VoidCallback? onTap,
        required bool quiet,
      }) {
        final action = onTap == null
            ? null
            : () {
                Navigator.pop(ctx);
                onTap();
              };
        final child = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        );
        final shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        );
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: quiet
              ? OutlinedButton(
                  onPressed: action,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _carePink,
                    side: BorderSide(color: _carePink.withValues(alpha: 0.55)),
                    shape: shape,
                  ),
                  child: child,
                )
              : ElevatedButton(
                  onPressed: action,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _carePink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: p.surface,
                    disabledForegroundColor: p.textMuted,
                    elevation: 0,
                    shape: shape,
                  ),
                  child: child,
                ),
        );
      }

      return Container(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          24 + MediaQuery.of(ctx).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (eyebrow != null)
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.textMuted,
                ),
              ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CarePill(status: status, label: statusLabel),
              ],
            ),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final (icon, text) in facts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: _carePink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            button(
              label: primaryLabel,
              icon: primaryIcon,
              onTap: primaryEnabled ? onPrimary : null,
              quiet: primaryQuiet,
            ),
            if (!primaryEnabled && disabledNote != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  disabledNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              button(
                label: secondaryLabel,
                icon: secondaryIcon,
                onTap: onSecondary,
                quiet: true,
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Whether an item dated [date] can be marked done yet: today or earlier, or
/// undated. One dated next month is not something she can have attended, so
/// its action stays greyed rather than recording the wrong thing.
bool careIsDue(DateTime? date) {
  if (date == null) return true;
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  return !DateTime(date.year, date.month, date.day).isAfter(startOfToday);
}

/// How far off a date is, in the words the schedule tables use: "53 days ago",
/// "In 7 days", "Today". Null when there is no date to describe.
String? relativeDayLabel(DateTime? date, {DateTime? now}) {
  if (date == null) return null;
  final today = now ?? DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  final target = DateTime(date.year, date.month, date.day);
  final days = target.difference(startOfToday).inDays;

  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days == -1) return 'Yesterday';
  return days > 0 ? 'In $days days' : '${-days} days ago';
}
