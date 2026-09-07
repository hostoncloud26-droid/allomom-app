/// The live user state AlloBot grounds its answers in — the "A" in RAG.
///
/// Pure data plus date arithmetic, deliberately free of Flutter, GetX and
/// SQLite so the phrasing rules (which ANC line to speak, how to describe
/// gestational age, when a vital is stale) can be unit tested directly.
/// `AlloBotContextLoader` is the impure half that fills this in.
library;

/// A scheduled antenatal-care visit, flattened out of the drift row.
class AncVisitContext {
  const AncVisitContext({
    this.id = '',
    required this.visitNumber,
    required this.scheduledDate,
    required this.status,
    this.pregnancyMonth,
    this.trimester,
    this.actualDate,
    this.bp,
    this.weightKg,
    this.fetalHeartRate,
    this.notes,
  });

  /// Row id, so an answer can be written back to this visit. Empty for a
  /// hand-built context in a test.
  final String id;

  final int visitNumber;
  final DateTime scheduledDate;

  /// `pending`, `done` or `missed`.
  final String status;

  final int? pregnancyMonth;
  final int? trimester;
  final DateTime? actualDate;
  final String? bp;
  final double? weightKg;
  final int? fetalHeartRate;
  final String? notes;

  bool get isDone => status.toLowerCase() == 'done';
  bool get isMissed => status.toLowerCase() == 'missed';
  bool get isPending => !isDone && !isMissed;

  /// Whole days from [from] to the scheduled date; negative once it is past.
  int daysFrom(DateTime from) =>
      _dateOnly(scheduledDate).difference(_dateOnly(from)).inDays;
}

/// A maternal vaccine dose from the schedule.
class VaccineContext {
  const VaccineContext({
    this.id = '',
    required this.name,
    required this.doseNumber,
    required this.scheduledDate,
    required this.status,
    this.pregnancyMonth,
  });

  /// Row id, so a dose can be marked given.
  final String id;

  final String name;
  final int doseNumber;
  final DateTime scheduledDate;
  final String status;
  final int? pregnancyMonth;

  bool get isDone => status.toLowerCase() == 'done';

  int daysFrom(DateTime from) =>
      _dateOnly(scheduledDate).difference(_dateOnly(from)).inDays;
}

/// A lab test, scan or report still on her checklist.
class LabReportContext {
  const LabReportContext({
    required this.name,
    required this.status,
    this.category,
    this.pregnancyMonth,
    this.dueDate,
    this.completedDate,
    this.isRequired = true,
    this.resultSummary,
  });

  final String name;
  final String status;
  final String? category;
  final int? pregnancyMonth;
  final DateTime? dueDate;
  final DateTime? completedDate;

  /// False for tests a doctor orders only when indicated, which should not be
  /// chased the way a routine one is.
  final bool isRequired;

  final String? resultSummary;

  bool get isDone => status.toLowerCase() == 'done' || completedDate != null;
  bool get isPending => !isDone && status.toLowerCase() != 'missed';

  int? daysFrom(DateTime from) {
    final due = dueDate;
    if (due == null) return null;
    return _dateOnly(due).difference(_dateOnly(from)).inDays;
  }
}

