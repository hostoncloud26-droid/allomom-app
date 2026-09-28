import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_custom_activity.dart';
import 'package:allomom/features/overview_section/todays_care/care_day.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/planner/todays_plan_page.dart';
import 'package:allomom/controllers/main_controller.dart';

/// Today's care, scoped to the current part of the day.
///
/// The list is rebuilt from [careItemsFor] whenever the clock crosses into a
/// new [CareDayPart], so before 11 AM it asks about breakfast, the afternoon
/// asks about lunch and the evening about dinner. Completion is read back from
/// the vitals the rest of the app already writes (`breakfast`, `lunch`,
/// `dinner`, `snacks`, `water`, `drinks`) plus the `todocare` tick-offs, so
/// logging a meal in My Health also ticks it off here.
class TodocareSection extends StatefulWidget {
  const TodocareSection({
    super.key,
    this.allDayParts = false,
    this.compact = false,
  });

  /// Every window of the day, instead of only the one the clock is in.
  ///
  /// Home shows the current window — the three or four things she can act on
  /// right now. The checklist page (which the chatbot opens) shows the lot
  /// grouped by window, and reuses this widget so the sheets, the tick-off
  /// writes and the completion rules are the same ones, not a second copy.
  /// Home's header and "View more" open [TodaysPlanPage] instead.
  final bool allDayParts;

  /// Home's card: one plain row per item — its time, icon and name — with no
  /// timeline, description or add slots. Tapping a row still logs it.
  final bool compact;

  @override
  State<TodocareSection> createState() => _TodocareSectionState();
}

class _TodocareSectionState extends State<TodocareSection> {
  /// How often we re-check whether the day part changed under us.
  static const _slotWatchInterval = Duration(minutes: 1);

  CareDayPart _part = CareDayPart.at();

  /// Today's items and how far she has got with each.
  CareDay _day = CareDay.empty;

  List<CareItem> get _items => _day.items;
  Map<String, CareCustomActivity> get _customById => _day.customById;
  bool _isLoading = true;

  Timer? _slotTimer;

