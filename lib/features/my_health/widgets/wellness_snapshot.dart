import 'package:flutter/material.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

/// One reading per vital — the freshest available — plus the wellness score
/// blended from them. Ported from AlloConnect's `WellnessSnapshot` (with the
/// parts of its `ReadinessEngine` that produce the score folded in), so every
/// surface that shows a wellness score agrees on the number.
///
/// Each vital falls back to its own most recent reading within [maxStaleness]
/// independently, so a two-day-old sleep log still counts alongside a heart
/// rate taken this morning.
class WellnessSnapshot {
  /// How old a reading may be and still count toward the score.
  static const Duration maxStaleness = Duration(days: 7);

  /// Vitals the score is blended from, each no older than [maxStaleness].
  final VitalsStreamResponse? hrv;
  final VitalsStreamResponse? heartRate;
  final VitalsStreamResponse? steps;
  final VitalsStreamResponse? sleep;
  final VitalsStreamResponse? stress;
  final VitalsStreamResponse? bloodOxygen;

  /// Manually logged readings — not windowed, not part of the score.
  final VitalsStreamResponse? bloodPressure;
  final VitalsStreamResponse? weight;
  final VitalsStreamResponse? height;

  /// Newest reading feeding the score, or null when nothing does.
  final DateTime? asOf;
  final double? _todaySleepHours;

  const WellnessSnapshot._({
    required this.asOf,
    this.hrv,
    this.heartRate,
    this.steps,
    this.sleep,
    this.stress,
    this.bloodOxygen,
    this.bloodPressure,
    this.weight,
    this.height,
    double? todaySleepHours,
  }) : _todaySleepHours = todaySleepHours;

  static const Map<String, List<String>> _aliases = {
    'hrv': ['hrv'],
    'heart_rate': ['heart_rate'],
    'steps': ['steps'],
    'sleep': ['sleep_data', 'sleep', 'sleep_hours'],
    'stress': ['stress'],
    'blood_oxygen': ['blood_oxygen', 'spo2'],
    'blood_pressure': ['blood_pressure'],
    'weight': ['weight'],
    'height': ['height'],
  };

  /// Snapshot built from [HealthVitalsController.instance]'s vitals.
  factory WellnessSnapshot.current({DateTime? at}) =>
      WellnessSnapshot.from(HealthVitalsController.instance.vitals, at: at);

  /// Builds the snapshot as it stood at [at] (defaults to now).
  factory WellnessSnapshot.from(
    List<VitalsStreamResponse> vitals, {
    DateTime? at,
    Duration window = maxStaleness,
    double? todaySleepHours,
  }) {
    final cutoff = at ?? DateTime.now();

    DateTime? freshest;
    VitalsStreamResponse? scoring(String key) {
      final vital = _latestAsOf(vitals, key, cutoff, window);
      if (vital != null &&
          (freshest == null || vital.createdAt.isAfter(freshest!))) {
        freshest = vital.createdAt;
      }
      return vital;
    }

    final hrv = scoring('hrv');
    final heartRate = scoring('heart_rate');
    final steps = scoring('steps');
    final sleep = scoring('sleep');
    final stress = scoring('stress');
    final bloodOxygen = scoring('blood_oxygen');

    final snapshot = WellnessSnapshot._(
      asOf: freshest,
      hrv: hrv,
      heartRate: heartRate,
      steps: steps,
      sleep: sleep,
      stress: stress,
      bloodOxygen: bloodOxygen,
      bloodPressure: _latestAsOf(vitals, 'blood_pressure', cutoff, null),
      weight: _latestAsOf(vitals, 'weight', cutoff, null),
      height: _latestAsOf(vitals, 'height', cutoff, null),
      todaySleepHours: todaySleepHours,
    );
    return snapshot.hasAnyData
        ? snapshot
        : WellnessSnapshot._(
            asOf: null,
            bloodPressure: snapshot.bloodPressure,
            weight: snapshot.weight,
            height: snapshot.height,
            todaySleepHours: todaySleepHours,
          );
  }

