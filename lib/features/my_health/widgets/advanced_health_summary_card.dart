import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/widgets/wellness_snapshot.dart';
import 'package:allomom/features/my_health/vitals/steps/steps_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/heart_rate_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/blood_pressure_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/stress/stress_summary_screen.dart';

// Port of AlloConnect's `HealthSummaryCard`
// (lib/features/health_section/section/self/advanced_health_summary_card.dart).

// ════════════════════════════════════════════════════════════════════════════
//  THEME TOKENS
// ════════════════════════════════════════════════════════════════════════════

class _HealthColors {
  static const excellent = Color(0xFF4CAF82);
  static const good = Color(0xFF81C784);
  static const fair = Color(0xFFFFB74D);
  static const poor = Color(0xFFEF5350);
  static const noData = Color(0xFF78909C);
}

// ════════════════════════════════════════════════════════════════════════════
//  MODELS
// ════════════════════════════════════════════════════════════════════════════

enum HealthStatus { excellent, good, fair, poor, noData }

extension HealthStatusX on HealthStatus {
  Color get color => switch (this) {
        HealthStatus.excellent => _HealthColors.excellent,
        HealthStatus.good => _HealthColors.good,
        HealthStatus.fair => _HealthColors.fair,
        HealthStatus.poor => _HealthColors.poor,
        HealthStatus.noData => _HealthColors.noData,
      };

  String get label => switch (this) {
        HealthStatus.excellent => 'Excellent',
        HealthStatus.good => 'Good',
        HealthStatus.fair => 'Fair',
        HealthStatus.poor => 'Needs Attention',
        HealthStatus.noData => 'No Data',
      };
}

HealthStatus _scoreToStatus(int score) => switch (score) {
      >= 85 => HealthStatus.excellent,
      >= 70 => HealthStatus.good,
      >= 50 => HealthStatus.fair,
      > 0 => HealthStatus.poor,
      _ => HealthStatus.noData,
    };

class _CategoryResult {
  final String name;
  final IconData icon;
  final int score;
  final HealthStatus status;
  final List<String> insights;

  _CategoryResult({
    required this.name,
    required this.icon,
    required this.score,
    required this.insights,
  }) : status = score == 0 ? HealthStatus.noData : _scoreToStatus(score);
}

class _HealthData {
  final int overallScore;
  final HealthStatus overallStatus;
  final List<_CategoryResult> categories;
  final List<String> priorities;

  _HealthData({
    required this.overallScore,
    required this.categories,
    required this.priorities,
  }) : overallStatus = _scoreToStatus(overallScore);

