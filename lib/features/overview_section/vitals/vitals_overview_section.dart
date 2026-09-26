import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/features/my_health/vitals/steps/steps_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/heart_rate_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/stress/stress_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/blood_pressure_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_glucose/blood_glucose_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/hemoglobin/hemoglobin_summary_screen.dart';

/// "My Vitals" on Home: a full-width card per vital, except blood pressure and
/// glucose, which share a row whose widths shift towards whichever reading
/// needs attention.
///
/// Today reads [HealthVitalsController] directly so fresh entries land at
/// once; any other day reads what was recorded on it.
class VitalsOverviewSection extends StatefulWidget {
  /// Day the cards report on. Defaults to today when omitted.
  final DateTime? date;

  /// Latest vital per key as it stood on [date], as returned by
  /// [HealthVitalsController.fetchVitalsForDate]. Optional: when a past day is
  /// selected and this is null, the section loads the day itself.
  final Map<String, VitalsStreamResponse?>? dayVitals;

  const VitalsOverviewSection({super.key, this.date, this.dayVitals});

  bool get isToday =>
      date == null || DateUtils.isSameDay(date!, DateTime.now());

  @override
  State<VitalsOverviewSection> createState() => _VitalsOverviewSectionState();
}

class _VitalsOverviewSectionState extends State<VitalsOverviewSection> {
  final HealthVitalsController _controller = HealthVitalsController.instance;

  /// The selected past day's readings, loaded here when none were handed down.
  Map<String, VitalsStreamResponse?>? _loadedDay;

