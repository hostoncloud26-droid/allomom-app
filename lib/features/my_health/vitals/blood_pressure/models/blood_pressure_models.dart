// Ported from AlloConnect lib/features/health_section/vitals/blood_pressure/models/blood_pressure_models.dart.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';

enum BPCategory { normal, elevated, stage1, stage2, crisis }

extension BPCategoryExtension on BPCategory {
  String get label {
    switch (this) {
      case BPCategory.normal:
        return 'Normal';
      case BPCategory.elevated:
        return 'Elevated';
      case BPCategory.stage1:
        return 'Hypertension Stage 1';
      case BPCategory.stage2:
        return 'Hypertension Stage 2';
      case BPCategory.crisis:
        return 'Hypertensive Crisis';
    }
  }

  Color get color {
    switch (this) {
      case BPCategory.normal:
        return const Color(0xFF00E676); // Green
      case BPCategory.elevated:
        return const Color(0xFFFFD600); // Yellow/Amber
      case BPCategory.stage1:
        return const Color(0xFFFF9100); // Orange
      case BPCategory.stage2:
        return const Color(0xFFFF5252); // Red
      case BPCategory.crisis:
        return const Color(0xFFD50000); // Dark Red
    }
  }
}

class BloodPressureEntry {
  final DateTime timestamp;
  final int systolic;
  final int diastolic;
  final int? pulse;

  BloodPressureEntry({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    this.pulse,
  });

  BPCategory get category {
    if (systolic >= 180 || diastolic >= 120) return BPCategory.crisis;
    if (systolic >= 140 || diastolic >= 90) return BPCategory.stage2;
    if (systolic >= 130 || diastolic >= 80) return BPCategory.stage1;
    if (systolic >= 120 && diastolic < 80) return BPCategory.elevated;
    return BPCategory.normal;
  }

  factory BloodPressureEntry.fromVital(VitalsStreamResponse vital) {
    final data = vital.data;
    return BloodPressureEntry(
      timestamp: vital.createdAt,
      systolic: _asInt(data?['systolic']) ?? vital.value.toInt(),
      diastolic: _asInt(data?['diastolic']) ?? 80,
      pulse: _asInt(data?['pulse']),
    );
  }

  // Allomom rows come back from SQLite JSON, so values may be int, double or String.
  static int? _asInt(dynamic v) {
    if (v is num) return v.round();
    if (v is String) return num.tryParse(v)?.round();
    return null;
  }
}

class DailyBloodPressureStats {
  final DateTime date;
  final double avgSystolic;
  final double avgDiastolic;
  final int minSystolic;
  final int maxSystolic;
  final int minDiastolic;
  final int maxDiastolic;
  final double hypertensionPercentage;

  DailyBloodPressureStats({
    required this.date,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.minSystolic,
    required this.maxSystolic,
    required this.minDiastolic,
    required this.maxDiastolic,
    required this.hypertensionPercentage,
  });

  static List<DailyBloodPressureStats> fromHistory(
    List<VitalsStreamResponse> history,
  ) {
    if (history.isEmpty) return [];

    final Map<String, List<BloodPressureEntry>> grouped = {};
    for (var item in history) {
      if (item.key != 'blood_pressure') continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(item.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(BloodPressureEntry.fromVital(item));
    }

    final List<DailyBloodPressureStats> stats = [];
    grouped.forEach((dateKey, entries) {
      if (entries.isNotEmpty) {
        final date = DateTime.parse(dateKey);
        int minSys = entries.first.systolic;
        int maxSys = entries.first.systolic;
        int minDia = entries.first.diastolic;
        int maxDia = entries.first.diastolic;
        double sumSys = 0;
        double sumDia = 0;
        int highCount = 0;

        for (var e in entries) {
          if (e.systolic < minSys) minSys = e.systolic;
          if (e.systolic > maxSys) maxSys = e.systolic;
          if (e.diastolic < minDia) minDia = e.diastolic;
          if (e.diastolic > maxDia) maxDia = e.diastolic;
          sumSys += e.systolic;
          sumDia += e.diastolic;
          if (e.category != BPCategory.normal) highCount++;
        }

        stats.add(
          DailyBloodPressureStats(
            date: date,
            avgSystolic: sumSys / entries.length,
            avgDiastolic: sumDia / entries.length,
            minSystolic: minSys,
            maxSystolic: maxSys,
            minDiastolic: minDia,
            maxDiastolic: maxDia,
            hypertensionPercentage: (highCount / entries.length) * 100,
          ),
        );
      }
    });

    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }
}
