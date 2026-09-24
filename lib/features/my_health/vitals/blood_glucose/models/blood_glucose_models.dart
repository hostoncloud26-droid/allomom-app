// Blood glucose models, in the shape of AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/models/blood_oxygen_models.dart.
//
// Gestational-diabetes targets from Allomom's blood glucose detail page:
// fasting / pre-meal below 95 mg/dL, post-meal below 120 mg/dL, with a
// 70–140 mg/dL band on the charts. Below 70 is low.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/models/vitals_stream_model.dart';

const Color kGlucoseColor = Color(0xFFD97706);

/// Keys Allomom stores glucose under: `glucose` now, `blood_glucose` on older
/// rows.
const List<String> kGlucoseKeys = ['glucose', 'blood_glucose'];

const double kGlucoseLow = 70;
const double kGlucoseFastingTarget = 95;
const double kGlucosePostMealTarget = 120;
const double kGlucoseBandMin = 70;
const double kGlucoseBandMax = 140;

/// Meal phases the Allomom log sheet writes to `data['mealPhase']`.
const List<String> kGlucoseMealPhases = ['fasting', 'pre_meal', 'post_meal'];

String glucosePhaseLabel(String phase) {
  switch (phase) {
    case 'fasting':
      return 'Fasting';
    case 'pre_meal':
      return 'Pre-Meal';
    case 'post_meal':
      return 'Post-Meal';
  }
  if (phase.isEmpty) return 'Fasting';
  final s = phase.replaceAll('_', ' ');
  return s[0].toUpperCase() + s.substring(1);
}

/// Post-meal (and random) readings are held to the post-meal target.
bool glucoseIsPostMeal(String phase) {
  final p = phase.toLowerCase();
  return p.contains('post') || p.contains('after') || p.contains('random');
}

double glucoseTargetFor(String phase) =>
    glucoseIsPostMeal(phase) ? kGlucosePostMealTarget : kGlucoseFastingTarget;

enum GlucoseCategory { low, inTarget, aboveTarget, high }

extension GlucoseCategoryX on GlucoseCategory {
  String get label {
    switch (this) {
      case GlucoseCategory.low:
        return 'Low';
      case GlucoseCategory.inTarget:
        return 'In Target';
      case GlucoseCategory.aboveTarget:
        return 'Above Target';
      case GlucoseCategory.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case GlucoseCategory.low:
        return const Color(0xFF3B82F6);
      case GlucoseCategory.inTarget:
        return const Color(0xFF10B981);
      case GlucoseCategory.aboveTarget:
        return const Color(0xFFF59E0B);
      case GlucoseCategory.high:
        return const Color(0xFFEF4444);
    }
  }
}

GlucoseCategory glucoseCategoryFor(double mgDl, String phase) {
  if (mgDl < kGlucoseLow) return GlucoseCategory.low;
  final post = glucoseIsPostMeal(phase);
  final target = post ? kGlucosePostMealTarget : kGlucoseFastingTarget;
  if (mgDl < target) return GlucoseCategory.inTarget;
  final high = post ? 180.0 : 126.0;
  if (mgDl < high) return GlucoseCategory.aboveTarget;
  return GlucoseCategory.high;
}

class GlucoseReading {
  final VitalsStreamResponse vital;

  GlucoseReading(this.vital);

  DateTime get timestamp => vital.createdAt;
  double get value => vital.value;
  String get mealPhase {
    final p = vital.data?['mealPhase']?.toString().trim() ?? '';
    return p.isEmpty ? 'fasting' : p;
  }

  bool get isPostMeal => glucoseIsPostMeal(mealPhase);
  GlucoseCategory get category => glucoseCategoryFor(value, mealPhase);
  bool get isInTarget => category == GlucoseCategory.inTarget;
  bool get isEditable =>
      (vital.data?['source']?.toString().toLowerCase() ?? '') != 'allowear';
}

double? _avg(Iterable<double> values) {
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

class GlucoseStats {
  final List<GlucoseReading> readings;

  GlucoseStats(this.readings);

  bool get hasData => readings.isNotEmpty;
  double get avg => _avg(readings.map((r) => r.value)) ?? 0;
  double get min =>
      readings.map((r) => r.value).reduce((a, b) => a < b ? a : b);
  double get max =>
      readings.map((r) => r.value).reduce((a, b) => a > b ? a : b);
  double? get fastingAvg =>
      _avg(readings.where((r) => !r.isPostMeal).map((r) => r.value));
  double? get postMealAvg =>
      _avg(readings.where((r) => r.isPostMeal).map((r) => r.value));
  double get inTargetPercent => readings.isEmpty
      ? 0
      : readings.where((r) => r.isInTarget).length / readings.length * 100;
}

class DailyGlucoseAggregate {
  final DateTime date;
  final List<GlucoseReading> readings;

  DailyGlucoseAggregate({required this.date, required this.readings});

  bool get hasData => readings.isNotEmpty;
  GlucoseStats get stats => GlucoseStats(readings);
  double get avg => stats.avg;

  /// [days] consecutive days ending today, empty days included, oldest first.
  static List<DailyGlucoseAggregate> lastDays(
    List<VitalsStreamResponse> history,
    int days,
  ) {
    final grouped = <String, List<GlucoseReading>>{};
    for (final v in history) {
      final key = DateFormat('yyyy-MM-dd').format(v.createdAt);
      grouped.putIfAbsent(key, () => []).add(GlucoseReading(v));
    }
    final now = DateTime.now();
    return List.generate(days, (i) {
      final d = DateTime(now.year, now.month, now.day - (days - 1 - i));
      final readings = grouped[DateFormat('yyyy-MM-dd').format(d)] ?? [];
      readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return DailyGlucoseAggregate(date: d, readings: readings);
    });
  }
}
