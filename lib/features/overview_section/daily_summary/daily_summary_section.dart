import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// General daily summary, shown instead of the pregnancy card once a
/// pregnancy is completed or deleted.
///
/// Everything here comes from today's locally recorded vitals, so it reads the
/// same numbers as My Health rather than a pregnancy timeline.
class DailySummarySection extends StatefulWidget {
  const DailySummarySection({super.key, this.showHeading = true});

  /// Set false when the caller already renders its own title row.
  final bool showHeading;

  @override
  State<DailySummarySection> createState() => _DailySummarySectionState();
}

class _DailySummarySectionState extends State<DailySummarySection> {
  static final _dayFmt = DateFormat('EEEE, d MMM');

  int _waterGlasses = 0;

  @override
  void initState() {
    super.initState();
    _loadWater();
    HealthVitalsController.instance.addListener(_loadWater);
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_loadWater);
    super.dispose();
  }

  /// Water is not on the controller, so it is summed straight from today's
  /// rows — the same increment convention Today's Care writes.
  Future<void> _loadWater() async {
    final userId = UserSessionManager.instance.userId;
    if (userId.isEmpty) return;
    try {
      final now = DateTime.now();
      final rows = await VitalsSqLiteService().getVitalsHistory(
        userId,
        'water',
        fromDate: DateTime(now.year, now.month, now.day),
      );
      var total = 0;
      for (final row in rows) {
        total += ((row['value'] as num?)?.toDouble() ?? 0).round();
      }
      if (mounted) setState(() => _waterGlasses = total < 0 ? 0 : total);
    } catch (e) {
      debugPrint('DailySummarySection: could not read water vitals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vitals = HealthVitalsController.instance;
    final session = UserSessionManager.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeading) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily summary',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              Text(
                _dayFmt.format(DateTime.now()),
                style: GoogleFonts.poppins(fontSize: 12, color: textLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Text(
          _summaryLine(session, vitals),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'TODAY SO FAR',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildVitalsRow(vitals),
      ],
    );
  }

  /// One friendly sentence built from whatever was actually recorded today.
  String _summaryLine(UserSessionManager session, HealthVitalsController v) {
    final name = session.userName.split(' ').first;

    if (session.isNewMom) {
      final days = session.daysSinceDelivery;
      final since = days == null
          ? 'Recovery time'
          : days == 0
          ? 'Baby arrived today'
          : 'Day $days after delivery';
      return '$since, $name. Rest, eat well and keep your own check-ups going '
          '— your recovery matters as much as the baby.';
    }

    final logged = <String>[
      if (v.hasSteps) '${_formatSteps(v.stepsValue)} steps',
      if (v.hasSleep) '${v.sleepHoursValue.toStringAsFixed(1)}h sleep',
      if (_waterGlasses > 0) '$_waterGlasses glasses of water',
    ];

    if (logged.isEmpty) {
      return "Nothing logged yet today, $name. Add a meal, a glass of water or "
          'a vital to start your summary.';
    }
    if (logged.length == 1) {
      return "You've logged ${logged.first} today, $name. Keep going.";
    }
    final last = logged.removeLast();
    return "You've logged ${logged.join(', ')} and $last today, $name. "
        'Nice work.';
  }

  static String _formatSteps(int steps) =>
      steps >= 1000 ? NumberFormat.decimalPattern().format(steps) : '$steps';

  Widget _buildVitalsRow(HealthVitalsController v) {
    final tiles = <_SummaryTile>[
      _SummaryTile(
        icon: Icons.directions_walk_rounded,
        value: v.hasSteps ? _formatSteps(v.stepsValue) : '--',
        label: 'Steps',
        color: primaryColor,
      ),
      _SummaryTile(
        icon: Icons.nightlight_round,
        value: v.hasSleep ? '${v.sleepHoursValue.toStringAsFixed(1)}h' : '--',
        label: 'Sleep',
        color: const Color(0xff6C63FF),
      ),
      _SummaryTile(
        icon: Icons.favorite_rounded,
        value: v.hasHeartRate ? '${v.heartRateValue} bpm' : '--',
        label: 'Heart rate',
        color: primaryColor,
      ),
      _SummaryTile(
        icon: Icons.water_drop_rounded,
        value: _waterGlasses > 0 ? '$_waterGlasses' : '--',
        label: 'Glasses',
        color: infoCyan,
      ),
    ];

    return Row(
      children: [
        for (final tile in tiles)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: tile.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(tile.icon, color: tile.color, size: 18),
                  const SizedBox(height: 6),
                  Text(
                    tile.value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: tile.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tile.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 10, color: textLight),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryTile {
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
}
