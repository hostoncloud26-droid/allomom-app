// Hemoglobin models, in the shape of AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/models/blood_oxygen_models.dart.
//
// Ranges are the pregnancy anaemia bands Allomom's hemoglobin detail page
// uses: 11 g/dL and above is normal (target > 10.5), the chart's healthy band
// is 11–14 g/dL. Below 11 is split into the WHO pregnancy grades.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/models/vitals_stream_model.dart';

const Color kHemoglobinColor = Color(0xFFE11D48);

/// Healthy band drawn on the charts.
const double kHbBandMin = 11.0;
const double kHbBandMax = 14.0;

/// "Target > 10.5" shown on Allomom's detail page.
const double kHbTarget = 10.5;

enum HbCategory { normal, mild, moderate, severe }

extension HbCategoryX on HbCategory {
  String get label {
    switch (this) {
      case HbCategory.normal:
        return 'Normal';
      case HbCategory.mild:
        return 'Mild Anaemia';
      case HbCategory.moderate:
        return 'Moderate Anaemia';
      case HbCategory.severe:
        return 'Severe Anaemia';
    }
  }

  String get rangeText {
    switch (this) {
      case HbCategory.normal:
        return '11 g/dL and above';
      case HbCategory.mild:
        return '10.0 – 10.9 g/dL';
      case HbCategory.moderate:
        return '7.0 – 9.9 g/dL';
      case HbCategory.severe:
        return 'Below 7 g/dL';
    }
  }

  Color get color {
    switch (this) {
      case HbCategory.normal:
        return const Color(0xFF10B981);
      case HbCategory.mild:
        return const Color(0xFFF59E0B);
      case HbCategory.moderate:
        return const Color(0xFFF97316);
      case HbCategory.severe:
        return const Color(0xFFEF4444);
    }
  }
}

HbCategory hbCategoryFor(double gdl) {
  if (gdl >= 11.0) return HbCategory.normal;
  if (gdl >= 10.0) return HbCategory.mild;
  if (gdl >= 7.0) return HbCategory.moderate;
  return HbCategory.severe;
}

class HemoglobinReading {
  final VitalsStreamResponse vital;

  HemoglobinReading(this.vital);

  DateTime get timestamp => vital.createdAt;
  double get value => vital.value;
  HbCategory get category => hbCategoryFor(value);
  bool get isNormal => value >= 11.0;
  bool get isEditable =>
      (vital.data?['source']?.toString().toLowerCase() ?? '') != 'allowear';
}

class DailyHemoglobinAggregate {
  final DateTime date;
  final double avg;
  final double min;
  final double max;
  final List<HemoglobinReading> readings;

  DailyHemoglobinAggregate({
    required this.date,
    required this.avg,
    required this.min,
    required this.max,
    required this.readings,
  });

  bool get hasData => readings.isNotEmpty;

  factory DailyHemoglobinAggregate.empty(DateTime date) =>
      DailyHemoglobinAggregate(
        date: DateTime(date.year, date.month, date.day),
        avg: 0,
        min: 0,
        max: 0,
        readings: const [],
      );

  factory DailyHemoglobinAggregate.fromReadings(
    DateTime date,
    List<HemoglobinReading> readings,
  ) {
    if (readings.isEmpty) return DailyHemoglobinAggregate.empty(date);
    final sorted = List<HemoglobinReading>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final values = sorted.map((r) => r.value).toList();
    final total = values.reduce((a, b) => a + b);
    return DailyHemoglobinAggregate(
      date: DateTime(date.year, date.month, date.day),
      avg: total / values.length,
      min: values.reduce((a, b) => a < b ? a : b),
      max: values.reduce((a, b) => a > b ? a : b),
      readings: sorted,
    );
  }

  /// One aggregate per calendar day that has readings, oldest first.
  static List<DailyHemoglobinAggregate> fromHistory(
    List<VitalsStreamResponse> history,
  ) {
    final grouped = <String, List<HemoglobinReading>>{};
    for (final v in history) {
      final key = DateFormat('yyyy-MM-dd').format(v.createdAt);
      grouped.putIfAbsent(key, () => []).add(HemoglobinReading(v));
    }
    final result =
        grouped.entries
            .map(
              (e) => DailyHemoglobinAggregate.fromReadings(
                DateTime.parse(e.key),
                e.value,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// [days] consecutive days ending today, empty days included.
  static List<DailyHemoglobinAggregate> lastDays(
    List<VitalsStreamResponse> history,
    int days,
  ) {
    final byDay = {
      for (final a in fromHistory(history))
        DateFormat('yyyy-MM-dd').format(a.date): a,
    };
    final now = DateTime.now();
    return List.generate(days, (i) {
      final d = DateTime(now.year, now.month, now.day - (days - 1 - i));
      return byDay[DateFormat('yyyy-MM-dd').format(d)] ??
          DailyHemoglobinAggregate.empty(d);
    });
  }
}
