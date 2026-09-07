/// Menstrual cycle predictions for mothers who are **not** pregnant.
///
/// Pre-pregnancy (planning) and new-mom users have no due date, so instead of
/// an EDD their LMP is used to work out when the next period is expected and
/// — for someone trying to conceive — when they are most fertile.
///
/// Pure functions with no I/O so the arithmetic can be tested directly.
library;

/// Typical cycle length when the mother has not told us hers.
const int defaultCycleLength = 28;

/// Range the UI lets her pick from.
const int minCycleLength = 21;
const int maxCycleLength = 35;

/// Days between ovulation and the next period (the luteal phase). Nearly
/// constant across cycle lengths, which is why ovulation is counted back from
/// the next period rather than forward from the last one.
const int lutealPhaseDays = 14;

/// A predicted cycle.
class CyclePrediction {
  const CyclePrediction({
    required this.lastPeriodStart,
    required this.cycleLength,
    required this.nextPeriodStart,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.cycleDay,
    required this.daysUntilNextPeriod,
  });

  final DateTime lastPeriodStart;
  final int cycleLength;

  /// Start of the next expected period.
  final DateTime nextPeriodStart;

  /// Estimated ovulation day.
  final DateTime ovulationDate;

  /// Fertile window — five days before ovulation through the day after, which
  /// is roughly how long sperm survive plus the egg's viability.
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;

  /// Day of the current cycle, 1-based.
  final int cycleDay;

  /// Days from today until [nextPeriodStart]; 0 when it is due today.
  final int daysUntilNextPeriod;

  /// Whether [day] falls inside the fertile window.
  bool isFertile(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(fertileWindowStart) && !d.isAfter(fertileWindowEnd);
  }
}

/// Predicts the cycle following [lastPeriodStart].
///
/// [cycleLength] is clamped to [minCycleLength]–[maxCycleLength]. The next
/// period rolls forward in whole cycles until it is in the future, so a months-
/// old LMP still predicts a useful date rather than one in the past.
CyclePrediction predictCycle({
  required DateTime lastPeriodStart,
  int cycleLength = defaultCycleLength,
  DateTime? today,
}) {
  final length = cycleLength.clamp(minCycleLength, maxCycleLength);
  final lmp = _dateOnly(lastPeriodStart);
  final now = _dateOnly(today ?? DateTime.now());

  // Roll forward whole cycles until the next period is today or later.
  var next = lmp.add(Duration(days: length));
  var cyclesElapsed = 0;
  while (next.isBefore(now)) {
    next = next.add(Duration(days: length));
    cyclesElapsed++;
  }

  final currentCycleStart = lmp.add(Duration(days: length * cyclesElapsed));
  final daysSinceCycleStart = now.difference(currentCycleStart).inDays;

  final ovulation = next.subtract(const Duration(days: lutealPhaseDays));

  return CyclePrediction(
    lastPeriodStart: lmp,
    cycleLength: length,
    nextPeriodStart: next,
    ovulationDate: ovulation,
    fertileWindowStart: ovulation.subtract(const Duration(days: 5)),
    fertileWindowEnd: ovulation.add(const Duration(days: 1)),
    // Before the first predicted cycle starts we are still in cycle day
    // (days since LMP) + 1; clamp so the value is always at least 1.
    cycleDay: daysSinceCycleStart < 0 ? 1 : daysSinceCycleStart + 1,
    daysUntilNextPeriod: next.difference(now).inDays.clamp(0, 1 << 31),
  );
}

/// The next [count] expected period start dates, beginning with the soonest.
List<DateTime> upcomingPeriodDates({
  required DateTime lastPeriodStart,
  int cycleLength = defaultCycleLength,
  int count = 3,
  DateTime? today,
}) {
  final prediction = predictCycle(
    lastPeriodStart: lastPeriodStart,
    cycleLength: cycleLength,
    today: today,
  );
  return [
    for (var i = 0; i < count; i++)
      prediction.nextPeriodStart.add(
        Duration(days: prediction.cycleLength * i),
      ),
  ];
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
