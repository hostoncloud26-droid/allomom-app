import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:allomom/features/cycle_tracker/cycle_setup_sheet.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/cycle_tracker/cycle_theme.dart';
import 'package:allomom/repositories/cycle_repository.dart';
import 'package:allomom/controllers/vitals_controller.dart';
import 'package:allomom/services/cycle_predictor.dart';
import 'package:allomom/services/menstrual_tracker.dart';

/// Her cycle in full, tracked the way AlloConnect's menstruation tracker does:
/// where she is today, the dates that follow from it, day-by-day care, and
/// every period she has logged — with "log period start", "mark period ended"
/// and "edit" all writing to the `lmp_date` vitals the two apps share.
///
/// Only reached when she is not pregnant — a pregnancy replaces the whole
/// prediction with a due date, and the home card links to the journey instead.
class CycleTrackerPage extends StatefulWidget {
  const CycleTrackerPage({super.key});

  @override
  State<CycleTrackerPage> createState() => _CycleTrackerPageState();
}

class _CycleTrackerPageState extends State<CycleTrackerPage> {
  static final _longFmt = DateFormat('EEE, d MMM');
  static final _shortFmt = DateFormat('d MMM');

  List<PeriodLog> _history = const [];
  int? _measuredCycleLength;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool fromDisk = false}) async {
    if (fromDisk) await VitalsController.instance.loadFromLocal();
    final repo = CycleRepository.instance;
    final logged = repo.history();
    if (!mounted) return;
    setState(() {
      _history = logged;
      _measuredCycleLength = repo.measuredCycleLength();
      _isLoading = false;
    });
  }

  // ─── ACTIONS ───────────────────────────────────────────────

  Future<void> _openSetup() async {
    if (await CycleSetupSheet.show(context) && mounted) await _load();
  }

  Future<void> _edit(PeriodLog log) async {
    if (await CycleSetupSheet.edit(context, log) && mounted) {
      await _load();
      _toast('Period updated');
    }
  }

  /// A new period that has just started — a date, nothing more.
  Future<void> _logPeriodStart() async {
    final today = dateOnly(DateTime.now());
    final picked = await _pickDate(
      help: 'When did your period start?',
      initial: today,
      first: today.subtract(const Duration(days: 90)),
      last: today,
    );
    if (picked == null) return;
    await _run(
      () => CycleRepository.instance.logPeriodStart(picked),
      done: 'Period logged',
    );
  }

  Future<void> _markPeriodEnded(PeriodLog log) async {
    final today = dateOnly(DateTime.now());
    final picked = await _pickDate(
      help: 'When did your period end?',
      initial: today.isBefore(log.start) ? log.start : today,
      first: log.start,
      last: today.isBefore(log.start) ? log.start : today,
    );
    if (picked == null) return;
    await _run(
      () => CycleRepository.instance.markPeriodEnded(log, picked),
      done: 'Period marked as ended',
    );
  }

  Future<void> _run(
    Future<void> Function() write, {
    required String done,
  }) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await write();
      await _load();
      _toast(done);
    } catch (_) {
      _toast('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<DateTime?> _pickDate({
    required String help,
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) {
    return showDatePicker(
      context: context,
      helpText: help,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: context.palette.isDark
              ? ColorScheme.dark(
                  primary: CycleColors.accent,
                  onPrimary: Colors.white,
                  surface: context.palette.card,
                  onSurface: context.palette.textPrimary,
                )
              : ColorScheme.light(
                  primary: CycleColors.accent,
                  onPrimary: Colors.white,
                  onSurface: CycleColors.inkOn(context),
                ),
        ),
        child: child!,
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _history.isEmpty
        ? null
        : MenstrualStatus.from(_history.first);

    return Scaffold(
      backgroundColor: context.palette.pick(
        const Color(0xFFFAF7F8),
        context.palette.scaffoldSoft,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: CycleColors.accent,
                      ),
                    )
                  : status == null
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: CycleColors.accent,
                      onRefresh: () => _load(fromDisk: true),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          _buildPhaseCard(status),
                          const SizedBox(height: 14),
                          // Next period and ovulation are predicted from a
                          // finished period, so they wait until she marks
                          // this one ended.
                          if (!status.onPeriod) ...[
                            _buildKeyDates(status),
                            const SizedBox(height: 14),
                          ],
                          _buildCalendar(status),
                          const SizedBox(height: 14),
                          _buildGuidance(status.guidance),
                          const SizedBox(height: 14),
                          _buildHistory(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.palette.card,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.palette.pick(
                      Colors.black12,
                      context.palette.shadow,
                    ),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: CycleColors.inkOn(context),
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'My Cycle',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: CycleColors.inkOn(context),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ─── NOTHING LOGGED YET ────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CycleColors.softOn(
                  context,
                  CycleColors.accent,
                  CycleColors.accentSoft,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: CycleColors.accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No tracking data yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CycleColors.inkOn(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us when your last period started and we will predict the '
              'next one, your fertile days and the phase you are in.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: CycleColors.mutedOn(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CycleColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Start tracking',
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PHASE RING ────────────────────────────────────────────
  Widget _buildPhaseCard(MenstrualStatus s) {
    final phase = s.phase;
    final color = CycleColors.of(phase);
    final onPeriod = s.onPeriod;

    return _Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CycleColors.phaseSoftOn(context, phase),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CycleColors.iconOf(phase), color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      phase.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CircularPercentIndicator(
            radius: 82,
            lineWidth: 12,
            percent: s.progress,
            animation: true,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: context.palette.pick(
              const Color(0xFFF1F3F7),
              context.palette.surface,
            ),
            progressColor: color,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  onPeriod ? 'PERIOD DAY' : 'CYCLE DAY',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: onPeriod
                        ? CycleColors.accent
                        : CycleColors.mutedOn(context),
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${s.cycleDay}',
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: CycleColors.inkOn(context),
                    height: 1.1,
                  ),
                ),
                Text(
                  'of ${s.averageCycle}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: CycleColors.mutedOn(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: onPeriod ? CycleColors.accent : CycleColors.inkOn(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            phase.summary,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: CycleColors.mutedOn(context),
              height: 1.45,
            ),
          ),
          if (s.isStale) ...[
            const SizedBox(height: 12),
            _Note(
              icon: Icons.info_outline_rounded,
              color: CycleColors.overdue,
              background: CycleColors.softOn(
                context,
                CycleColors.overdue,
                CycleColors.overdueSoft,
              ),
              text:
                  'Your last log is over a cycle old. If your period has '
                  'come since, log it to keep your predictions right.',
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.water_drop_rounded,
                  color: CycleColors.accent,
                  value: _shortFmt.format(s.lastPeriod),
                  label: 'Last period',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: CycleColors.hairlineOn(context),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.timelapse_rounded,
                  color: CycleColors.fertile,
                  value: '${s.averageCycle} days',
                  label: 'Avg cycle',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PeriodActionButton(
            onPeriod: onPeriod,
            busy: _isSaving,
            onPressed: onPeriod
                ? () => _markPeriodEnded(s.latest)
                : _logPeriodStart,
          ),
        ],
      ),
    );
  }

  // ─── KEY DATES ─────────────────────────────────────────────
  Widget _buildKeyDates(MenstrualStatus s) {
    return Row(
      children: [
        Expanded(
          child: _DateTile(
            icon: Icons.water_drop_rounded,
            color: CycleColors.accent,
            background: CycleColors.softOn(
              context,
              CycleColors.accent,
              CycleColors.accentSoft,
            ),
            label: 'Next period',
            value: _longFmt.format(s.nextPeriod),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DateTile(
            icon: Icons.brightness_7_rounded,
            color: CycleColors.fertile,
            background: CycleColors.softOn(
              context,
              CycleColors.fertile,
              CycleColors.fertileSoft,
            ),
            label: 'Ovulation',
            value: _longFmt.format(s.ovulationDate),
          ),
        ),
      ],
    );
  }

  // ─── THIS CYCLE, DAY BY DAY ────────────────────────────────
  Widget _buildCalendar(MenstrualStatus s) {
    // One tile per day since the logged period started, so the bleed, the
    // fertile window and today all read off a single strip.
    final days = s.calendarDays;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.calendar_month_rounded,
            color: CycleColors.accent,
            text: 'THIS CYCLE',
          ),
          const SizedBox(height: 4),
          Text(
            '${_shortFmt.format(days.first)} – ${_shortFmt.format(days.last)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: CycleColors.mutedOn(context),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: [
              for (final day in days) _CalendarDay(day: day, status: s),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _LegendDot(color: CycleColors.accent, label: 'Period'),
              _LegendDot(color: CycleColors.fertile, label: 'Fertile'),
              _LegendDot(color: CycleColors.follicular, label: 'Ovulation'),
              _LegendDot(color: CycleColors.inkOn(context), label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DAY-BY-DAY GUIDANCE ───────────────────────────────────
  Widget _buildGuidance(CycleGuidance g) {
    final color = CycleColors.of(g.phase);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.tips_and_updates_rounded,
            color: color,
            text: g.title.toUpperCase(),
          ),
          const SizedBox(height: 10),
          Text(
            g.label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CycleColors.inkOn(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            g.tip,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: CycleColors.mutedOn(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _GuidanceHeading(text: 'What to do', color: CycleColors.follicular),
          const SizedBox(height: 8),
          for (final tip in g.dos)
            _GuidanceLine(
              icon: Icons.check_circle_rounded,
              color: CycleColors.follicular,
              text: tip,
            ),
          const SizedBox(height: 8),
          _GuidanceHeading(text: 'What to avoid', color: CycleColors.accent),
          const SizedBox(height: 8),
          for (final tip in g.donts)
            _GuidanceLine(
              icon: Icons.remove_circle_rounded,
              color: CycleColors.accent,
              text: tip,
            ),
        ],
      ),
    );
  }

  // ─── LOGGED PERIODS ────────────────────────────────────────
  Widget _buildHistory() {
    final today = dateOnly(DateTime.now());
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CardTitle(
                  icon: Icons.history_rounded,
                  color: CycleColors.luteal,
                  text: 'PERIOD HISTORY',
                ),
              ),
              if (_measuredCycleLength != null)
                Text(
                  'Avg $_measuredCycleLength days',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: CycleColors.mutedOn(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _history.length; i++) ...[
            if (i > 0)
              Divider(height: 22, color: CycleColors.hairlineOn(context)),
            _HistoryRow(
              entry: _history[i],
              today: today,
              onEdit: () => _edit(_history[i]),
            ),
          ],
          if (_history.length < 2) ...[
            const SizedBox(height: 12),
            Text(
              'Log each period as it starts — after two of them we can '
              'measure your real cycle length.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: CycleColors.mutedOn(context),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── CYCLE-SPECIFIC PIECES ───────────────────────────────────

/// "Log period start" when she is not bleeding, "Mark period ended" while
/// she is — the one action AlloConnect's overview offers.
class _PeriodActionButton extends StatelessWidget {
  const _PeriodActionButton({
    required this.onPeriod,
    required this.busy,
    required this.onPressed,
  });

  final bool onPeriod;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPeriod ? CycleColors.overdue : CycleColors.accent;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    onPeriod
                        ? Icons.check_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    onPeriod ? 'Mark period ended' : 'Log period start',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: CycleColors.inkOn(context),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: CycleColors.mutedOn(context),
          ),
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({required this.day, required this.status});

  final DateTime day;
  final MenstrualStatus status;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day, status.today);
    final isPeriod = status.isPeriodDay(day);
    final isOvulation = status.isOvulation(day);
    final isFertile = status.isFertile(day);

    final (Color bg, Color fg) = switch (true) {
      _ when isPeriod => (CycleColors.accent, Colors.white),
      _ when isOvulation => (CycleColors.follicular, Colors.white),
      _ when isFertile => (
        CycleColors.softOn(
          context,
          CycleColors.fertile,
          CycleColors.fertileSoft,
        ),
        CycleColors.fertile,
      ),
      _ => (
        context.palette.pick(const Color(0xFFF7F8FA), context.palette.surface),
        CycleColors.mutedOn(context),
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        // Today is outlined rather than filled so it can sit on top of any
        // phase colour without hiding it.
        border: isToday
            ? Border.all(color: CycleColors.inkOn(context), width: 1.8)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _GuidanceHeading extends StatelessWidget {
  const _GuidanceHeading({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// One logged period: start → end (or "Not completed" while ongoing), its
/// length, its status and an edit button — AlloConnect's history card.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.today,
    required this.onEdit,
  });

  static final _dayFmt = DateFormat('d MMM');
  static final _yearFmt = DateFormat('yyyy');

  final PeriodLog entry;
  final DateTime today;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ongoing = entry.isOngoing;
    final end = entry.displayEnd;
    final days = entry.daysSoFar(today);
    final muted = CycleColors.mutedOn(context);

    return Column(
      children: [
        Row(
          children: [
            _TimelineDate(
              label: 'Start',
              color: CycleColors.accent,
              day: _dayFmt.format(entry.start),
              year: _yearFmt.format(entry.start),
            ),
            const Spacer(),
            Column(
              children: [
                Icon(
                  ongoing
                      ? Icons.more_horiz_rounded
                      : Icons.arrow_forward_rounded,
                  size: 16,
                  color: ongoing
                      ? CycleColors.accent.withValues(alpha: 0.6)
                      : muted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ongoing
                        ? CycleColors.softOn(
                            context,
                            CycleColors.overdue,
                            CycleColors.overdueSoft,
                          )
                        : CycleColors.softOn(
                            context,
                            CycleColors.accent,
                            CycleColors.accentSoft,
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ongoing ? 'Day $days' : '$days day${days == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ongoing ? CycleColors.overdue : CycleColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ongoing || end == null
                ? _NotCompleted()
                : _TimelineDate(
                    label: 'End',
                    color: CycleColors.overdue,
                    day: _dayFmt.format(end),
                    year: _yearFmt.format(end),
                  ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (ongoing)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: CycleColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                ongoing
                    ? 'Ongoing'
                    : entry.isStored
                    ? 'Completed'
                    : 'From your profile',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ongoing ? CycleColors.accent : muted,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                'Edit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: CycleColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineDate extends StatelessWidget {
  const _TimelineDate({
    required this.label,
    required this.color,
    required this.day,
    required this.year,
  });

  final String label;
  final Color color;
  final String day;
  final String year;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          day,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: CycleColors.inkOn(context),
          ),
        ),
        Text(
          year,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: CycleColors.mutedOn(context),
          ),
        ),
      ],
    );
  }
}

class _NotCompleted extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: CycleColors.overdue,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CycleColors.softOn(
              context,
              CycleColors.overdue,
              CycleColors.overdueSoft,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_bottom_rounded,
                size: 14,
                color: CycleColors.overdue,
              ),
              const SizedBox(width: 4),
              Text(
                'Not completed',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: CycleColors.overdue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SMALL PIECES ────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CycleColors.hairlineOn(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.palette.pick(
              Colors.black.withValues(alpha: 0.03),
              context.palette.shadow,
            ),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: CycleColors.inkOn(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: CycleColors.mutedOn(context),
          ),
        ),
      ],
    );
  }
}

class _GuidanceLine extends StatelessWidget {
  const _GuidanceLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: context.palette.pick(
                  const Color(0xFF4B5160),
                  context.palette.textSecondary,
                ),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.palette.pick(
                  const Color(0xFF4B5160),
                  context.palette.textSecondary,
                ),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