  /// Guards against an older load landing after a newer one.
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onVitalsChanged);
    _loadDayIfNeeded();
  }

  @override
  void didUpdateWidget(covariant VitalsOverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameDay = (oldWidget.date == null && widget.date == null) ||
        (oldWidget.date != null &&
            widget.date != null &&
            DateUtils.isSameDay(oldWidget.date!, widget.date!));
    if (!sameDay) {
      _loadedDay = null;
      _loadDayIfNeeded();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVitalsChanged);
    super.dispose();
  }

  void _onVitalsChanged() {
    if (!mounted) return;
    setState(() {});
    // A new entry may have been back-dated onto the day on screen.
    _loadDayIfNeeded();
  }

  Future<void> _loadDayIfNeeded() async {
    if (widget.isToday) return;
    final date = widget.date!;
    final token = ++_loadToken;

    final day = Map<String, VitalsStreamResponse?>.from(
      widget.dayVitals ?? await _controller.fetchVitalsForDate(date),
    );
    // Blood glucose is written under `glucose`, which the day snapshot does
    // not cover, so pick it up here.
    day['glucose'] = await _latestOnDay('glucose', date);

    if (!mounted || token != _loadToken) return;
    setState(() => _loadedDay = day);
  }

  Future<VitalsStreamResponse?> _latestOnDay(String key, DateTime date) async {
    final userId = _controller.userId.trim();
    if (userId.isEmpty) return null;
    try {
      final rows = await VitalsSqLiteService().getVitalsHistory(
        userId,
        key,
        fromDate: DateTime(date.year, date.month, date.day),
        toDate: DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
      );
      if (rows.isEmpty) return null;
      final parsed = rows.map(_vitalFromRow).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return parsed.first;
    } catch (e) {
      debugPrint('⚠️ [VitalsOverviewSection] Could not read "$key": $e');
      return null;
    }
  }

  VitalsStreamResponse _vitalFromRow(Map<String, dynamic> map) {
    final raw = map['data'];
    Map<String, dynamic>? data;
    if (raw is Map) {
      data = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Not JSON; nothing to read from it.
      }
    }
    final created = map['createdAt'];
    return VitalsStreamResponse(
      id: map['id']?.toString() ?? '',
      key: (map['vital_key'] ?? map['key'])?.toString() ?? '',
      value: map['value'] is num
          ? (map['value'] as num).toDouble()
          : double.tryParse(map['value']?.toString() ?? '') ?? 0,
      unit: map['unit']?.toString() ?? '',
      createdAt: created is DateTime
          ? created
          : DateTime.tryParse(created?.toString() ?? '') ?? DateTime.now(),
      data: data,
    );
  }

  // ─── DATA ───────────────────────────────────────────────────

  _VitalsSnapshot _snapshot() {
    final c = _controller;
    if (widget.isToday) {
      final glucose = c.vitals
          .where((v) {
            final k = v.key.toLowerCase();
            return k == 'glucose' || k == 'blood_glucose';
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return _VitalsSnapshot.from(
        steps: c.stepsVital,
        sleepHours: c.sleepHoursValue,
        heartRate: c.heartRateVital,
        bloodOxygen: c.bloodOxygenVital,
        stress: c.stressVital,
        bloodPressure: c.bloodPressureVital,
        glucose: glucose.isEmpty ? null : glucose.first,
        hemoglobin: c.hemoglobinVital,
      );
    }

    final day = _loadedDay ?? widget.dayVitals ?? const {};
    // Sleep may sit under either key; the newer one wins.
    final sleepCandidates = [day['sleep'], day['sleep_data']]
        .whereType<VitalsStreamResponse>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sleep = sleepCandidates.isEmpty ? null : sleepCandidates.first;
    final glucoseCandidates = [day['glucose'], day['blood_glucose']]
        .whereType<VitalsStreamResponse>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _VitalsSnapshot.from(
      steps: day['steps'],
      sleepHours: sleep == null ? 0 : _sleepHoursOf(sleep),
      heartRate: day['heart_rate'],
      bloodOxygen: day['blood_oxygen'],
      stress: day['stress'],
      bloodPressure: day['blood_pressure'],
      glucose: glucoseCandidates.isEmpty ? null : glucoseCandidates.first,
      hemoglobin: day['hemoglobin'],
    );
  }

  /// Sleep is stored in hours by Allomom's own log, in minutes by older rows.
  double _sleepHoursOf(VitalsStreamResponse v) {
    if (v.unit.toLowerCase().contains('min') || v.value > 24) {
      return v.value / 60.0;
    }
    return v.value;
  }

  // ─── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    final s = _snapshot();
    final stepTarget = _controller.currentStepTarget;

    // Blood pressure and glucose share a row; whichever needs attention gets
    // the wider card. Every other vital has a full-width card of its own.
    final isBpAlert = s.hasBloodPressure && s.bpStatus != 'Normal';
    final isGlucoseAlert = s.glucose > 0 && s.glucoseStatus != 'Normal';

    var bpFlex = 1;
    var glucoseFlex = 1;
    if (isBpAlert) {
      bpFlex = 2;
    } else if (isGlucoseAlert) {
      glucoseFlex = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            widget.isToday ? 'My Vitals' : 'Vitals',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1B1C1A),
              letterSpacing: -0.5,
            ),
          ),
        ),

        // One full-width card each.
        _buildStepsCard(
          steps: s.steps,
          target: stepTarget,
          isWide: true,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildHeartRateCard(
          heartRate: s.heartRate,
          isWide: true,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildSleepCard(
          sleepHours: s.sleepHours,
          isWide: true,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildStressCard(stress: s.stress, isWide: true, isDark: isDark),
        const SizedBox(height: 12),

        // Row 3: Oxygen Level (always full width)
        _buildOxygenCard(bloodOxygen: s.bloodOxygen, isDark: isDark),
        const SizedBox(height: 12),

        // Row 4: Blood Pressure & Blood Glucose
        _pair(
          leftFlex: bpFlex,
          left: _buildBloodPressureCard(
            s: s,
            isWide: bpFlex == 2,
            isDark: isDark,
          ),
          rightFlex: glucoseFlex,
          right: _buildGlucoseCard(
            s: s,
            isWide: glucoseFlex == 2,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 12),

        // Row 5: Hemoglobin (always full width)
        _buildHemoglobinCard(hemoglobin: s.hemoglobin, isDark: isDark),
      ],
    );
  }

  Widget _pair({
    required int leftFlex,
    required Widget left,
    required int rightFlex,
    required Widget right,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: leftFlex, child: left),
          const SizedBox(width: 12),
          Expanded(flex: rightFlex, child: right),
        ],
      ),
    );
  }

  // ─── STEPS ──────────────────────────────────────────────────

  Widget _buildStepsCard({
    required int steps,
    required int target,
    required bool isWide,
    required bool isDark,
  }) {
    final progress = target > 0 ? (steps / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();
    const color = Color(0xFF10B981); // Emerald Green

    if (!isWide) {
      return _compactCard(
        page: const StepsSummaryScreen(),
        icon: Icons.directions_walk_rounded,
        color: color,
        label: 'Steps',
        value: '$steps',
        chip: '$percent%',
        chipActive: true,
        isDark: isDark,
      );
    }

    var insight = widget.isToday
        ? "No steps logged today. Let's get moving!"
        : 'No steps were logged on this day.';
    if (steps > 0) {
      if (steps >= target) {
        insight = 'Outstanding! You surpassed your daily goal.';
      } else if (progress < 0.2) {
        insight = 'A quick 10-minute walk adds ~1,000 steps.';
      } else {
        insight = 'You need ${target - steps} more steps to hit your goal.';
      }
    }

    return _wideCard(
      page: const StepsSummaryScreen(),
      icon: Icons.directions_walk_rounded,
      color: color,
      title: 'Steps',
      badge: _badge('$percent%', color, color.withValues(alpha: 0.1)),
      value: '$steps',
      unit: '/ $target steps',
      progress: progress,
      insight: insight,
      insightMaxLines: 3,
      isDark: isDark,
    );
  }

  // ─── HEART RATE ─────────────────────────────────────────────

  Widget _buildHeartRateCard({
    required int heartRate,
    required bool isWide,
    required bool isDark,
  }) {
    const color = Color(0xFFF43F5E); // Rose
    final hasData = heartRate > 0;

    var statusText = 'No data';
    if (hasData) {
      if (heartRate < 60) {
        statusText = 'Resting Slow';
      } else if (heartRate <= 100) {
        statusText = 'Normal';
      } else {
        statusText = 'Elevated';
      }
    }

    if (!isWide) {
      return _compactCard(
        page: const HeartRateSummaryScreen(),
        icon: Icons.favorite_rounded,
        color: color,
        label: 'Heart Rate',
        value: hasData ? '$heartRate' : '--',
        unit: hasData ? 'bpm' : null,
        chip: statusText,
        chipActive: hasData,
        trailing:
            hasData ? const _PulsingHeartDot(color: Colors.redAccent) : null,
        isDark: isDark,
      );
    }

    final alertText = heartRate < 60
        ? 'Low resting pulse. Ensure you feel well and stay rested.'
        : 'Elevated pulse. Rest, relax, and take slow, calm breaths.';

    return _wideCard(
      page: const HeartRateSummaryScreen(),
      icon: Icons.favorite_rounded,
      color: color,
      title: 'Heart Alert',
      badge: _badge(
        statusText,
        Colors.red,
        Colors.red.withValues(alpha: 0.1),
        leading: const _PulsingHeartDot(color: Colors.redAccent),
      ),
      value: '$heartRate',
      valueExtras: [
        const SizedBox(width: 4),
        Text(
          'bpm',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(width: 6),
        _alertChip(heartRate >= 100 ? 'High' : 'Low'),
      ],
      insight: alertText,
      insightStrong: true,
      isDark: isDark,
    );
  }

  // ─── SLEEP ──────────────────────────────────────────────────

  Widget _buildSleepCard({
    required double sleepHours,
    required bool isWide,
    required bool isDark,
  }) {
    const color = Color(0xFF6366F1); // Indigo
    final hasData = sleepHours > 0;
    const sleepTarget = 8.0;
    final progress = hasData ? (sleepHours / sleepTarget).clamp(0.0, 1.0) : 0.0;
    final statusText =
        hasData ? (sleepHours >= 7 ? 'Optimal' : 'Short') : 'No data';

    if (!isWide) {
      return _compactCard(
        page: const SleepSummaryScreen(),
        icon: Icons.nights_stay_rounded,
        color: color,
        label: 'Sleep',
        value: hasData ? sleepHours.toStringAsFixed(1) : '--',
        unit: hasData ? 'hrs' : null,
        chip: statusText,
        chipActive: hasData,
        isDark: isDark,
      );
    }

    final deficit = (sleepTarget - sleepHours).toStringAsFixed(1);
    final String insight;
    final String title;
    final Color statusFg;
    final Color statusBg;

    if (!hasData) {
      insight = widget.isToday
          ? "No sleep logged yet. Add last night's sleep to see how well rested you are."
          : 'No sleep was logged for this day.';
      title = 'Sleep Tracking';
      statusFg = isDark ? Colors.white38 : Colors.black45;
      statusBg = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04);
    } else if (sleepHours >= sleepTarget) {
      insight =
          'Great job! You reached your sleep target of ${sleepTarget.toStringAsFixed(0)} hrs. Consistent sleep supports your immunity, mood and your baby\'s growth.';
      title = 'Sleep Target Met';
      statusFg = const Color(0xFF10B981);
      statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
    } else {
      insight =
          'Your sleep was short by $deficit hrs. Short sleep affects recovery, stress and mood. Try a dark, screen-free bedtime routine tonight.';
      title = 'Sleep Deficit';
      statusFg = Colors.amber.shade800;
      statusBg = Colors.amber.withValues(alpha: 0.12);
    }

    return _wideCard(
      page: const SleepSummaryScreen(),
      icon: Icons.nights_stay_rounded,
      color: color,
      title: title,
      badge: _badge(statusText, statusFg, statusBg),
      value: hasData ? sleepHours.toStringAsFixed(1) : '--',
      unit: '/ ${sleepTarget.toStringAsFixed(0)} hrs slept',
      progress: progress,
      insight: insight,
      insightMaxLines: 3,
      isDark: isDark,
    );
  }

  // ─── STRESS ─────────────────────────────────────────────────

  Widget _buildStressCard({
    required int stress,
    required bool isWide,
    required bool isDark,
  }) {
    const color = Color(0xFF8B5CF6); // Purple
    final hasData = stress > 0;
    final progress = hasData ? (stress / 100).clamp(0.0, 1.0) : 0.0;

    var statusText = 'No data';
    var insight = widget.isToday
        ? 'Log how stressed you feel to keep an eye on your wellbeing.'
        : 'No stress reading was logged on this day.';
    if (hasData) {
      if (stress <= 25) {
        statusText = 'Low Stress';
        insight = 'Relaxed state. Lovely for you and your baby.';
      } else if (stress <= 50) {
        statusText = 'Mild Stress';
        insight = 'Normal stress levels. Remember to keep hydrated.';
      } else {
        statusText = 'High Stress';
        insight = 'Elevated levels. Try a quick 2-minute breathing exercise.';
      }
    }

    if (!isWide) {
      return _compactCard(
        page: const StressSummaryScreen(),
        icon: Icons.psychology_rounded,
        color: color,
        label: 'Stress',
        value: hasData ? '$stress' : '--',
        unit: hasData ? '/100' : null,
        chip: hasData
            ? (stress <= 25 ? 'Low' : (stress <= 50 ? 'Med' : 'High'))
            : 'No data',
        chipActive: hasData,
        isDark: isDark,
      );
    }

    return _wideCard(
      page: const StressSummaryScreen(),
      icon: Icons.psychology_rounded,
      color: color,
      title: 'Stress Level',
      badge: _badge(
        statusText,
        hasData ? color : (isDark ? Colors.white30 : Colors.black38),
        hasData
            ? color.withValues(alpha: 0.1)
            : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03)),
        fontSize: 8,
      ),
      value: hasData ? '$stress' : '--',
      unit: hasData ? '/100' : null,
      unitGap: 2,
      progress: progress,
      insight: insight,
      isDark: isDark,
    );
  }

  // ─── OXYGEN ─────────────────────────────────────────────────

  Widget _buildOxygenCard({required int bloodOxygen, required bool isDark}) {
    const color = Color(0xFF0EA5E9); // Light Blue
    final hasData = bloodOxygen > 0;

    var insight =
        'Blood oxygen saturation (SpO2) measures how much oxygen your red blood cells are carrying. Normal healthy levels range between 95% and 100%.';
    if (hasData) {
      insight = bloodOxygen >= 95
          ? 'Your blood oxygen level of $bloodOxygen% is healthy. Your lungs are supplying plenty of oxygen to you and your baby.'
          : 'Your blood oxygen level of $bloodOxygen% is low. Rest somewhere well ventilated and contact your doctor if it persists.';
    }

    return _featureCard(
      page: const BloodOxygenSummaryScreen(),
      icon: Icons.opacity_rounded,
      color: color,
      title: 'Oxygen Level (SpO2)',
      status: hasData ? (bloodOxygen >= 95 ? 'Healthy' : 'Low') : 'No data',
      hasData: hasData,
      value: hasData ? '$bloodOxygen' : '--',
      unit: hasData ? '%' : null,
      insight: insight,
      isDark: isDark,
    );
  }

  // ─── BLOOD PRESSURE ─────────────────────────────────────────

  Widget _buildBloodPressureCard({
    required _VitalsSnapshot s,
    required bool isWide,
    required bool isDark,
  }) {
    const color = Color(0xFFEC4899); // Pink
    final hasData = s.hasBloodPressure;
    final value = hasData ? s.bpText : '--/--';

    if (!isWide) {
      return _compactCard(
        page: const BloodPressureSummaryScreen(),
        icon: Icons.monitor_heart_rounded,
        color: color,
        label: 'Blood Pressure',
        value: value,
        unit: hasData ? 'mmHg' : null,
        chip: hasData ? s.bpStatus : 'No data',
        chipActive: hasData,
        isDark: isDark,
      );
    }

    final high = s.bpStatus == 'High';
    return _wideCard(
      page: const BloodPressureSummaryScreen(),
      icon: Icons.monitor_heart_rounded,
      color: color,
      title: 'Blood Pressure',
      badge: _badge(
        s.bpStatus,
        high ? Colors.red : Colors.amber.shade800,
        (high ? Colors.red : Colors.amber).withValues(alpha: 0.12),
      ),
      value: value,
      unit: 'mmHg',
      insight: high
          ? 'Readings of 140/90 or above need attention in pregnancy. Rest, re-check in 15 minutes and call your doctor if it stays high.'
          : 'Slightly above the ideal 120/80. Cut back on salt, rest on your left side and keep checking.',
      isDark: isDark,
    );
  }

  // ─── BLOOD GLUCOSE ──────────────────────────────────────────

  Widget _buildGlucoseCard({
    required _VitalsSnapshot s,
    required bool isWide,
    required bool isDark,
  }) {
    const color = Color(0xFF8B5CF6); // Violet
    final hasData = s.glucose > 0;
    final value = hasData ? s.glucose.toStringAsFixed(0) : '--';

    if (!isWide) {
      return _compactCard(
        page: const BloodGlucoseSummaryScreen(),
        icon: Icons.water_drop_rounded,
        color: color,
        label: 'Blood Glucose',
        value: value,
        unit: hasData ? 'mg/dL' : null,
        chip: hasData ? s.glucoseStatus : 'No data',
        chipActive: hasData,
        isDark: isDark,
      );
    }

    final low = s.glucoseStatus == 'Low';
    return _wideCard(
      page: const BloodGlucoseSummaryScreen(),
      icon: Icons.water_drop_rounded,
      color: color,
      title: 'Blood Glucose',
      badge: _badge(
        s.glucoseStatus,
        low ? Colors.amber.shade800 : Colors.red,
        (low ? Colors.amber : Colors.red).withValues(alpha: 0.12),
      ),
      value: value,
      unit: 'mg/dL · ${s.glucosePhaseLabel}',
      insight: low
          ? 'Your sugar is low. Have a small snack or juice now and re-check in 15 minutes.'
          : 'Your sugar is above the pregnancy target. Share this reading with your doctor at your next visit.',
      isDark: isDark,
    );
  }

  // ─── HEMOGLOBIN ─────────────────────────────────────────────

  Widget _buildHemoglobinCard({
    required double hemoglobin,
    required bool isDark,
  }) {
    const color = Color(0xFFEF4444); // Red
    final hasData = hemoglobin > 0;
    final healthy = hemoglobin >= 11;

    var insight =
        'Hemoglobin carries oxygen to you and your baby. In pregnancy it should stay at 11 g/dL or above. Log it from your latest blood test.';
    if (hasData) {
      insight = healthy
          ? 'Your hemoglobin of ${hemoglobin.toStringAsFixed(1)} g/dL is in a healthy range. Keep up iron-rich foods like greens, dates and lentils.'
          : 'Your hemoglobin of ${hemoglobin.toStringAsFixed(1)} g/dL is below 11 g/dL. Take your iron tablets regularly and speak to your doctor.';
    }

    return _featureCard(
      page: const HemoglobinSummaryScreen(),
      icon: Icons.bloodtype_rounded,
      color: color,
      title: 'Hemoglobin (Hb)',
      status: hasData ? (healthy ? 'Healthy' : 'Low') : 'No data',
      hasData: hasData,
      value: hasData ? hemoglobin.toStringAsFixed(1) : '--',
      unit: hasData ? 'g/dL' : null,
      insight: insight,
      isDark: isDark,
    );
  }

  // ─── CARD BUILDERS ──────────────────────────────────────────

  /// One-third-width card: icon, label, value and a status chip.
  Widget _compactCard({
    required Widget page,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? unit,
    required String chip,
    required bool chipActive,
    Widget? trailing,
    required bool isDark,
  }) {
    return _baseCard(
      page: page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconBubble(icon, color),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 1),
                      Text(
                        unit,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: chipActive
                      ? color.withValues(alpha: 0.08)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  chip,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: chipActive
                        ? color
                        : (isDark ? Colors.white30 : Colors.black38),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Two-thirds-width card: titled header with badge, value, optional
  /// progress bar and a short insight.
  Widget _wideCard({
    required Widget page,
    required IconData icon,
    required Color color,
    required String title,
    required Widget badge,
    required String value,
    String? unit,
    double unitGap = 3,
    List<Widget>? valueExtras,
    double? progress,
    required String insight,
    int insightMaxLines = 2,
    bool insightStrong = false,
    required bool isDark,
  }) {
    return _baseCard(
      page: page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _iconBubble(icon, color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              badge,
            ],
          ),
          SizedBox(height: progress != null ? 14 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit != null) ...[
                  SizedBox(width: unitGap),
                  Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white30 : Colors.black38,
                    ),
                  ),
                ],
                ...?valueExtras,
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            insight,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: insightStrong
                  ? (isDark ? Colors.white54 : Colors.black54)
                  : (isDark ? Colors.white38 : Colors.black45),
              height: 1.3,
            ),
            maxLines: insightMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Full-width card with room for a plain-language explanation.
  Widget _featureCard({
    required Widget page,
    required IconData icon,
    required Color color,
    required String title,
    required String status,
    required bool hasData,
    required String value,
    String? unit,
    required String insight,
    required bool isDark,
  }) {
    return _baseCard(
      page: page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF1B1C1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasData
                      ? color.withValues(alpha: 0.1)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: hasData
                        ? color
                        : (isDark ? Colors.white30 : Colors.black38),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B1C1A),
                  letterSpacing: -0.5,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBubble(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _badge(
    String text,
    Color fg,
    Color bg, {
    Widget? leading,
    double fontSize = 9,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.red.shade400,
        ),
      ),
    );
  }

  /// Shared shell; tapping opens the vital's detail page.
  Widget _baseCard({required Widget page, required Widget child}) {
    final isDark = context.palette.isDark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// The numbers the cards need, whichever day they come from.
class _VitalsSnapshot {
  final int steps;
  final double sleepHours;
  final int heartRate;
  final int bloodOxygen;
  final int stress;
  final int? systolic;
  final int? diastolic;
  final double glucose;
  final String glucosePhase;
  final double hemoglobin;

  const _VitalsSnapshot({
    required this.steps,
    required this.sleepHours,
    required this.heartRate,
    required this.bloodOxygen,
    required this.stress,
    required this.systolic,
    required this.diastolic,
    required this.glucose,
    required this.glucosePhase,
    required this.hemoglobin,
  });

  factory _VitalsSnapshot.from({
    required VitalsStreamResponse? steps,
    required double sleepHours,
    required VitalsStreamResponse? heartRate,
    required VitalsStreamResponse? bloodOxygen,
    required VitalsStreamResponse? stress,
    required VitalsStreamResponse? bloodPressure,
    required VitalsStreamResponse? glucose,
    required VitalsStreamResponse? hemoglobin,
  }) {
    int? asInt(dynamic raw) {
      if (raw is num) return raw.round();
      return int.tryParse(raw?.toString() ?? '') ??
          double.tryParse(raw?.toString() ?? '')?.round();
    }

    int? systolic;
    int? diastolic;
    if (bloodPressure != null) {
      systolic = asInt(bloodPressure.data?['systolic']) ??
          (bloodPressure.value > 0 ? bloodPressure.value.round() : null);
      diastolic = asInt(bloodPressure.data?['diastolic']);
    }

    return _VitalsSnapshot(
      steps: steps?.value.toInt() ?? 0,
      sleepHours: sleepHours,
      heartRate: heartRate?.value.toInt() ?? 0,
      bloodOxygen: bloodOxygen?.value.toInt() ?? 0,
      stress: stress?.value.toInt() ?? 0,
      systolic: systolic,
      diastolic: diastolic,
      glucose: glucose?.value ?? 0,
      glucosePhase:
          glucose?.data?['mealPhase']?.toString().toLowerCase() ?? 'fasting',
      hemoglobin: hemoglobin?.value ?? 0,
    );
  }

  bool get hasBloodPressure => systolic != null && systolic! > 0;

  String get bpText => diastolic == null ? '$systolic' : '$systolic/$diastolic';

  String get bpStatus {
    final sys = systolic ?? 0;
    final dia = diastolic ?? 0;
    if (sys >= 140 || dia >= 90) return 'High';
    if (sys >= 120 || dia >= 80) return 'Elevated';
    return 'Normal';
  }

  bool get _isFasting => !glucosePhase.contains('after') &&
      !glucosePhase.contains('post') &&
      !glucosePhase.contains('random');

  String get glucosePhaseLabel => _isFasting ? 'Fasting' : 'After meal';

  String get glucoseStatus {
    if (glucose < 70) return 'Low';
    final ceiling = _isFasting ? 95 : 140;
    return glucose <= ceiling ? 'Normal' : 'High';
  }
}

/// Pulsing heart dot micro-animation.
class _PulsingHeartDot extends StatefulWidget {
  final Color color;
  const _PulsingHeartDot({required this.color});

  @override
  State<_PulsingHeartDot> createState() => _PulsingHeartDotState();
}

class _PulsingHeartDotState extends State<_PulsingHeartDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