  /// `addVitalEntry` notifies listeners several times per write, and each
  /// notification would otherwise kick off a fresh round of queries. Coalesce
  /// them: run one refresh at a time and remember if another was asked for.
  bool _isRefreshing = false;
  bool _refreshQueued = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    HealthVitalsController.instance.addListener(_onVitalsChanged);
    _slotTimer = Timer.periodic(
      _slotWatchInterval,
      (_) => _checkSlotRollover(),
    );
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
    HealthVitalsController.instance.removeListener(_onVitalsChanged);
    super.dispose();
  }

  void _onVitalsChanged() {
    if (mounted) _refresh();
  }

  /// Rebuilds when the clock moves into a new window (e.g. the user leaves the
  /// app open through 11 AM and breakfast becomes the mid-morning snack).
  void _checkSlotRollover() {
    final current = CareDayPart.at();
    if (current != _part && mounted) _refresh();
  }

  // ─── LOADING ────────────────────────────────────────────────

  Future<void> _refresh() async {
    if (_isRefreshing) {
      _refreshQueued = true;
      return;
    }
    _isRefreshing = true;
    try {
      do {
        _refreshQueued = false;
        await _loadOnce();
      } while (_refreshQueued && mounted);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadOnce() async {
    final part = CareDayPart.at();
    final day = await CareDay.load(
      widget.allDayParts ? CareDayPart.values : <CareDayPart>[part],
    );
    if (!mounted) return;
    setState(() {
      _part = part;
      _day = day;
      _isLoading = false;
    });
  }

  static CareDayPart _partAtHour(int hour) => CareDay.partAtHour(hour);

  // ─── STATE OF AN ITEM ───────────────────────────────────────

  bool _isDone(CareItem item) => _day.isDone(item);

  int _countFor(CareItem item) => _day.countFor(item);

  String? _progressLabel(CareItem item) => _day.progressLabel(item);

  // ─── ACTIONS ────────────────────────────────────────────────

  Future<void> _onItemTap(CareItem item) async {
    await CareItemActions.run(
      context,
      item,
      _day,
      onTicked: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) await _refresh();
  }

  // ─── BUILD ──────────────────────────────────────────────────

  int get _doneCount => _items.where(_isDone).length;

  static final _hourFmt = DateFormat('hh:mm a');

  static String _hourLabel(int hour) =>
      _hourFmt.format(DateTime(2000, 1, 1, hour));

  /// The day as the timeline reads it: from 5 AM, when the morning window
  /// opens, round to 4 AM.
  static final List<int> _dayHours = [
    for (var i = 0; i < 24; i++) (5 + i) % 24,
  ];

  /// The hours the window the clock is in covers, for the home card.
  List<int> get _windowHours =>
      _dayHours.where((h) => _partAtHour(h) == _part).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final p = context.palette;
    final progress = _items.isEmpty ? 0.0 : _doneCount / _items.length;
    final name = MainController.instance.userName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.allDayParts ? null : _openPlanner,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.allDayParts
                            ? '${_part.greeting}, $name'
                            : "Today's care",
                        style: GoogleFonts.outfit(
                          fontSize: widget.allDayParts ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.allDayParts
                            ? 'Your day, hour by hour'
                            : '${_part.greeting}, $name · ${_part.headline}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (widget.allDayParts)
                _AddActivityButton(onTap: () => _addActivity())
              else
                _DayPartBadge(part: _part),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: p.pick(const Color(0xFFF0F2F5), p.surface),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$_doneCount/${_items.length}',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Home shows the hours of the window she is in; the checklist page
          // the whole day. Both leave empty hours open to add to.
          if (widget.compact)
            _buildCompactList()
          else
            _buildTimeline(widget.allDayParts ? _dayHours : _windowHours),

          if (!widget.allDayParts) ...[
            const SizedBox(height: 4),
            _buildViewMore(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(List<int> hours) {
    final byHour = <int, List<CareItem>>{};
    for (final item in _items) {
      final hour = _day.hourOf(item);
      byHour.putIfAbsent(hour, () => []).add(item);
    }
    final nowHour = DateTime.now().hour;

    return Column(
      children: [
        for (var i = 0; i < hours.length; i++)
          _TimelineRow(
            label: _hourLabel(hours[i]),
            isNow: hours[i] == nowHour,
            isFirst: i == 0,
            isLast: i == hours.length - 1,
            child: (byHour[hours[i]] ?? const []).isEmpty
                ? _EmptySlot(onTap: () => _addActivity(hour: hours[i]))
                : Column(
                    children: [
                      for (final item in byHour[hours[i]]!)
                        _buildTimelineCard(item),
                    ],
                  ),
          ),
      ],
    );
  }

  /// Home's plain list: the items in time order, each at its hour.
  Widget _buildCompactList() {
    int hourOf(CareItem item) => _day.hourOf(item);
    final items = [..._items]
      ..sort(
        (a, b) => _dayHours
            .indexOf(hourOf(a))
            .compareTo(_dayHours.indexOf(hourOf(b))),
      );
    final nowHour = DateTime.now().hour;
    return Column(
      children: [
        for (final item in items)
          _buildCompactRow(item, hourOf(item), hourOf(item) == nowHour),
      ],
    );
  }

  Widget _buildCompactRow(CareItem item, int hour, bool isNow) {
    final p = context.palette;
    final isDone = _isDone(item);
    return GestureDetector(
      onTap: () => _onItemTap(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : item.color.withValues(alpha: p.isDark ? 0.5 : 0.38),
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                _hourLabel(hour),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                  color: isNow ? primaryColor : p.textSecondary,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: p.tint(item.color, item.color.withValues(alpha: 0.12)),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDone ? p.textMuted : p.textPrimary,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: p.textMuted,
                ),
              ),
            ),
            if (isDone)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: Color(0xFF10B981),
              ),
          ],
        ),
      ),
    );
  }

  /// Opens the rest of today. Home only ever shows the window she is in, and
  /// the other windows were unreachable until this.
  /// Opens Today's Planner, the whole day on a timeline.
  Future<void> _openPlanner() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TodaysPlanPage()));
    // She may have logged something while she was in there.
    if (mounted) await _refresh();
  }

  Widget _buildViewMore() {
    return GestureDetector(
      onTap: _openPlanner,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule_rounded, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              "Open Today's Planner",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// One activity on the timeline: its icon in a soft circle, the name in
  /// capitals, what to do, and — for a count — how far through the day's goal
  /// she is.
  Widget _buildTimelineCard(CareItem item) {
    final p = context.palette;
    final isDone = _isDone(item);
    final progressLabel = _progressLabel(item);
    final isTickable = item.kind == CareActionKind.checkoff;
    final custom = _customById[item.id];
    final target = item.dailyTarget;
    final countProgress = item.kind == CareActionKind.count && target != null
        ? (_countFor(item) / target).clamp(0.0, 1.0)
        : null;

    return GestureDetector(
      onTap: () => _onItemTap(item),
      onLongPress: custom == null ? null : () => _confirmRemove(custom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? const Color(
                    0xFF10B981,
                  ).withValues(alpha: p.isDark ? 0.45 : 0.4)
                : item.color.withValues(alpha: p.isDark ? 0.5 : 0.38),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: p.pick(item.color.withValues(alpha: 0.08), p.shadow),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.tint(item.color, item.color.withValues(alpha: 0.12)),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: p.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: isDone ? p.textMuted : p.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  if (countProgress != null) ...[
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: countProgress,
                        minHeight: 4,
                        backgroundColor: p.pick(
                          const Color(0xFFEFF1F5),
                          p.surface,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
                      ),
                    ),
                  ],
                  if (progressLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      progressLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: item.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ItemTrailing(
              isDone: isDone,
              // Tick-offs get a checkbox; everything else opens a sheet or a
              // screen, so it gets an affordance that says "there's more".
              showChevron: !isTickable && !isDone,
              color: item.color,
            ),
          ],
        ),
      ),
    );
  }

  // ─── HER OWN ACTIVITIES ─────────────────────────────────────

  Future<void> _addActivity({int? hour}) async {
    await showAddCareActivity(context, hour: hour);
    await _refresh();
  }

  Future<void> _confirmRemove(CareCustomActivity activity) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Remove "${activity.title}"?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'It will no longer appear at ${_hourLabel(activity.hour)} each day.',
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep',
              style: TextStyle(color: ctx.palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: dangerRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (remove != true) return;
    await CareCustomActivityStore.remove(activity.id);
    await _refresh();
  }
}

