import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class _HealthColors {
  static const excellent = Color(0xFF10B981);
  static const good = Color(0xFF34D399);
  static const fair = Color(0xFFF59E0B);
  static const poor = Color(0xFFEF4444);
  static const noData = Color(0xFF94A3B8);
}

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
        HealthStatus.excellent => 'Optimal',
        HealthStatus.good => 'Good',
        HealthStatus.fair => 'Fair',
        HealthStatus.poor => 'Needs Attention',
        HealthStatus.noData => 'Calibrating',
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
  final String note;

  _CategoryResult({
    required this.name,
    required this.icon,
    required this.score,
    required this.note,
  }) : status = score == 0 ? HealthStatus.noData : _scoreToStatus(score);
}

class _Engine {
  static ({int overallScore, HealthStatus overallStatus, List<_CategoryResult> categories, List<String> priorities}) compute({
    required int steps,
    required double sleepHours,
    required int heartRate,
    required int bloodOxygen,
    required int systolic,
    required int diastolic,
    required int stressScore,
    required double weight,
    required double height,
  }) {
    final categories = <_CategoryResult>[];
    final priorities = <String>[];
    int totalPoints = 0;
    int maxPoints = 0;

    // 1. Steps / Movement
    if (steps > 0) {
      int stepScore = ((steps / 6000) * 100).clamp(0, 100).toInt();
      categories.add(_CategoryResult(
        name: 'Activity',
        icon: Icons.directions_walk_rounded,
        score: stepScore,
        note: steps >= 6000 ? 'Goal met' : '$steps / 6,000 steps',
      ));
      totalPoints += (stepScore * 0.15).toInt();
      maxPoints += 15;
    }

    // 2. Sleep
    if (sleepHours > 0) {
      int sleepScore = (sleepHours >= 7 && sleepHours <= 9)
          ? 95
          : (sleepHours >= 6 ? 78 : 55);
      categories.add(_CategoryResult(
        name: 'Sleep',
        icon: Icons.bedtime_rounded,
        score: sleepScore,
        note: '${sleepHours.toStringAsFixed(1)}h rested',
      ));
      totalPoints += (sleepScore * 0.20).toInt();
      maxPoints += 20;
    }

    // 3. Heart Rate
    if (heartRate > 0) {
      int hrScore = (heartRate >= 60 && heartRate <= 100) ? 95 : 65;
      categories.add(_CategoryResult(
        name: 'Heart Rate',
        icon: Icons.favorite_rounded,
        score: hrScore,
        note: '$heartRate bpm',
      ));
      totalPoints += (hrScore * 0.15).toInt();
      maxPoints += 15;
    }

    // 4. Blood Oxygen
    if (bloodOxygen > 0) {
      int oxyScore = bloodOxygen >= 95 ? 98 : (bloodOxygen >= 90 ? 70 : 45);
      categories.add(_CategoryResult(
        name: 'Blood Oxygen',
        icon: Icons.air_rounded,
        score: oxyScore,
        note: '$bloodOxygen% SpO2',
      ));
      totalPoints += (oxyScore * 0.15).toInt();
      maxPoints += 15;
    }

    // 5. Blood Pressure
    if (systolic > 0 && diastolic > 0) {
      int bpScore = (systolic <= 120 && diastolic <= 80)
          ? 96
          : (systolic <= 130 && diastolic <= 85 ? 80 : 60);
      categories.add(_CategoryResult(
        name: 'Blood Pressure',
        icon: Icons.speed_rounded,
        score: bpScore,
        note: '$systolic/$diastolic mmHg',
      ));
      totalPoints += (bpScore * 0.20).toInt();
      maxPoints += 20;
    }

    // 6. Stress
    int computedStressScore = stressScore > 0 ? (100 - stressScore).clamp(20, 95) : 85;
    categories.add(_CategoryResult(
      name: 'Stress Recovery',
      icon: Icons.spa_rounded,
      score: computedStressScore,
      note: computedStressScore >= 80 ? 'Well Recovered' : 'Moderate Load',
    ));
    totalPoints += (computedStressScore * 0.15).toInt();
    maxPoints += 15;

    int finalScore = maxPoints > 0 ? ((totalPoints / maxPoints) * 100).round() : 88;
    final status = _scoreToStatus(finalScore);

    if (finalScore >= 85) {
      priorities.add("Your vitals are in excellent balance for gestational stage.");
    } else {
      priorities.add("Stay well hydrated and maintain gentle daily strolls.");
    }

    return (
      overallScore: finalScore,
      overallStatus: status,
      categories: categories,
      priorities: priorities,
    );
  }
}

class AdvancedHealthSummaryCard extends StatelessWidget {
  const AdvancedHealthSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([HealthVitalsController.instance, UserSessionManager.instance]),
      builder: (context, _) {
        final vitals = HealthVitalsController.instance;

        final bpVital = vitals.bloodPressureVital;
        final bpData = bpVital?.data ?? {};
        final systolic = (bpData['systolic'] as num?)?.toInt() ?? 118;
        final diastolic = (bpData['diastolic'] as num?)?.toInt() ?? 76;
        final hr = int.tryParse(vitals.heartRateValue) ?? 78;
        final spo2 = int.tryParse(vitals.bloodOxygenValue) ?? 98;
        final steps = vitals.stepsValue;
        final sleepH = vitals.sleepHoursValue;
        final stressScore = vitals.stressLevel.toLowerCase() == 'low' ? 20 : (vitals.stressLevel.toLowerCase() == 'high' ? 75 : 45);

        final result = _Engine.compute(
          steps: steps,
          sleepHours: sleepH,
          heartRate: hr,
          bloodOxygen: spo2,
          systolic: systolic,
          diastolic: diastolic,
          stressScore: stressScore,
          weight: vitals.weightValue,
          height: vitals.heightValue,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Readiness & Vital Score',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Real-time biometric assessment',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8E95A5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: result.overallStatus.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      result.overallStatus.label,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: result.overallStatus.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Score Meter & Insights Row
              Row(
                children: [
                  // Circular Score Gauge
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: CircularProgressIndicator(
                            value: result.overallScore / 100.0,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(result.overallStatus.color),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${result.overallScore}',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E2024),
                              ),
                            ),
                            Text(
                              '/ 100',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Insight message
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: Color(0xFFFF3B5C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.priorities.firstOrNull ?? "Keep maintaining your balanced nutrition and daily walks.",
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Mini Badges Grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.categories.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 13, color: c.status.color),
                        const SizedBox(width: 5),
                        Text(
                          '${c.name}: ',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          c.note,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
