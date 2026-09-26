import 'dart:async';

import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_custom_activity.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';

const _rose = Color(0xFFFF4E6A);
const _roseDeep = Color(0xFFFF3B5C);

/// The section card the Home carousel pages share — the same shell the Daily
/// Summary card has always used, so the pages read as one set.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: p.pick(const Color(0xFFF0F1F5), p.border),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: p.pick(Colors.black.withValues(alpha: 0.03), p.shadow),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _roseDeep, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _roseDeep,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// The wide soft button at the foot of a section card.
class _CardButton extends StatelessWidget {
  const _CardButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: p.tint(_rose, const Color(0xFFFFF0F4)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _rose, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: _rose, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── This week ───────────────────────────────────────────────────────────────

/// This week's message from the baby: what the week's AlloBot flow,
/// `pregnancy_week_<n>_info`, says (see [WeeklyBabyTalk]).
class PregnancyWeekCard extends StatefulWidget {
  const PregnancyWeekCard({
    super.key,
    required this.week,
    required this.trimester,
    required this.daysLeft,
    this.onOpenJourney,
  });

  /// Completed weeks, as `MainController.currentGestationalWeek` counts them.
  final int week;
  final String trimester;
  final int daysLeft;
  final VoidCallback? onOpenJourney;

  @override
  State<PregnancyWeekCard> createState() => _PregnancyWeekCardState();
}

class _PregnancyWeekCardState extends State<PregnancyWeekCard> {
  String? _message;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PregnancyWeekCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week != widget.week) _load();
  }

  Future<void> _load() async {
    // The week's AlloBot flow — Amma's line for her, Appa's for him, in her
    // language — the same words the baby speaks on the card above.
    final message = await WeeklyBabyTalk.message(
      WeeklyBabyTalk.pregnancyWeek(widget.week),
    );
    if (!mounted) return;
    setState(() {
      _message = message;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final week = WeeklyBabyTalk.pregnancyWeek(widget.week);

    return _SectionCard(
      icon: Icons.auto_awesome_rounded,
      label: 'THIS WEEK',
      trailing: Text(
        '${widget.daysLeft} days to go',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: p.textMuted,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Week $week',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.trimester,
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: !_loaded
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      _message ??
                          'Your baby is growing a little more every day.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: p.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          _CardButton(
            icon: Icons.favorite_rounded,
            label: 'My Pregnancy Journey',
            onTap: widget.onOpenJourney,
          ),
        ],
      ),
    );
  }
}

// ── Baby's week ─────────────────────────────────────────────────────────────

/// The pregnancy week card, carried on after the birth: the baby's week in the
/// 1000 days (41 is the birth week, then one more each week up to 142) and
/// that week's message from its AlloBot flow.
class BabyWeekCard extends StatefulWidget {
  const BabyWeekCard({
    super.key,
    required this.week,
    required this.birth,
    this.babyName,
    this.onOpenJourney,
  });

  /// 41–142, as [WeeklyBabyTalk.babyWeekOf] counts it.
  final int week;
  final DateTime birth;
  final String? babyName;
  final VoidCallback? onOpenJourney;

  @override
  State<BabyWeekCard> createState() => _BabyWeekCardState();
}

class _BabyWeekCardState extends State<BabyWeekCard> {
  String? _message;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BabyWeekCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week != widget.week) _load();
  }

  Future<void> _load() async {
    final message = await WeeklyBabyTalk.message(widget.week);
    if (!mounted) return;
    setState(() {
      _message = message;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final week = widget.week;
    final name = widget.babyName?.trim();
    final who = name == null || name.isEmpty ? 'Baby' : name;
    final progress =
        (week - WeeklyBabyTalk.birthWeek) /
        (WeeklyBabyTalk.lastWeek - WeeklyBabyTalk.birthWeek);

    return _SectionCard(
      icon: Icons.child_care_rounded,
      label: 'THIS WEEK',
      trailing: Text(
        '${WeeklyBabyTalk.lastWeek - week} weeks to 1000 days',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: p.textMuted,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            week == WeeklyBabyTalk.birthWeek
                ? 'Week $week · Birth week'
                : 'Week $week',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$who is ${WeeklyBabyTalk.ageLabel(widget.birth)}',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              color: _rose,
              backgroundColor: p.tint(_rose, const Color(0xFFFFF0F4)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: !_loaded
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      _message ??
                          '$who is learning something new every day. Feed, '
                              'cuddle and talk to your baby — it all helps them grow.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: p.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          _CardButton(
            icon: Icons.child_friendly_rounded,
            label: 'Baby Journey',
            onTap: widget.onOpenJourney,
          ),
        ],
      ),
    );
  }
}

