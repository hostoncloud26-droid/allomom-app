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

/// Typical bleed length when she has not told us hers.
const int defaultPeriodDuration = 5;

/// Range the UI lets her pick from.
const int minPeriodDuration = 2;
const int maxPeriodDuration = 10;

/// Days between ovulation and the next period (the luteal phase). Nearly
/// constant across cycle lengths, which is why ovulation is counted back from
/// the next period rather than forward from the last one.
const int lutealPhaseDays = 14;

/// Where in the cycle today falls.
enum CyclePhase {
  /// Bleeding — the first [CyclePrediction.periodDuration] days.
  menstrual,

  /// After the bleed, before the fertile window opens.
  follicular,

  /// The five days before ovulation through the day after it.
  fertile,

  /// After ovulation, waiting for the next period.
  luteal,

  /// The expected period has not arrived.
  late,
}

extension CyclePhaseLabel on CyclePhase {
  /// Short name for the phase badge.
  String get label => switch (this) {
    CyclePhase.menstrual => 'Menstrual phase',
    CyclePhase.follicular => 'Follicular phase',
    CyclePhase.fertile => 'Fertile window',
    CyclePhase.luteal => 'Luteal phase',
    CyclePhase.late => 'Period overdue',
  };

  /// One line describing what the body is doing, written for the mother.
  String get summary => switch (this) {
    CyclePhase.menstrual =>
      'Your period is here. Rest when you need to and keep your iron and '
          'fluids up.',
    CyclePhase.follicular =>
      'Your body is building up to ovulation. Energy and mood usually pick up '
          'through these days.',
    CyclePhase.fertile =>
      'These are your most fertile days — the best time to conceive if you '
          'are planning a baby.',
    CyclePhase.luteal =>
      'Ovulation has passed. Cramps, tender breasts and mood dips are common '
          'before your period.',
    CyclePhase.late =>
      'Your period has not arrived yet. A few days either way is normal, but '
          'a test is worth taking if you could be pregnant.',
  };
}

/// Phase-specific care advice.
///
/// Kept beside the phase itself rather than in the widget so the screen and
/// any future voice prompt say the same thing.
extension CyclePhaseGuidance on CyclePhase {
  /// What helps during this phase.
  List<String> get dos => switch (this) {
    CyclePhase.menstrual => const [
      'Iron-rich food — greens, dates, jaggery',
      'Warm compress for cramps',
      'Drink plenty of water and rest',
    ],
    CyclePhase.follicular => const [
      'Good days for exercise and new plans',
      'Protein and fresh fruit',
      'Note any changes you feel',
    ],
    CyclePhase.fertile => const [
      'Track the signs — cervical mucus, temperature',
      'Folic acid daily if you are planning a baby',
      'Keep sleep and stress in check',
    ],
    CyclePhase.luteal => const [
      'Magnesium-rich food for cramps and mood',
      'Gentle movement — walking, stretching',
      'Cut back on caffeine and salt',
    ],
    CyclePhase.late => const [
      'Take a home pregnancy test if you could be pregnant',
      'Log the period as soon as it starts',
      'Note any stress, illness or travel — all can delay it',
    ],
  };

  /// What to go easy on.
  List<String> get donts => switch (this) {
    CyclePhase.menstrual => const [
      'Skipping meals or going without iron',
      'Heavy lifting if the cramps are bad',
    ],
    CyclePhase.follicular => const [
      'Ignoring unusual bleeding between periods',
    ],
    CyclePhase.fertile => const [
      'Smoking or alcohol while trying to conceive',
      'Medicines not cleared by your doctor',
    ],
    CyclePhase.luteal => const [
      'Too much sugar — it worsens mood swings',
      'Blaming every symptom on PMS if it feels severe',
    ],
    CyclePhase.late => const [
      'Waiting weeks before asking a doctor',
      'Assuming it is nothing if you also have pain or fever',
    ],
  };
}

/// A predicted cycle.
class CyclePrediction {
  const CyclePrediction({
    required this.lastPeriodStart,
    required this.cycleLength,
    required this.periodDuration,
    required this.today,
    required this.currentPeriodStart,
    required this.nextPeriodStart,
    required this.ovulationDate,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.cycleDay,
    required this.daysUntilNextPeriod,
    required this.daysLate,
  });

