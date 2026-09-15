import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:allomom/features/cycle_tracker/cycle_setup_sheet.dart';
import 'package:allomom/features/cycle_tracker/cycle_theme.dart';
import 'package:allomom/repositories/cycle_repository.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/cycle_predictor.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

/// Her cycle in full: where she is today, the dates that follow from it, what
/// helps in this phase, and every period she has logged.
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
  static final _historyFmt = DateFormat('d MMM yyyy');

  List<CycleHistory> _history = const [];
  int? _measuredCycleLength;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logged = await CycleRepository.instance.history();
    if (!mounted) return;
    setState(() {
      _history = logged;
      _measuredCycleLength = CycleRepository.cycleLengthFromHistory(logged);
      _isLoading = false;
    });
  }

  Future<void> _openSheet({required bool isFirstSetup}) async {
    final saved = await CycleSetupSheet.show(
      context,
      isFirstSetup: isFirstSetup,
    );
    if (saved && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionManager.instance;
    final prediction = session.cyclePrediction;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F8),
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
                  : prediction == null
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: CycleColors.accent,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          _buildPhaseCard(prediction),
                          const SizedBox(height: 14),
                          _buildKeyDates(prediction),
                          const SizedBox(height: 14),
                          _buildCalendar(prediction),
                          const SizedBox(height: 14),
                          _buildGuidance(prediction),
                          const SizedBox(height: 14),
                          _buildHistory(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: prediction == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openSheet(isFirstSetup: false),
              backgroundColor: CycleColors.accent,
              icon: const Icon(Icons.water_drop_rounded, color: Colors.white),
              label: Text(
                'Log period',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: CycleColors.ink,
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
                color: CycleColors.ink,
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
              decoration: const BoxDecoration(
                color: CycleColors.accentSoft,
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
              'Nothing tracked yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CycleColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us when your last period started and we will predict the '
              'next one, your fertile days and the phase you are in.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: CycleColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openSheet(isFirstSetup: true),
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
  Widget _buildPhaseCard(CyclePrediction p) {
    final phase = p.phase;
    final color = CycleColors.of(phase);
    final progress = (p.cycleDay / p.cycleLength).clamp(0.0, 1.0);

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
                  color: CycleColors.softOf(phase),
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
            percent: progress,
            animation: true,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: const Color(0xFFF1F3F7),
            progressColor: color,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DAY',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: CycleColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${p.cycleDay}',
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: CycleColors.ink,
                    height: 1.1,
                  ),
                ),
                Text(
                  'of ${p.cycleLength}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: CycleColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _headline(p),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: CycleColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            phase.summary,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: CycleColors.muted,
              height: 1.45,
            ),
          ),
          if (p.isStale) ...[
            const SizedBox(height: 12),
            _Note(
              icon: Icons.info_outline_rounded,
              color: CycleColors.overdue,
              background: CycleColors.overdueSoft,
              text:
                  'Your last log is over a cycle old, so this is an estimate. '
                  'Log your latest period to sharpen it.',
            ),
          ],
        ],
      ),
    );
  }

  String _headline(CyclePrediction p) {
    if (p.isLate) {
      return p.daysLate == 1
          ? 'Your period is 1 day late'
          : 'Your period is ${p.daysLate} days late';
    }
    final days = p.daysUntilNextPeriod;
    if (days == 0) return 'Your period is due today';
    return days == 1
        ? 'Your period is due tomorrow'
        : 'Your period is due in $days days';
  }

  // ─── KEY DATES ─────────────────────────────────────────────
  Widget _buildKeyDates(CyclePrediction p) {
    return Row(
      children: [
        Expanded(
          child: _DateTile(
            icon: Icons.water_drop_rounded,
            color: CycleColors.accent,
            background: CycleColors.accentSoft,
            label: 'Next period',
            value: _longFmt.format(p.nextPeriodStart),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DateTile(
            icon: Icons.brightness_7_rounded,
            color: CycleColors.fertile,
            background: CycleColors.fertileSoft,
            label: 'Ovulation',
            value: _longFmt.format(p.ovulationDate),
          ),
        ),
      ],
    );
  }

  // ─── THIS CYCLE, DAY BY DAY ────────────────────────────────
  Widget _buildCalendar(CyclePrediction p) {
    // One tile per day of the cycle she is in, so the bleed, the fertile
    // window and today all read off a single strip.
    final days = [
      for (var i = 0; i < p.cycleLength; i++)
        p.currentPeriodStart.add(Duration(days: i)),
    ];

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
            '${_shortFmt.format(p.currentPeriodStart)} – '
            '${_shortFmt.format(p.nextPeriodStart.subtract(const Duration(days: 1)))}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: CycleColors.muted,
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
              for (final day in days) _CalendarDay(day: day, prediction: p),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: const [
              _LegendDot(color: CycleColors.accent, label: 'Period'),
              _LegendDot(color: CycleColors.fertile, label: 'Fertile'),
              _LegendDot(color: CycleColors.follicular, label: 'Ovulation'),
              _LegendDot(color: CycleColors.ink, label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PHASE GUIDANCE ────────────────────────────────────────
  Widget _buildGuidance(CyclePrediction p) {
    final phase = p.phase;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.tips_and_updates_rounded,
            color: CycleColors.of(phase),
            text: 'CARE THIS WEEK',
          ),
          const SizedBox(height: 12),
          for (final tip in phase.dos)
            _GuidanceLine(
              icon: Icons.check_circle_rounded,
              color: CycleColors.follicular,
              text: tip,
            ),
          const SizedBox(height: 6),
          for (final tip in phase.donts)
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
                    color: CycleColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            Text(
              'Periods you log will be listed here, and after two of them we '
              'can measure your real cycle length.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: CycleColors.muted,
                height: 1.45,
              ),
            )
          else
            for (var i = 0; i < _history.length; i++) ...[
              if (i > 0) const Divider(height: 18, color: Color(0xFFF0F1F5)),
              _HistoryRow(
                entry: _history[i],
                // Gap to the period before it — null for the oldest entry,
                // which has nothing to measure against.
                gapDays: i + 1 < _history.length
                    ? _history[i].cycleStartDate
                          .difference(_history[i + 1].cycleStartDate)
                          .inDays
                    : null,
                format: _historyFmt,
              ),
            ],
        ],
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CycleColors.hairline, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: CycleColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({required this.day, required this.prediction});

  final DateTime day;
  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(day, prediction.today);
    final isPeriod = prediction.isPeriodDay(day);
    final isOvulation = _isSameDay(day, prediction.ovulationDate);
    final isFertile = prediction.isFertile(day);

    final (Color bg, Color fg) = switch (true) {
      _ when isPeriod => (CycleColors.accent, Colors.white),
      _ when isOvulation => (CycleColors.follicular, Colors.white),
      _ when isFertile => (CycleColors.fertileSoft, CycleColors.fertile),
      _ => (const Color(0xFFF7F8FA), CycleColors.muted),
    };

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        // Today is outlined rather than filled so it can sit on top of any
        // phase colour without hiding it.
        border: isToday
            ? Border.all(color: CycleColors.ink, width: 1.8)
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

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
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
            color: CycleColors.muted,
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
                color: const Color(0xFF4B5160),
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
                color: const Color(0xFF4B5160),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.gapDays,
    required this.format,
  });

  final CycleHistory entry;
  final int? gapDays;
  final DateFormat format;

  @override
  Widget build(BuildContext context) {
    final end = entry.cycleEndDate;
    final duration = end == null
        ? null
        : end.difference(entry.cycleStartDate).inDays + 1;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: CycleColors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: CycleColors.accent,
            size: 17,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                format.format(entry.cycleStartDate),
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: CycleColors.ink,
                ),
              ),
              Text(
                duration == null
                    ? 'Still ongoing'
                    : '$duration day${duration == 1 ? '' : 's'} long',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: CycleColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (gapDays != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$gapDays d cycle',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CycleColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}