// ── Right now ───────────────────────────────────────────────────────────────

/// What to do now, from Today's Care: the items of the window the clock is in,
/// in time order, with the one that is due next picked out.
///
/// Read-only — the logging, ticks and sheets all live in Today's Care, which
/// [onOpenCare] brings into view.
class RightNowCareCard extends StatefulWidget {
  const RightNowCareCard({super.key, this.onOpenCare, this.clock});

  final VoidCallback? onOpenCare;

  /// For tests: the time to plan for. Defaults to the real clock.
  final DateTime Function()? clock;

  /// How many items the card has room for; the rest are in Today's Care.
  static const maxItems = 3;

  @override
  State<RightNowCareCard> createState() => _RightNowCareCardState();
}

class _RightNowCareCardState extends State<RightNowCareCard> {
  Timer? _tick;
  List<CareCustomActivity> _customs = const [];

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _loadCustoms();
    // Moves on as the day does — breakfast becomes the mid-morning snack at
    // 11 without her having to leave and come back.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _loadCustoms() async {
    try {
      final customs = await CareCustomActivityStore.load();
      if (mounted) setState(() => _customs = customs);
    } catch (e) {
      debugPrint('RightNowCareCard: could not read her activities: $e');
    }
  }

  /// The window's items with their hours, earliest first — the same items and
  /// hours Today's Care puts on its timeline.
  List<({CareItem item, int hour})> _itemsFor(CareDayPart part) {
    final session = MainController.instance;
    final entries = <({CareItem item, int hour})>[
      for (final item in careItemsFor(
        part: part,
        isPregnant: session.isPregnant,
        pregnancyDay: session.currentPregnancyDay,
        babyAgeDays: WeeklyBabyTalk.babyAgeDays(),
      ))
        (item: item, hour: careHourFor(item.id, part)),
      for (final custom in _customs)
        if (CareDayPart.at(DateTime(2000, 1, 1, custom.hour)) == part)
          (item: custom.toCareItem(), hour: custom.hour),
    ];
    entries.sort((a, b) => _order(a.hour).compareTo(_order(b.hour)));
    return entries;
  }

  /// Late night wraps past midnight, so the small hours sort after 22:00.
  static int _order(int hour) => hour < 5 ? hour + 24 : hour;

  static String _hourLabel(int hour) {
    final h = hour % 24;
    final suffix = h < 12 ? 'AM' : 'PM';
    final twelve = h % 12 == 0 ? 12 : h % 12;
    return '$twelve $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = _now;
    final part = CareDayPart.at(now);
    final all = _itemsFor(part);

    // Due next: the first item whose hour has not passed, else the last one.
    final nowOrder = _order(now.hour);
    var nextIndex = all.indexWhere((e) => _order(e.hour) >= nowOrder);
    if (nextIndex < 0) nextIndex = all.isEmpty ? 0 : all.length - 1;

    // Start the list at what is due, so the card is about now rather than
    // what was due at 6 AM — but keep it full when the window is ending.
    final lastStart = all.length > RightNowCareCard.maxItems
        ? all.length - RightNowCareCard.maxItems
        : 0;
    final start = nextIndex > lastStart ? lastStart : nextIndex;
    final shown = all.skip(start).take(RightNowCareCard.maxItems).toList();
    final more = all.length - shown.length;

    return _SectionCard(
      icon: part.icon,
      label: 'RIGHT NOW · ${part.label.toUpperCase()}',
      trailing: Text(
        part.timeRange,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: p.textMuted,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            part.headline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            all.isEmpty
                ? 'Nothing planned for now — take a moment for yourself.'
                : 'What to do now, from Today’s Care.',
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    _NowRow(
                      item: shown[i].item,
                      time: _hourLabel(shown[i].hour),
                      isNext: start + i == nextIndex,
                    ),
                  if (more > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Text(
                          '+$more more in Today’s Care',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _CardButton(
            icon: Icons.checklist_rounded,
            label: 'Open Today’s Care',
            onTap: widget.onOpenCare,
          ),
        ],
      ),
    );
  }
}

class _NowRow extends StatelessWidget {
  const _NowRow({required this.item, required this.time, required this.isNext});

  final CareItem item;
  final String time;

  /// The item due next, which gets the highlight and a "Now" tag.
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isNext
            ? p.tint(item.color, item.color.withValues(alpha: 0.08))
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext
              ? item.color.withValues(alpha: 0.35)
              : p.pick(const Color(0xFFF0F1F5), p.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: p.tint(item.color, item.color.withValues(alpha: 0.12)),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                color: p.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isNext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'NOW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            )
          else
            Text(
              time,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: p.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