  final DateTime lastPeriodStart;
  final int cycleLength;

  /// How many days she bleeds for, used to mark the menstrual phase.
  final int periodDuration;

  /// The day the prediction was made for.
  final DateTime today;

  /// Start of the cycle [today] falls in — the LMP rolled forward by whole
  /// cycles. Equal to [lastPeriodStart] until a cycle has elapsed.
  final DateTime currentPeriodStart;

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

  /// Days past the period expected from the *recorded* LMP, before any
  /// rolling forward; 0 when it is not yet due.
  ///
  /// Read it through [isLate] / [isStale] rather than directly: a months-old
  /// LMP produces a large number that means "she stopped logging", not that
  /// she is a hundred days late.
  final int daysLate;

  /// Last day of the current bleed.
  DateTime get currentPeriodEnd =>
      currentPeriodStart.add(Duration(days: periodDuration - 1));

  /// Overdue, but by little enough that it is still this cycle.
  bool get isLate => daysLate > 0 && daysLate <= cycleLength;

  /// The LMP is more than a cycle out of date, so she almost certainly has
  /// not logged her last period. Predictions should be shown as stale and she
  /// should be asked to log rather than told she is months overdue.
  bool get isStale => daysLate > cycleLength;

  /// Where [today] sits in the cycle.
  CyclePhase get phase {
    if (isLate) return CyclePhase.late;
    if (cycleDay <= periodDuration) return CyclePhase.menstrual;
    if (isFertile(today)) return CyclePhase.fertile;
    return today.isBefore(fertileWindowStart)
        ? CyclePhase.follicular
        : CyclePhase.luteal;
  }

  /// Whether [day] falls inside the fertile window.
  bool isFertile(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(fertileWindowStart) && !d.isAfter(fertileWindowEnd);
  }

  /// Whether [day] falls inside the current bleed.
  bool isPeriodDay(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(currentPeriodStart) && !d.isAfter(currentPeriodEnd);
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
  int periodDuration = defaultPeriodDuration,
  DateTime? today,
}) {
  final length = cycleLength.clamp(minCycleLength, maxCycleLength);
  final bleed = periodDuration.clamp(minPeriodDuration, maxPeriodDuration);
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

  // Lateness is measured against the period the *recorded* LMP predicts, not
  // the rolled-forward one, which by construction is never in the past.
  final expectedFromLmp = lmp.add(Duration(days: length));

  return CyclePrediction(
    lastPeriodStart: lmp,
    cycleLength: length,
    periodDuration: bleed,
    today: now,
    currentPeriodStart: currentCycleStart,
    nextPeriodStart: next,
    ovulationDate: ovulation,
    fertileWindowStart: ovulation.subtract(const Duration(days: 5)),
    fertileWindowEnd: ovulation.add(const Duration(days: 1)),
    // Before the first predicted cycle starts we are still in cycle day
    // (days since LMP) + 1; clamp so the value is always at least 1.
    cycleDay: daysSinceCycleStart < 0 ? 1 : daysSinceCycleStart + 1,
    daysUntilNextPeriod: next.difference(now).inDays.clamp(0, 1 << 31),
    daysLate: now.difference(expectedFromLmp).inDays.clamp(0, 1 << 31),
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

/// Her average cycle length measured from [periodStarts] (most recent first),
/// or null when there are not yet two logged periods to measure between.
///
/// Gaps outside [minCycleLength]–[maxCycleLength] are dropped: they are far
/// more likely to be a missed log than a real 60-day cycle.
int? observedCycleLength(List<DateTime> periodStarts) {
  final sorted = [for (final d in periodStarts) _dateOnly(d)]
    ..sort((a, b) => b.compareTo(a));

  final gaps = <int>[];
  for (var i = 0; i + 1 < sorted.length; i++) {
    final gap = sorted[i].difference(sorted[i + 1]).inDays;
    if (gap >= minCycleLength && gap <= maxCycleLength) gaps.add(gap);
  }
  if (gaps.isEmpty) return null;

  return (gaps.reduce((a, b) => a + b) / gaps.length).round();
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
