import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';

import 'package:allomom/features/cycle_tracker/cycle_setup_sheet.dart';
import 'package:allomom/features/cycle_tracker/cycle_theme.dart';
import 'package:allomom/features/cycle_tracker/cycle_tracker_page.dart';
import 'package:allomom/services/cycle_predictor.dart';

/// The home carousel card for a mother who is not pregnant.
///
/// A pregnancy has forty weeks of milestones to show; without one there is
/// nothing to count down to, and the card used to be a standing invitation to
/// register. Her cycle is the thing that actually moves week to week, so it
/// takes the slot — with registering a pregnancy kept as a link underneath for
/// the day the answer changes.
class CycleSummaryCard extends StatelessWidget {
  const CycleSummaryCard({
    super.key,
    required this.prediction,
    required this.onRegisterPregnancy,
    required this.onChanged,
  });

  /// Null until she has told us when her last period started.
  final CyclePrediction? prediction;

  /// Opens pregnancy registration.
  final VoidCallback onRegisterPregnancy;

  /// Called after she logs or sets up a cycle, so home can rebuild.
  final VoidCallback onChanged;

  static final _shortFmt = DateFormat('d MMM');

  Future<void> _startTracking(BuildContext context) async {
    final saved = await CycleSetupSheet.show(context, isFirstSetup: true);
    if (saved) onChanged();
  }

  Future<void> _openTracker(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CycleTrackerPage()),
    );
    // She may have logged a period in there, so re-read on the way back.
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = prediction;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.palette.pick(
              const [Color(0xFFFFF0F4), Colors.white],
              [
                Color.alphaBlend(
                  CycleColors.accent.withValues(alpha: 0.14),
                  context.palette.card,
                ),
                context.palette.card,
              ],
            ),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: context.palette.pick(
              const Color(0xFFFFDCE4),
              context.palette.accentBorder,
            ),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CycleColors.accent.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // The carousel gives every card the same fixed height, and the
            // text inside this one grows with her system font scale. Scaling
            // the block down when it would not fit keeps the card whole
            // instead of overflowing it.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: p == null
                        ? _buildInvite(context)
                        : _buildTracking(context, p),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _PrimaryButton(
                  icon: p == null
                      ? Icons.add_circle_outline_rounded
                      : Icons.insights_rounded,
                  label: p == null ? 'Start Tracking' : 'View My Cycle',
                  onTap: () => p == null
                      ? _startTracking(context)
                      : _openTracker(context),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onRegisterPregnancy,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Expecting? Register your pregnancy →',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CycleColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── NOT TRACKING YET ──────────────────────────────────────
  Widget _buildInvite(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(icon: Icons.water_drop_rounded, text: 'MY CYCLE'),
        const SizedBox(height: 12),
        Text(
          'Track your monthly cycle',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: CycleColors.inkOn(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tell us when your last period started and we will predict what '
          'comes next.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: CycleColors.mutedOn(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _Pill(
              icon: Icons.water_drop_rounded,
              color: CycleColors.accent,
              background: CycleColors.accentSoft,
              label: 'Next period',
            ),
            _Pill(
              icon: Icons.favorite_rounded,
              color: CycleColors.fertile,
              background: CycleColors.fertileSoft,
              label: 'Fertile days',
            ),
            _Pill(
              icon: Icons.insights_rounded,
              color: CycleColors.luteal,
              background: CycleColors.lutealSoft,
              label: 'Phase insights',
            ),
          ],
        ),
      ],
    );
  }

  // ─── TRACKING ──────────────────────────────────────────────
  Widget _buildTracking(BuildContext context, CyclePrediction p) {
    final phase = p.phase;
    final color = CycleColors.of(phase);
    final progress = (p.cycleDay / p.cycleLength).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Flexible(
              child: _SectionHeader(
                icon: Icons.water_drop_rounded,
                text: 'MY CYCLE',
              ),
            ),
            const Spacer(),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CycleColors.phaseSoftOn(context, phase),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  phase.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Day ${p.cycleDay}',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: CycleColors.inkOn(context),
                height: 1.1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'of ${p.cycleLength}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: CycleColors.mutedOn(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _headline(p),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: CycleColors.mutedOn(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: context.palette.pick(
              const Color(0xFFF1F3F7),
              context.palette.surface,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 14),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              icon: Icons.water_drop_rounded,
              color: CycleColors.accent,
              background: CycleColors.accentSoft,
              label: 'Period ${_shortFmt.format(p.nextPeriodStart)}',
            ),
            _Pill(
              icon: Icons.favorite_rounded,
              color: CycleColors.fertile,
              background: CycleColors.fertileSoft,
              label: 'Fertile ${_shortFmt.format(p.fertileWindowStart)}',
            ),
          ],
        ),
      ],
    );
  }

  String _headline(CyclePrediction p) {
    if (p.isStale) {
      return 'It has been a while — log your last period to refresh this.';
    }
    if (p.isLate) {
      return p.daysLate == 1
          ? 'Your period is 1 day late.'
          : 'Your period is ${p.daysLate} days late.';
    }
    final days = p.daysUntilNextPeriod;
    if (days == 0) return 'Your period is due today.';
    return days == 1
        ? 'Your period is due tomorrow.'
        : 'Your period is due in $days days.';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: CycleColors.accent, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CycleColors.accent,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small labelled pill. Short enough that three fit on a phone-width row,
/// which is what keeps the card inside its carousel slot.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.color,
    required this.background,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: CycleColors.softOn(context, color, background),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: CycleColors.inkOn(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: CycleColors.accent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