/// One hour on the timeline: the time, a dot on the rail, and what is on.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.child,
    this.isNow = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final Widget child;

  /// The hour the clock is in — the time and the dot turn pink.
  final bool isNow;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rail = p.pick(const Color(0xFFD5D9E0), p.border);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                  color: isNow ? primaryColor : p.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 1.6,
                  height: 22,
                  color: isFirst ? Colors.transparent : rail,
                ),
                Container(
                  width: isNow ? 11 : 7,
                  height: isNow ? 11 : 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNow ? primaryColor : rail,
                    border: isNow
                        ? Border.all(
                            color: primaryColor.withValues(alpha: 0.25),
                            width: 3,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1.6,
                    color: isLast ? Colors.transparent : rail,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// An hour with nothing in it, open to add to.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.pick(
          const Color(0xFFF1F3F6),
          p.surface.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: p.pick(const Color(0xFFDDE1E7), p.border),
                width: 1.1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: p.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pink "Add activity" pill at the top of the full day.
class _AddActivityButton extends StatelessWidget {
  const _AddActivityButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primaryColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_rounded,
                size: 17,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'ADD ACTIVITY',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the add sheet hands back.
typedef _NewActivity = ({
  CareActivityType type,
  String title,
  String note,
  int hour,
});

/// Picks what to add, what to call it and when.
class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet({
    required this.hours,
    required this.initialHour,
    required this.hourLabel,
  });

  final List<int> hours;
  final int initialHour;
  final String Function(int) hourLabel;

  static Future<_NewActivity?> show(
    BuildContext context, {
    required List<int> hours,
    required int initialHour,
    required String Function(int) hourLabel,
  }) {
    return showModalBottomSheet<_NewActivity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddActivitySheet(
        hours: hours,
        initialHour: initialHour,
        hourLabel: hourLabel,
      ),
    );
  }

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  CareActivityType _type = CareActivityType.meal;
  late int _hour = widget.initialHour;
  final _title = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim().isEmpty ? _type.label : _title.text.trim();
    Navigator.pop<_NewActivity>(context, (
      type: _type,
      title: title,
      note: _note.text.trim(),
      hour: _hour,
    ));
  }

  InputDecoration _field(AppPalette p, String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: p.textMuted),
    filled: true,
    fillColor: p.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primaryColor, width: 1.4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              Text(
                'Add activity',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'It will show at this time every day.',
                style: GoogleFonts.poppins(fontSize: 12, color: p.textMuted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in CareActivityType.values)
                    ChoiceChip(
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                      avatar: Icon(
                        type.icon,
                        size: 16,
                        color: _type == type ? Colors.white : type.color,
                      ),
                      label: Text(type.label),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _type == type ? Colors.white : p.textPrimary,
                      ),
                      showCheckmark: false,
                      selectedColor: type.color,
                      backgroundColor: p.inputFill,
                      side: BorderSide(
                        color: _type == type ? type.color : p.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14, color: p.textPrimary),
                decoration: _field(p, 'Name, e.g. ${_type.label}'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14, color: p.textPrimary),
                decoration: _field(p, 'Note (optional)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _hour,
                dropdownColor: p.card,
                borderRadius: BorderRadius.circular(14),
                menuMaxHeight: 320,
                style: GoogleFonts.poppins(fontSize: 14, color: p.textPrimary),
                decoration: _field(p, 'Time').copyWith(
                  prefixIcon: const Icon(
                    Icons.schedule_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                items: [
                  for (final h in widget.hours)
                    DropdownMenuItem(
                      value: h,
                      child: Text(widget.hourLabel(h)),
                    ),
                ],
                onChanged: (h) {
                  if (h != null) setState(() => _hour = h);
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Add to my day',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One window of the day and what it asks for.
class _DayPartBadge extends StatelessWidget {
  const _DayPartBadge({required this.part});

  final CareDayPart part;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(part.icon, size: 14, color: primaryColor),
          const SizedBox(width: 5),
          Text(
            part.label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTrailing extends StatelessWidget {
  const _ItemTrailing({
    required this.isDone,
    required this.showChevron,
    required this.color,
  });

  final bool isDone;
  final bool showChevron;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (showChevron) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
        ),
        child: Icon(Icons.add_rounded, color: color, size: 18),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? const Color(0xFF10B981) : Colors.transparent,
        border: isDone
            ? null
            : Border.all(
                color: context.palette.pick(
                  const Color(0xFFD0D5DD),
                  context.palette.textMuted,
                ),
                width: 1.8,
              ),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}

/// Asks for one of her own activities (what, when, a note) and adds it to
/// every day's care at that hour. Returns whether one was added. Shared with
/// Today's Planner's Add Plan.
Future<bool> showAddCareActivity(BuildContext context, {int? hour}) async {
  final result = await _AddActivitySheet.show(
    context,
    hours: _TodocareSectionState._dayHours,
    initialHour: hour ?? DateTime.now().hour,
    hourLabel: _TodocareSectionState._hourLabel,
  );
  if (result == null || !context.mounted) return false;

  try {
    await CareCustomActivityStore.add(
      type: result.type,
      title: result.title,
      hour: result.hour,
      note: result.note,
    );
    HapticFeedback.mediumImpact();
    if (context.mounted) {
      CareItemActions.showLogged(
        context,
        '${result.title} added at ${_TodocareSectionState._hourLabel(result.hour)}',
      );
    }
    return true;
  } catch (e) {
    debugPrint('⚠️ [TodocareSection] Could not save activity: $e');
    if (context.mounted) {
      CareItemActions.showError(context, 'Could not add the activity');
    }
    return false;
  }
}