  _HealthData withOverallScore(int score) => _HealthData(
        overallScore: score,
        categories: categories,
        priorities: priorities,
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  SCORING ENGINE
// ════════════════════════════════════════════════════════════════════════════

class _Engine {
  static _HealthData compute({
    required int steps,
    required double sleepHours,
    required int heartRate,
    required int bloodOxygen,
    required int systolic,
    required int diastolic,
    required int stress,
    required double weight,
    required double height,
  }) {
    final priorities = <String>[];
    final activity = _scoreActivity(steps, priorities);
    final sleep = _scoreSleep(sleepHours, stress, priorities);
    final cardio =
        _scoreCardio(heartRate, bloodOxygen, systolic, diastolic, priorities);
    final stressRes = _scoreStress(stress, priorities);
    final body = _scoreBody(weight, height, priorities);

    final categories = [activity, sleep, cardio, stressRes, body];
    final validScores =
        categories.where((c) => c.score > 0).map((c) => c.score).toList();
    final overall = validScores.isEmpty
        ? 0
        : (validScores.reduce((a, b) => a + b) / validScores.length).round();

    return _HealthData(
      overallScore: overall,
      categories: categories,
      priorities: priorities,
    );
  }

  static _CategoryResult _scoreActivity(int steps, List<String> p) {
    if (steps == 0) {
      return _CategoryResult(
        name: 'Activity',
        icon: Icons.directions_run_rounded,
        score: 0,
        insights: ['No step data — ensure your device is synced'],
      );
    }
    final (score, insights) = switch (steps) {
      >= 10000 => (100, ['Daily goal achieved — great momentum!']),
      >= 7500 => (
          85,
          [
            '${10000 - steps} steps to your daily goal',
            'A short walk will get you there'
          ]
        ),
      >= 5000 => (
          70,
          [
            'Moderate activity today',
            'Aim for a 20–30 min walk to boost your count'
          ]
        ),
      _ => (
          55,
          [
            'Low activity detected',
            'More movement improves cardiovascular health'
          ]
        ),
    };
    if (score < 70) p.add('Increase daily movement');
    return _CategoryResult(
      name: 'Activity',
      icon: Icons.directions_run_rounded,
      score: score,
      insights: insights,
    );
  }

  static _CategoryResult _scoreSleep(double hours, int stress, List<String> p) {
    if (hours == 0) {
      return _CategoryResult(
        name: 'Sleep',
        icon: Icons.bedtime_rounded,
        score: 0,
        insights: ['No sleep data available'],
      );
    }
    final (score, insights) = switch (hours) {
      >= 7.5 && <= 9.0 => (
          100,
          ['Optimal sleep — excellent recovery', 'Keep this routine going']
        ),
      > 9.0 => (
          68,
          ['Extended sleep duration', 'Oversleeping can impact daytime alertness']
        ),
      >= 7.0 => (
          80,
          ['Good sleep duration', 'Adding 30 min reaches optimal recovery']
        ),
      >= 6.0 => (
          68,
          ['Average sleep — below optimal', 'Target 7.5–8 hours for better recovery']
        ),
      >= 5.0 => (
          55,
          ['Insufficient sleep — affects immunity', 'Prioritize rest tonight']
        ),
      _ => (
          40,
          ['Critical: very low sleep', 'Make sleep your top priority now']
        ),
    };

    if (score < 75) {
      if (hours > 9.0) {
        p.add('Aim for 7.5–9 hours of sleep to avoid oversleeping');
      } else if (hours >= 6.0) {
        p.add('Target 7.5–8 hours of sleep for optimal recovery');
      } else {
        p.add('Improve sleep duration — aim for at least 7 hours');
      }
    }

    final extra = (hours < 6 && stress > 50)
        ? [
            'High stress levels combined with low sleep — prioritize physical recovery'
          ]
        : <String>[];
    return _CategoryResult(
      name: 'Sleep',
      icon: Icons.bedtime_rounded,
      score: score,
      insights: [...insights, ...extra],
    );
  }

  static _CategoryResult _scoreCardio(
    int hr,
    int spo2,
    int sys,
    int dia,
    List<String> p,
  ) {
    if (hr == 0 && sys == 0 && spo2 == 0) {
      return _CategoryResult(
        name: 'Cardiovascular',
        icon: Icons.favorite_rounded,
        score: 0,
        insights: ['Cardiovascular data unavailable'],
      );
    }

    int score = 100;
    final insights = <String>[];

    if (hr > 0) {
      if (hr >= 60 && hr <= 100) {
        insights.add('Heart rate in healthy range ($hr bpm)');
      } else if (hr > 100) {
        insights.add('Elevated HR ($hr bpm) — try relaxation techniques');
        score -= 20;
      } else {
        insights
            .add('Low resting HR ($hr bpm) — typical for active individuals');
        score -= 5;
      }
    }

    if (sys > 0) {
      if (sys < 120 && dia < 80) {
        insights.add('Blood pressure excellent ($sys/$dia mmHg)');
      } else if (sys < 140 && dia < 90) {
        insights.add('BP slightly elevated ($sys/$dia) — monitor closely');
        score -= 20;
        p.add('Monitor blood pressure regularly');
      } else {
        insights.add('BP concerning ($sys/$dia) — consult your doctor');
        score -= 40;
        p.add('High BP — consult a healthcare provider');
      }
    }

    if (spo2 > 0) {
      if (spo2 >= 95) {
        insights.add('Oxygen saturation excellent ($spo2%)');
      } else if (spo2 >= 90) {
        insights.add('SpO2 adequate ($spo2%) — stay hydrated');
        score -= 15;
      } else {
        insights.add('Low SpO2 ($spo2%) — seek medical attention');
        score -= 50;
        p.add('Low oxygen — consult a doctor immediately');
      }
    }

    return _CategoryResult(
      name: 'Cardiovascular',
      icon: Icons.favorite_rounded,
      score: score.clamp(0, 100),
      insights: insights,
    );
  }

  static _CategoryResult _scoreStress(int stress, List<String> p) {
    if (stress == 0) {
      return _CategoryResult(
        name: 'Stress',
        icon: Icons.psychology_rounded,
        score: 0,
        insights: ['No stress data available'],
      );
    }

    final (score, insights) = switch (stress) {
      <= 25 => (100, ['Low stress level ($stress%)', 'Recovered / Calm state']),
      <= 50 => (85, ['Moderate stress load ($stress%)', 'Normal / Mild load']),
      <= 75 => (
          65,
          ['High stress detected ($stress%)', 'Consider relaxation techniques']
        ),
      _ => (
          45,
          ['Very High stress level ($stress%)', 'System overloaded — rest now']
        ),
    };

    if (score < 70) p.add('Reduce stress load — prioritize calm');
    return _CategoryResult(
      name: 'Stress',
      icon: Icons.psychology_rounded,
      score: score,
      insights: insights,
    );
  }

  static _CategoryResult _scoreBody(
      double weight, double height, List<String> p) {
    if (height <= 0 || weight <= 0) {
      return _CategoryResult(
        name: 'Body Composition',
        icon: Icons.monitor_weight_rounded,
        score: 0,
        insights: ['Height or weight data incomplete'],
      );
    }

    // Height may be stored in cm or m.
    final hm = height > 3 ? height / 100 : height;
    final bmi = weight / (hm * hm);
    final bmiStr = bmi.toStringAsFixed(1);

    final (score, insights) = switch (bmi) {
      < 18.5 => (
          78,
          [
            'Below healthy weight (BMI $bmiStr)',
            'Consider a nutritionist consultation'
          ]
        ),
      < 25 => (
          100,
          ['Healthy BMI ($bmiStr) — great work', 'Maintain current habits']
        ),
      < 30 => (
          72,
          ['Overweight (BMI $bmiStr)', 'Cardio + strength training recommended']
        ),
      _ => (
          48,
          ['Obese range (BMI $bmiStr)', 'Consult your doctor for a weight plan']
        ),
    };

    if (score < 70) p.add('Weight management recommended');
    return _CategoryResult(
      name: 'Body Composition',
      icon: Icons.monitor_weight_rounded,
      score: score,
      insights: insights,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  RING PAINTER
// ════════════════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  const _RingPainter(
      {required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width <= 72 ? 4.5 : 7.0;
    final r = size.width / 2 - strokeWidth;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r, stroke..color = track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2,
        2 * pi * progress.clamp(0, 1), false, stroke..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

// ════════════════════════════════════════════════════════════════════════════
//  CONTROLLER-FED WRAPPER (existing Allomom call site)
// ════════════════════════════════════════════════════════════════════════════

/// Health Summary card fed from [HealthVitalsController.instance]. Rebuilds on
/// every controller `update()`.
class AdvancedHealthSummaryCard extends StatelessWidget {
  const AdvancedHealthSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HealthVitalsController>(
      init: HealthVitalsController.instance,
      builder: (vitals) {
        final snapshot = WellnessSnapshot.from(vitals.vitals);
        final weight = snapshot.weight?.value ??
            (vitals.hasWeight ? vitals.weightValue : 0.0);
        final height = snapshot.height?.value ?? vitals.heightVital?.value ?? 0.0;
        return HealthSummaryCard(
          currentSteps: snapshot.stepsCount,
          sleepHours: snapshot.sleepHours,
          heartRate: snapshot.heartRateBpm,
          bloodOxygen: snapshot.bloodOxygenPercent,
          systolic: snapshot.systolic,
          diastolic: snapshot.diastolic,
          stress: snapshot.stressLevel,
          weight: weight,
          height: height,
          snapshot: snapshot,
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  HEALTH SUMMARY CARD
// ════════════════════════════════════════════════════════════════════════════

class HealthSummaryCard extends StatelessWidget {
  final int currentSteps;
  final double sleepHours;
  final int heartRate;
  final int bloodOxygen;
  final int systolic;
  final int diastolic;
  final int stress;
  final double weight;
  final double height;

  /// When supplied, its score becomes the headline number and each tile can
  /// say how fresh its reading is.
  final WellnessSnapshot? snapshot;

  const HealthSummaryCard({
    super.key,
    this.currentSteps = 0,
    this.sleepHours = 0,
    this.heartRate = 0,
    this.bloodOxygen = 0,
    this.systolic = 0,
    this.diastolic = 0,
    this.stress = 0,
    this.weight = 0,
    this.height = 0,
    this.snapshot,
  });

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final effectiveSleepMinutes = (sleepHours * 60).round();

    var data = _Engine.compute(
      steps: currentSteps,
      sleepHours: sleepHours,
      heartRate: heartRate,
      bloodOxygen: bloodOxygen,
      systolic: systolic,
      diastolic: diastolic,
      stress: stress,
      weight: weight,
      height: height,
    );

    final shared = snapshot;
    if (shared != null && shared.hasData) {
      data = data.withOverallScore(shared.score);
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final statusColor = data.overallStatus.color;
    final backgroundColor = theme.cardColor;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor =
        textColor.withValues(alpha: isDarkMode ? 0.62 : 0.58);
    final daysBehind = shared?.daysBehind(now) ?? 0;
    final isStale = daysBehind > 0;
    final timeframe = isStale ? 'recent trends' : 'today';

    final String headlineText;
    if (data.priorities.isNotEmpty) {
      headlineText =
          '${data.priorities.length} focus area${data.priorities.length > 1 ? 's' : ''} detected for $timeframe.';
    } else if (data.overallStatus == HealthStatus.excellent) {
      headlineText = isStale
          ? 'You are maintaining your health trends well.'
          : 'You are maintaining your health trends well today.';
    } else if (data.overallStatus == HealthStatus.good) {
      headlineText = isStale
          ? 'Your overall health trends are in good standing.'
          : 'Your overall health trends are in good standing today.';
    } else if (data.overallStatus == HealthStatus.fair) {
      headlineText = isStale
          ? 'Some health metrics need attention based on recent trends.'
          : 'Some health metrics need attention today.';
    } else {
      headlineText = 'Your health trends need attention.';
    }

    Color categoryColor(String name) =>
        data.categories.firstWhere((c) => c.name == name).status.color;

    final metrics = <_Metric>[
      _Metric(
        label: 'Steps',
        icon: Icons.directions_run_rounded,
        value: currentSteps == 0 ? '—' : _fmt(currentSteps),
        note: _note(shared?.steps, currentSteps == 0, 'Today', now),
        color: categoryColor('Activity'),
        onTap: () => _open(context, const StepsSummaryScreen()),
      ),
      _Metric(
        label: 'Sleep',
        icon: Icons.bedtime_rounded,
        value: effectiveSleepMinutes == 0
            ? '—'
            : _formatSleepDuration(effectiveSleepMinutes),
        note: _note(shared?.sleep, effectiveSleepMinutes == 0, 'Today', now),
        color: categoryColor('Sleep'),
        onTap: () => _open(context, const SleepSummaryScreen()),
      ),
      _Metric(
        label: 'HR',
        icon: Icons.favorite_rounded,
        value: heartRate == 0 ? '—' : '$heartRate bpm',
        note: _note(shared?.heartRate, heartRate == 0, 'Resting', now),
        color: heartRate == 0
            ? _HealthColors.noData
            : (heartRate >= 60 && heartRate <= 100)
                ? _HealthColors.excellent
                : _HealthColors.fair,
        onTap: () => _open(context, const HeartRateSummaryScreen()),
      ),
      _Metric(
        label: 'SpO2',
        icon: Icons.air_rounded,
        value: bloodOxygen == 0 ? '—' : '$bloodOxygen%',
        note: _note(shared?.bloodOxygen, bloodOxygen == 0, 'Latest', now),
        color: bloodOxygen == 0
            ? _HealthColors.noData
            : bloodOxygen >= 95
                ? _HealthColors.excellent
                : bloodOxygen >= 90
                    ? _HealthColors.fair
                    : _HealthColors.poor,
        onTap: () => _open(context, const BloodOxygenSummaryScreen()),
      ),
      _Metric(
        label: 'BP',
        icon: Icons.monitor_heart_rounded,
        value: systolic == 0 ? '—' : '$systolic/$diastolic',
        note: _note(shared?.bloodPressure, systolic == 0, 'mmHg', now),
        color: systolic == 0
            ? _HealthColors.noData
            : (systolic < 120 && diastolic < 80)
                ? _HealthColors.excellent
                : (systolic < 140 && diastolic < 90)
                    ? _HealthColors.fair
                    : _HealthColors.poor,
        onTap: () => _open(context, const BloodPressureSummaryScreen()),
      ),
      _Metric(
        label: 'Stress',
        icon: Icons.psychology_rounded,
        value: stress == 0 ? '—' : '',
        note: stress == 0 ? 'No data' : _getStressLabel(stress),
        color: categoryColor('Stress'),
        onTap: () => _open(context, const StressSummaryScreen()),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Health Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                        alpha: isDarkMode ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    data.overallStatus.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bigger than AlloKonnect's 68px: the score is the card's
                // headline, and at 68 it read as squeezed next to the text.
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(88, 88),
                        painter: _RingPainter(
                          progress: data.overallScore / 100,
                          color: statusColor,
                          track: isDarkMode
                              ? Colors.white.withValues(alpha: 0.1)
                              : cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${data.overallScore}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: subTextColor,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    headlineText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.42,
                    ),
                  ),
                ),
              ],
            ),
            // Room between the score and the tiles, which used to touch it.
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: metrics
                  .map((m) => _MetricTile(
                        m: m,
                        isDarkMode: isDarkMode,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (data.priorities.isNotEmpty) ...[
              Text(
                isStale ? 'Recommended Actions' : 'Recommended Today',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: subTextColor,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 8),
              ...data.priorities.map(
                (p) => _PriorityItem(
                  text: p,
                  textColor: textColor,
                  accentColor: primaryColor,
                  isDarkMode: isDarkMode,
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color:
                      statusColor.withValues(alpha: isDarkMode ? 0.15 : 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.overallStatus == HealthStatus.excellent
                            ? (isStale
                                ? 'All recorded metrics look stable.'
                                : 'All metrics look stable. Keep it up.')
                            : 'Metrics are generally stable. Maintain consistency.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The tile's usual caption while the reading is today's, swapped for how
  /// old it is once it isn't.
  String _note(
    VitalsStreamResponse? vital,
    bool isEmpty,
    String whenFresh,
    DateTime now,
  ) {
    if (isEmpty) return 'No data';
    final label = WellnessSnapshot.freshnessLabel(vital, now);
    if (label == null || label == 'Today') return whenFresh;
    return label;
  }

  static String _fmt(int n) {
    if (n >= 1000) {
      final k = n ~/ 1000;
      final rem = (n % 1000) ~/ 100;
      return rem > 0 ? '$k.${rem}k' : '${k}k';
    }
    return '$n';
  }

  static String _formatSleepDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _getStressLabel(int stress) {
    if (stress <= 0) return 'No data';
    if (stress <= 15) return 'Calm';
    if (stress <= 30) return 'Relaxed';
    if (stress <= 50) return 'Normal';
    if (stress <= 70) return 'Slightly tense';
    if (stress <= 85) return 'Tense';
    return 'Overwhelmed';
  }
}

// ── Compact metric tile ──────────────────────────────────────────────────────

class _Metric {
  final String label;
  final IconData icon;
  final String value;
  final String note;
  final Color color;
  final VoidCallback? onTap;

  const _Metric({
    required this.label,
    required this.icon,
    required this.value,
    required this.note,
    required this.color,
    this.onTap,
  });
}

class _MetricTile extends StatelessWidget {
  final _Metric m;
  final bool isDarkMode;
  final Color textColor;
  final Color subTextColor;

  const _MetricTile({
    required this.m,
    required this.isDarkMode,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: m.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: m.color.withValues(alpha: isDarkMode ? 0.09 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: m.color.withValues(alpha: isDarkMode ? 0.35 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: m.color.withValues(alpha: isDarkMode ? 0.2 : 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(m.icon, size: 13, color: m.color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    m.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: subTextColor.withValues(
                          alpha: subTextColor.a * 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  m.value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: m.value == '—' ? subTextColor : textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityItem extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color accentColor;
  final bool isDarkMode;

  const _PriorityItem({
    required this.text,
    required this.textColor,
    required this.accentColor,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDarkMode ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: isDarkMode ? 0.28 : 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.circle,
              size: 7,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