  static VitalsStreamResponse? _latestAsOf(
    List<VitalsStreamResponse> vitals,
    String key,
    DateTime cutoff,
    Duration? window,
  ) {
    final keys = _aliases[key] ?? [key];
    final earliest = window == null ? null : cutoff.subtract(window);
    VitalsStreamResponse? best;
    for (final v in vitals) {
      if (!keys.contains(v.key.toLowerCase())) continue;
      if (v.createdAt.isAfter(cutoff)) continue;
      if (earliest != null && v.createdAt.isBefore(earliest)) continue;
      if (best == null || v.createdAt.isAfter(best.createdAt)) best = v;
    }
    return best;
  }

  // ── Readiness score (AlloConnect ReadinessEngine.readinessScore) ─────────

  static const double _baselineHRV = 50.0;
  static const double _baselineHR = 72.0;
  static const double _maxExpectedSteps = 10000.0;

  bool get _hasHRV => (hrv?.value ?? 0) > 0;
  bool get _hasHR => (heartRate?.value ?? 0) > 0;
  bool get _hasSteps => (steps?.value ?? 0) > 0;
  bool get _hasSleep => sleepHours > 0;
  bool get hasAnyData => _hasHRV || _hasHR || _hasSteps || _hasSleep;

  double get _sleepScore {
    final h = sleepHours;
    if (h >= 7.5 && h <= 9.0) return 1.0;
    if (h > 9.0) return 0.75;
    if (h >= 7.0) return 0.85;
    if (h >= 6.0) return 0.70;
    if (h >= 5.0) return 0.55;
    return 0.35;
  }

  /// The shared 0-100 wellness score.
  int get score {
    if (!hasAnyData) return 0;
    double totalWeight = 0;
    double totalScore = 0;
    if (_hasHRV) {
      totalScore += (hrv!.value / _baselineHRV).clamp(0.0, 1.0) * 35;
      totalWeight += 35;
    }
    if (_hasHR) {
      totalScore += (_baselineHR / heartRate!.value).clamp(0.0, 1.0) * 25;
      totalWeight += 25;
    }
    if (_hasSleep) {
      totalScore += _sleepScore * 30;
      totalWeight += 30;
    }
    if (_hasSteps) {
      totalScore += (steps!.value / _maxExpectedSteps).clamp(0.0, 1.0) * 10;
      totalWeight += 10;
    }
    final s = stress?.value ?? 0;
    if (s > 0) {
      totalScore += s < 40 ? 5.0 : (s > 70 ? -5.0 : 0.0);
    }
    if (totalWeight == 0) return 50;
    return ((totalScore / totalWeight) * 100).round().clamp(0, 100);
  }

  bool get hasData => hasAnyData && asOf != null;

  /// Whole days between [asOf] and [reference]; 0 while the data is same-day.
  int daysBehind(DateTime reference) {
    if (asOf == null) return 0;
    return DateUtils.dateOnly(reference)
        .difference(DateUtils.dateOnly(asOf!))
        .inDays;
  }

  static int? ageInDays(VitalsStreamResponse? vital, DateTime reference) {
    if (vital == null) return null;
    return DateUtils.dateOnly(reference)
        .difference(DateUtils.dateOnly(vital.createdAt))
        .inDays;
  }

  /// "Today" / "Yesterday" / "3d ago" for a reading, or null when absent.
  static String? freshnessLabel(
    VitalsStreamResponse? vital,
    DateTime reference,
  ) {
    final days = ageInDays(vital, reference);
    if (days == null) return null;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '${days}d ago';
  }

  /// Sleep in hours; Allomom stores sleep either in minutes or in hours.
  double get sleepHours {
    if (_todaySleepHours != null) return _todaySleepHours;
    final s = sleep;
    if (s == null) return 0;
    if (s.unit.toLowerCase().contains('min') || s.value > 24) {
      return s.value / 60.0;
    }
    return s.value;
  }

  int get stepsCount => steps?.value.round() ?? 0;

  int get heartRateBpm => heartRate?.value.round() ?? 0;

  int get bloodOxygenPercent => bloodOxygen?.value.round() ?? 0;

  int get stressLevel => stress?.value.round() ?? 0;

  int get systolic => _bpPart('systolic', bloodPressure?.value.round() ?? 0);

  int get diastolic => _bpPart('diastolic', 0);

  int _bpPart(String key, int fallback) {
    final raw = bloodPressure?.data?[key];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }
}
