import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';

enum BodyCompositionDateFilter { daily, weekly, monthly, allTime }

extension BodyCompositionDateFilterX on BodyCompositionDateFilter {
  String get label {
    switch (this) {
      case BodyCompositionDateFilter.daily:
        return 'Daily';
      case BodyCompositionDateFilter.weekly:
        return 'Weekly';
      case BodyCompositionDateFilter.monthly:
        return 'Monthly';
      case BodyCompositionDateFilter.allTime:
        return 'All Time';
    }
  }

  DateTime? rangeStart(DateTime now) {
    switch (this) {
      case BodyCompositionDateFilter.daily:
        return DateTime(now.year, now.month, now.day);
      case BodyCompositionDateFilter.weekly:
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
      case BodyCompositionDateFilter.monthly:
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
      case BodyCompositionDateFilter.allTime:
        return null;
    }
  }

  int get expectedPoints {
    switch (this) {
      case BodyCompositionDateFilter.daily:
        return 1;
      case BodyCompositionDateFilter.weekly:
        return 7;
      case BodyCompositionDateFilter.monthly:
        return 30;
      case BodyCompositionDateFilter.allTime:
        return 0;
    }
  }

  String formatAxisLabel(DateTime date) {
    switch (this) {
      case BodyCompositionDateFilter.daily:
        return DateFormat('hh:mm a').format(date);
      case BodyCompositionDateFilter.weekly:
        return DateFormat('E, dd').format(date);
      case BodyCompositionDateFilter.monthly:
        return DateFormat('dd MMM').format(date);
      case BodyCompositionDateFilter.allTime:
        return DateFormat('dd MMM').format(date);
    }
  }
}

class BodyCompositionAggregate {
  final DateTime date;
  final double? height;
  final double? weight;

  const BodyCompositionAggregate({
    required this.date,
    this.height,
    this.weight,
  });

  double? get bmi {
    final currentHeight = height;
    final currentWeight = weight;
    if (currentHeight == null ||
        currentWeight == null ||
        currentHeight <= 0 ||
        currentWeight <= 0) {
      return null;
    }

    final heightInMeters = currentHeight / 100;
    return currentWeight / (heightInMeters * heightInMeters);
  }
}

class BodyCompositionSummary {
  final double? latest;
  final double? minimum;
  final double? maximum;
  final double? change;

  const BodyCompositionSummary({
    this.latest,
    this.minimum,
    this.maximum,
    this.change,
  });

  bool get hasData => latest != null;
}

class BodyCompositionModels {
  static List<BodyCompositionAggregate> mergeHistory({
    required List<VitalsStreamResponse> heightHistory,
    required List<VitalsStreamResponse> weightHistory,
  }) {
    final Map<String, BodyCompositionAggregate> grouped = {};

    void absorb(List<VitalsStreamResponse> history, bool isHeight) {
      for (final item in history) {
        final localDate = item.createdAt.toLocal();
        final day = DateTime(localDate.year, localDate.month, localDate.day);
        final key = DateFormat('yyyy-MM-dd').format(day);
        final current = grouped[key];

        grouped[key] = BodyCompositionAggregate(
          date: day,
          height: isHeight ? item.value : current?.height,
          weight: isHeight ? current?.weight : item.value,
        );
      }
    }

    final sortedHeight = List<VitalsStreamResponse>.from(heightHistory)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final sortedWeight = List<VitalsStreamResponse>.from(weightHistory)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    absorb(sortedHeight, true);
    absorb(sortedWeight, false);

    final results = grouped.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  static List<BodyCompositionAggregate> fillRange(
    List<BodyCompositionAggregate> history,
    BodyCompositionDateFilter filter, {
    double? fallbackHeight,
    double? fallbackWeight,
  }) {
    final now = DateTime.now();
    final start =
        filter.rangeStart(now) ??
        (history.isNotEmpty ? history.first.date : now);
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedNow = DateTime(now.year, now.month, now.day);

    final Map<String, BodyCompositionAggregate> byDay = {
      for (final item in history)
        DateFormat('yyyy-MM-dd').format(item.date): item,
    };

    double? rollingHeight;
    double? rollingWeight;
    final output = <BodyCompositionAggregate>[];

    for (
      int i = 0;
      i <= normalizedNow.difference(normalizedStart).inDays;
      i++
    ) {
      final day = normalizedStart.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final existing = byDay[key];
      if (existing != null) {
        rollingHeight = existing.height ?? rollingHeight;
        rollingWeight = existing.weight ?? rollingWeight;
      }

      output.add(
        BodyCompositionAggregate(
          date: day,
          height: existing?.height ?? rollingHeight ?? fallbackHeight,
          weight: existing?.weight ?? rollingWeight ?? fallbackWeight,
        ),
      );
    }

    return output;
  }

  static BodyCompositionSummary summarize(
    List<double> values, {
    double? fallbackLatest,
  }) {
    final clean = values.where((v) => v > 0).toList();
    if (clean.isEmpty) {
      return BodyCompositionSummary(latest: fallbackLatest);
    }

    clean.sort();
    final latest = values.isNotEmpty ? values.last : clean.last;
    return BodyCompositionSummary(
      latest: latest > 0 ? latest : clean.last,
      minimum: clean.first,
      maximum: clean.last,
      change: values.length >= 2 ? values.last - values.first : 0,
    );
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'High BMI';
  }
}
