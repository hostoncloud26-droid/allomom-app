import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_overview_section.dart';
import 'package:allomom/features/overview_section/vitals/vitals_overview_section.dart';

/// Home's snapshot of one day, after AlloConnect's overview: a "For Today" /
/// "For This Day" header card, then vitals and nutrition for [date].
///
/// The host drives [date] from a [DayDateSelector]; give this widget a
/// [GlobalKey] to use it as the sticky strip's scroll anchor.
class DayOverviewSection extends StatelessWidget {
  /// Day everything below reports on. Defaults to today when omitted.
  final DateTime? date;

  const DayOverviewSection({super.key, this.date});

  DateTime get _day => date ?? DateTime.now();

  bool get _isToday => DateUtils.isSameDay(_day, DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildForTodayCard(context),
          const SizedBox(height: 24),
          // No narration here: these two sections stay silent.
          VitalsOverviewSection(date: _day),
          const SizedBox(height: 24),
          NutritionOverviewSection(date: _day),
        ],
      ),
    );
  }

  Widget _buildForTodayCard(BuildContext context) {
    final isDark = context.palette.isDark;
    final primary = Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? context.palette.card : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isToday ? Icons.wb_sunny_rounded : Icons.history_rounded,
              size: 20,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isToday ? 'For Today' : 'For This Day',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, d MMMM').format(_day),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