/// One reading off the vitals stream.
class VitalContext {
  const VitalContext({
    required this.key,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  final String key;
  final double value;
  final String unit;
  final DateTime recordedAt;

  bool isFromToday(DateTime now) =>
      _dateOnly(recordedAt) == _dateOnly(now);

  /// Trimmed number: 8 rather than 8.0, but 62.5 kept.
  String get displayValue => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

/// One row of Today's Care, reduced to what the bot needs to talk about it.
class TodayCareContext {
  const TodayCareContext({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dayPartLabel,
    this.target,
    this.loggedToday,
    this.unit = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String dayPartLabel;
  final int? target;
  final double? loggedToday;
  final String unit;

  bool get isComplete =>
      target != null && loggedToday != null && loggedToday! >= target!;

  /// How much of the day's target is still outstanding, or null when the item
  /// has no numeric target.
  double? get remaining {
    final goal = target;
    if (goal == null) return null;
    final done = loggedToday ?? 0;
    final left = goal - done;
    return left <= 0 ? 0 : left;
  }
}

/// Everything AlloBot knows about the mother at the moment she asks.
class AlloBotContext {
  const AlloBotContext({
    required this.motherName,
    required this.isPregnant,
    required this.isNewMom,
    required this.pregnancyDay,
    required this.gestationalWeek,
    required this.daysLeftUntilEdd,
    required this.now,
    required this.dayPartLabel,
    required this.greetingWord,
    required this.dayPartHeadline,
    this.lmpDate,
    this.eddDate,
    this.formattedEdd = '',
    this.riskStatus = '',
    this.bloodGroup,
    this.heightCm,
    this.weightKg,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.flaggedComplications = const [],
    this.ancVisits = const [],
    this.vaccines = const [],
    this.labReports = const [],
    this.latestVitals = const {},
    this.todayTotals = const {},
    this.todayCare = const [],
    this.kidsCount = 0,
    this.completedPregnancyCount = 0,
  });

  final String motherName;
  final bool isPregnant;
  final bool isNewMom;

  /// Days since LMP.
  final int pregnancyDay;
  final int gestationalWeek;
  final int daysLeftUntilEdd;

  /// Injected rather than read from the clock so tests are deterministic.
  final DateTime now;

  final String dayPartLabel;
  final String greetingWord;
  final String dayPartHeadline;

  final DateTime? lmpDate;
  final DateTime? eddDate;
  final String formattedEdd;
  final String riskStatus;

  final String? bloodGroup;
  final double? heightCm;
  final double? weightKg;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> flaggedComplications;

  final List<AncVisitContext> ancVisits;
  final List<VaccineContext> vaccines;
  final List<LabReportContext> labReports;
  /// Latest reading per vital key, across all time. Right for measurements
  /// like weight and blood pressure.
  final Map<String, VitalContext> latestVitals;

  /// Today's running total per vital key.
  ///
  /// Vitals rows hold *increments*, never running totals — the care sheets
  /// write "2 more glasses", not "6 glasses so far" — so anything cumulative
  /// has to be summed over the day. Reading the latest row instead would
  /// report the last sip as the whole day's intake.
  final Map<String, double> todayTotals;

  final List<TodayCareContext> todayCare;

  final int kidsCount;
  final int completedPregnancyCount;

  /// A neutral fallback used before the real context loads, so the chat can
  /// open and greet immediately instead of waiting on the database.
  static AlloBotContext placeholder({DateTime? now}) {
    final at = now ?? DateTime.now();
    return AlloBotContext(
      motherName: 'Amma',
      isPregnant: true,
      isNewMom: false,
      pregnancyDay: 0,
      gestationalWeek: 0,
      daysLeftUntilEdd: 0,
      now: at,
      dayPartLabel: 'Today',
      greetingWord: 'Hello',
      dayPartHeadline: '',
    );
  }

  /// Day of the week within the current gestational week (1–7).
  int get dayWithinWeek => pregnancyDay <= 0 ? 0 : (pregnancyDay % 7) + 1;

  int get trimesterNumber {
    if (gestationalWeek <= 12) return 1;
    if (gestationalWeek <= 26) return 2;
    return 3;
  }

  String get trimesterLabel => switch (trimesterNumber) {
        1 => '1st trimester',
        2 => '2nd trimester',
        _ => '3rd trimester',
      };

  /// Pregnancy month completed, matching the ANC schedule's month numbering.
  int get pregnancyMonth =>
      pregnancyDay <= 0 ? 0 : ((pregnancyDay / 30.44).floor()).clamp(0, 10);

  bool get hasGestationalAge => isPregnant && gestationalWeek > 0;

  /// The soonest ANC visit still outstanding, overdue ones included — those
  /// matter more than the next future one, so they sort first.
  AncVisitContext? get nextAncVisit {
    final pending = ancVisits.where((visit) => visit.isPending).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    if (pending.isEmpty) return null;

    final overdue = pending.where((visit) => visit.daysFrom(now) < 0).toList();
    if (overdue.isNotEmpty) return overdue.last;
    return pending.first;
  }

  /// The most recent completed visit, for "at your last check-up…" lines.
  AncVisitContext? get lastCompletedAncVisit {
    final done = ancVisits.where((visit) => visit.isDone).toList()
      ..sort((a, b) => (a.actualDate ?? a.scheduledDate)
          .compareTo(b.actualDate ?? b.scheduledDate));
    return done.isEmpty ? null : done.last;
  }

  int get pendingAncCount => ancVisits.where((visit) => visit.isPending).length;

  /// The visit scheduled for today, whatever its status.
  ///
  /// This is the one the post-visit questions belong to — the doctor's notes
  /// and the vaccine go against today's appointment, not against the next one.
  AncVisitContext? get ancVisitToday {
    for (final visit in ancVisits) {
      if (visit.daysFrom(now) == 0) return visit;
    }
    return null;
  }

  int get missedAncCount => ancVisits.where((visit) => visit.isMissed).length;

  /// Days until the next outstanding ANC visit; negative when overdue.
  int? get daysUntilNextAnc => nextAncVisit?.daysFrom(now);

  /// True when the ANC visit is close enough that AlloBot should lead with it
  /// rather than wait to be asked.
  bool get shouldLeadWithAnc {
    final days = daysUntilNextAnc;
    return days != null && days <= 3;
  }

  VaccineContext? get nextVaccine {
    final pending = vaccines.where((dose) => !dose.isDone).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return pending.isEmpty ? null : pending.first;
  }

  /// The routine lab test due soonest, overdue ones first.
  ///
  /// Only required tests: the optional ones are ordered by a doctor when
  /// indicated, so chasing them would be telling her to get tests nobody asked
  /// for.
  LabReportContext? get nextLabReport {
    final pending = labReports
        .where((report) => report.isPending && report.isRequired)
        .toList()
      ..sort((a, b) {
        final aDue = a.dueDate;
        final bDue = b.dueDate;
        if (aDue == null && bDue == null) return 0;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });
    if (pending.isEmpty) return null;

    final overdue = pending.where((report) {
      final days = report.daysFrom(now);
      return days != null && days < 0;
    }).toList();
    if (overdue.isNotEmpty) return overdue.last;
    return pending.first;
  }

  int get pendingLabReportCount =>
      labReports.where((r) => r.isPending && r.isRequired).length;

  /// Lab tests already done, most recent first, for "my last results" answers.
  List<LabReportContext> get completedLabReports {
    final done = labReports.where((report) => report.isDone).toList()
      ..sort((a, b) => (b.completedDate ?? b.dueDate ?? now)
          .compareTo(a.completedDate ?? a.dueDate ?? now));
    return done;
  }

  VitalContext? vital(String key) => latestVitals[key];

  /// How many days ago [key] was last recorded, or null if never.
  int? daysSinceVital(String key) {
    final reading = latestVitals[key];
    if (reading == null) return null;
    return _dateOnly(now).difference(_dateOnly(reading.recordedAt)).inDays;
  }

  /// Days since the most recent reading under any of [keys], or null when none
  /// of them has ever been recorded.
  ///
  /// Takes a list because one measure goes by several keys — blood pressure is
  /// written as `blood_pressure` in some places and `bp` in others. Checking
  /// them one at a time makes a measure look unrecorded whenever the *other*
  /// spelling is the one in use.
  int? daysSinceAnyVital(List<String> keys) {
    int? best;
    for (final key in keys) {
      final since = daysSinceVital(key);
      if (since == null) continue;
      if (best == null || since < best) best = since;
    }
    return best;
  }

  /// Whether [keys] has no reading at all, or none newer than
  /// [staleAfterDays].
  ///
  /// Drives the questions AlloBot asks off the vitals stream: a blood pressure
  /// last taken five weeks ago is not a current reading, and asking about it is
  /// more use than quoting it as if it were.
  bool isVitalStale(List<String> keys, {int staleAfterDays = 28}) {
    final since = daysSinceAnyVital(keys);
    return since == null || since > staleAfterDays;
  }

  /// Today's summed total for [key], or null when nothing was logged today.
  ///
  /// Use this for anything cumulative (water, kicks, steps); use [vital] for
  /// point-in-time measurements.
  double? totalToday(String key) {
    final total = todayTotals[key];
    if (total == null || total <= 0) return null;
    return total;
  }

  bool get isHighRisk {
    final status = riskStatus.toLowerCase();
    return status.contains('high') || flaggedComplications.isNotEmpty;
  }

  List<TodayCareContext> get outstandingCare =>
      todayCare.where((item) => !item.isComplete).toList();
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Renders a signed day offset as something a person would say.
///
/// Used for both ANC visits and vaccine doses, which is why it lives here
/// rather than on either class.
String describeDayOffset(int days) {
  if (days == 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days == -1) return 'yesterday';
  if (days < 0) return '${-days} days ago';
  if (days < 7) return 'in $days days';
  if (days < 14) return 'in about a week';
  final weeks = (days / 7).round();
  if (days < 60) return 'in about $weeks weeks';
  return 'in about ${(days / 30.44).round()} months';
}

/// Formats a date the way the rest of the app does ("14 Mar").
String formatShortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
