/// Period tracking, the same way AlloConnect's menstruation tracker does it.
///
/// Each period is one `lmp_date` reading in the vitals stream whose `data`
/// blob is shared with AlloConnect:
///
/// ```json
/// {
///   "lmp_date": "2026-09-21T00:00:00.000",
///   "period_end_date": "2026-09-25T00:00:00.000",
///   "period_duration": 5,
///   "average_cycle": 28.0,
///   "status": "on_period" | "not_on_period"
/// }
/// ```
///
/// Logging a period adds a row with `status: on_period`; marking it ended and
/// editing it rewrite that same row, so one period is always one reading.
///
/// Pure functions with no I/O so the arithmetic can be tested directly.
library;

import 'package:allomom/services/cycle_predictor.dart' show CyclePhase;

/// Status values written to `data.status`, as AlloConnect writes them.
class PeriodStatus {
  const PeriodStatus._();

  static const onPeriod = 'on_period';
  static const notOnPeriod = 'not_on_period';
}

/// Defaults AlloConnect writes when she has not said otherwise.
const int trackerDefaultCycle = 28;
const int trackerDefaultDuration = 5;

/// Ranges the edit sheet lets her pick from, matching AlloConnect's sliders.
const int trackerMinDuration = 1;
const int trackerMaxDuration = 15;
const int trackerMinCycle = 20;
const int trackerMaxCycle = 45;

/// One logged period.
class PeriodLog {
  const PeriodLog({
    required this.id,
    required this.start,
    required this.end,
    required this.periodDuration,
    required this.averageCycle,
    required this.status,
    required this.createdAt,
    this.data = const {},
  });

  /// The vitals row this came from, or null when it was derived from the LMP
  /// on her profile and has not been logged as a period yet.
  final String? id;

  /// First day of the period (`data.lmp_date`).
  final DateTime start;

  /// Last day (`data.period_end_date`), null until one is known.
  final DateTime? end;

  final int periodDuration;
  final int averageCycle;
  final String status;

  /// When the row was written — the tie-break between two logs of one day.
  final DateTime createdAt;

  /// The raw blob, kept so an update preserves fields this app does not know.
  final Map<String, dynamic> data;

  bool get isOngoing => status == PeriodStatus.onPeriod;

  /// Whether this is a saved reading rather than one derived from the LMP.
  bool get isStored => id != null;

  /// Parses a reading's `data`; null when it carries no usable `lmp_date`,
  /// the same entries AlloConnect skips (mood or symptom logs, say).
  static PeriodLog? fromData({
    required String? id,
    required DateTime createdAt,
    required Map<String, dynamic> data,
  }) {
    final start = parseDay(data['lmp_date']);
    if (start == null) return null;
    final duration = _asInt(data['period_duration']) ?? trackerDefaultDuration;
    final cycle = _asInt(data['average_cycle']) ?? trackerDefaultCycle;
    return PeriodLog(
      id: id,
      start: start,
      end: parseDay(data['period_end_date']),
      periodDuration: duration < 1 ? trackerDefaultDuration : duration,
      averageCycle: cycle <= 0 ? trackerDefaultCycle : cycle,
      status: data['status']?.toString() ?? PeriodStatus.notOnPeriod,
      createdAt: createdAt,
      data: data,
    );
  }

  /// The `data` blob for a new period.
  static Map<String, dynamic> newData({
    required DateTime start,
    required String status,
    required int periodDuration,
    required int averageCycle,
    DateTime? end,
    bool onboarding = false,
  }) => {
    'lmp_date': isoDay(start),
    if (end != null) 'period_end_date': isoDay(end),
    'period_duration': periodDuration,
    'average_cycle': averageCycle.toDouble(),
    'status': status,
    if (onboarding) 'onboarding': true,
  };

  /// This period marked as ended on [endDay]; the duration follows from it.
  Map<String, dynamic> endedData(DateTime endDay) {
    final endDate = dateOnly(endDay);
    return {
      ...data,
      'period_end_date': isoDay(endDate),
      'status': PeriodStatus.notOnPeriod,
      'period_duration': daysBetween(start, endDate) + 1,
    };
  }

  /// This period with its start, length or cycle corrected. The end date is
  /// recomputed from the new length, as AlloConnect's edit sheet does.
  Map<String, dynamic> editedData({
    required DateTime start,
    required int periodDuration,
    required int averageCycle,
  }) {
    final startDay = dateOnly(start);
    return {
      ...data,
      'lmp_date': isoDay(startDay),
      'period_duration': periodDuration,
      'average_cycle': averageCycle.toDouble(),
      'period_end_date': isoDay(addDays(startDay, periodDuration - 1)),
    };
  }

  /// Days bled so far while ongoing, otherwise the recorded length.
  int daysSoFar(DateTime today) => isOngoing
      ? daysBetween(start, dateOnly(today)) + 1
      : (end != null ? daysBetween(start, end!) + 1 : periodDuration);

  /// End date for display: the recorded one, or start + duration when the
  /// period is over but no end was written.
  DateTime? get displayEnd =>
      isOngoing ? null : (end ?? addDays(start, periodDuration - 1));
}

/// Where she is today, worked out from her latest logged period exactly as
/// AlloConnect's overview does: no rolling forward — a period that has not
/// come is reported as late, counted from the logged start.
class MenstrualStatus {
  MenstrualStatus._({
    required this.latest,
    required this.today,
    required this.cycleDay,
    required this.nextPeriod,
    required this.daysUntilNext,
    required this.ovulationDay,
  });

  factory MenstrualStatus.from(PeriodLog latest, {DateTime? today}) {
    final now = dateOnly(today ?? DateTime.now());
    final lmp = latest.start;
    final cycle = latest.averageCycle;
    final next = addDays(lmp, cycle);
    return MenstrualStatus._(
      latest: latest,
      today: now,
      cycleDay: daysBetween(lmp, now) + 1,
      nextPeriod: next,
      daysUntilNext: daysBetween(now, next),
      // ~day 14 of a 28-day cycle.
      ovulationDay: (cycle / 2).round(),
    );
  }

  final PeriodLog latest;
  final DateTime today;

  /// 1-based day since the logged period started.
  final int cycleDay;

  final DateTime nextPeriod;

  /// Negative once the period is late.
  final int daysUntilNext;

  /// Cycle day of ovulation.
  final int ovulationDay;

  DateTime get lastPeriod => latest.start;
  int get averageCycle => latest.averageCycle;
  int get periodDuration => latest.periodDuration;
  bool get onPeriod => latest.isOngoing;

  int get fertileStartDay => ovulationDay - 3;
  int get fertileEndDay => ovulationDay + 1;

  DateTime get ovulationDate => _dayOfCycle(ovulationDay);
  DateTime get fertileWindowStart => _dayOfCycle(fertileStartDay);
  DateTime get fertileWindowEnd => _dayOfCycle(fertileEndDay);

  bool get isOverdue => !onPeriod && daysUntilNext < 0;
  int get overdueDays => isOverdue ? -daysUntilNext : 0;

  /// Late by more than a whole cycle: she has most likely stopped logging.
  bool get isStale => overdueDays > averageCycle;

  /// Ring fill: how far through the cycle today is.
  double get progress => ((cycleDay - 1) / averageCycle).clamp(0.0, 1.0);

  CyclePhase get phase {
    if (onPeriod) return CyclePhase.menstrual;
    if (isOverdue) return CyclePhase.late;
    if (cycleDay >= fertileStartDay && cycleDay <= fertileEndDay) {
      return CyclePhase.fertile;
    }
    return cycleDay < fertileStartDay
        ? CyclePhase.follicular
        : CyclePhase.luteal;
  }

  /// The line under the ring, worded as AlloConnect words it.
  String get headline {
    if (onPeriod) return 'Currently bleeding';
    if (daysUntilNext > 0) {
      return daysUntilNext == 1
          ? 'Period in 1 day'
          : 'Period in $daysUntilNext days';
    }
    if (daysUntilNext == 0) return 'Period today';
    return overdueDays == 1
        ? 'Period late by 1 day'
        : 'Period late by $overdueDays days';
  }

  /// Last day of the bleed shown on the calendar. While ongoing it runs at
  /// least to today; the predicted length fills in the days still to come.
  DateTime get periodEnd {
    if (onPeriod) {
      final predicted = addDays(lastPeriod, periodDuration - 1);
      return predicted.isBefore(today) ? today : predicted;
    }
    return latest.displayEnd!;
  }

  bool isPeriodDay(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(lastPeriod) && !d.isAfter(periodEnd);
  }

  bool isFertile(DateTime day) {
    final d = dateOnly(day);
    return !d.isBefore(fertileWindowStart) && !d.isAfter(fertileWindowEnd);
  }

  bool isOvulation(DateTime day) => _sameDay(dateOnly(day), ovulationDate);

  /// Every day of this cycle, stretched to today when the period is late so
  /// today is always on the grid.
  List<DateTime> get calendarDays {
    final lastOfCycle = addDays(nextPeriod, -1);
    final last = today.isAfter(lastOfCycle) ? today : lastOfCycle;
    final count = daysBetween(lastPeriod, last) + 1;
    return [for (var i = 0; i < count; i++) addDays(lastPeriod, i)];
  }

  CycleGuidance get guidance => CycleGuidance.forStatus(this);

  DateTime _dayOfCycle(int day) => addDays(lastPeriod, day - 1);
}

/// Day-specific do's and don'ts, carried over from AlloConnect's cycle
/// guidance: each period day, the fertile window, follicular and luteal
/// phases, and three stages of a late period.
class CycleGuidance {
  const CycleGuidance({
    required this.phase,
    required this.title,
    required this.label,
    required this.tip,
    required this.dos,
    required this.donts,
  });

  final CyclePhase phase;

  /// Phase badge, e.g. "Menstrual Phase".
  final String title;

  /// e.g. "Day 2 — Heaviest Flow".
  final String label;
  final String tip;
  final List<String> dos;
  final List<String> donts;

  factory CycleGuidance.forStatus(MenstrualStatus s) {
    final cycleDay = s.cycleDay;
    final phase = s.phase;

    switch (phase) {
      case CyclePhase.menstrual:
        if (cycleDay <= 1) {
          return CycleGuidance(
            phase: phase,
            title: 'Menstrual Phase',
            label: 'Day 1 — Flow Beginning',
            tip:
                'Day 1 can be intense. Your uterine lining is shedding. Focus '
                'on comfort and warmth.',
            dos: const [
              'Drink plenty of warm water & herbal teas',
              'Use a heating pad for cramps',
              'Rest and allow yourself extra sleep',
              'Eat iron-rich foods (spinach, lentils, dates)',
              'Take a warm bath to ease tension',
            ],
            donts: const [
              'Avoid heavy exercise or intense workouts',
              'Avoid cold beverages & iced foods',
              "Don't skip meals — keep energy stable",
              'Avoid excess caffeine (increases cramps)',
              "Don't stress about low productivity today",
            ],
          );
        }
        if (cycleDay == 2) {
          return CycleGuidance(
            phase: phase,
            title: 'Menstrual Phase',
            label: 'Day 2 — Heaviest Flow',
            tip:
                'Flow is usually heaviest today. Focus on iron-rich nutrition '
                'and gentle rest.',
            dos: const [
              'Eat iron-rich foods (leafy greens, beans, lean meat)',
              'Stay hydrated — aim for 8+ glasses of water',
              'Take short, gentle walks if comfortable',
              'Use period-safe pain relief if needed',
              'Track your flow intensity for future reference',
            ],
            donts: const [
              'Avoid sugary snacks (causes energy crashes)',
              "Don't lift heavy weights",
              'Avoid tight clothing around abdomen',
              "Don't consume excess salt (increases bloating)",
              'Avoid staying up late — rest is critical',
            ],
          );
        }
        if (cycleDay == 3) {
          return CycleGuidance(
            phase: phase,
            title: 'Menstrual Phase',
            label: 'Day 3 — Moderate Flow',
            tip:
                'Flow may begin to ease. Light movement can help with '
                'lingering cramps and bloating.',
            dos: const [
              "Gentle yoga or stretching (cat-cow, child's pose)",
              'Continue iron and vitamin C rich foods',
              'Take short walks in fresh air',
              'Practice deep breathing for cramp relief',
              'Keep a mood journal to track patterns',
            ],
            donts: const [
              'Avoid swimming in unclean water',
              "Don't ignore persistent severe pain",
              'Avoid excessive dairy if bloating persists',
              "Don't use harsh chemical products",
              'Avoid skipping hydration',
            ],
          );
        }
        if (cycleDay <= 5) {
          return CycleGuidance(
            phase: phase,
            title: 'Menstrual Phase',
            label: 'Days 4-5 — Flow Lightening',
            tip:
                'Your body is recovering. The flow is easing. Focus on '
                'self-care and gentle nourishment.',
            dos: const [
              'Focus on skin-care and relaxation',
              'Eat balanced meals with protein & complex carbs',
              'Light exercise like walking or pilates',
              'Get quality sleep (7-8 hours)',
              'Start planning for your fertile window',
            ],
            donts: const [
              "Don't start intense diet restrictions",
              'Avoid excessive alcohol consumption',
              "Don't ignore any unusual discharge",
              'Avoid overworking yourself',
              "Don't consume excessive processed foods",
            ],
          );
        }
        return CycleGuidance(
          phase: phase,
          title: 'Menstrual Phase',
          label: 'Day $cycleDay — Extended Period',
          tip:
              'Your period is lasting longer than average. Keep tracking and '
              'consult your doctor if this is unusual for you.',
          dos: const [
            'Continue tracking symptoms carefully',
            'Maintain iron-rich diet',
            'Stay hydrated throughout the day',
            'Consider consulting your OB-GYN if >7 days',
            'Rest when your body signals fatigue',
          ],
          donts: const [
            "Don't ignore periods lasting >7 days",
            'Avoid self-medicating without guidance',
            "Don't dismiss heavy clotting or pain",
            'Avoid stress — practice mindfulness',
            "Don't skip doctor appointments",
          ],
        );

      case CyclePhase.late:
        final overdue = s.overdueDays;
        if (overdue <= 3) {
          return CycleGuidance(
            phase: phase,
            title: 'Period Overdue',
            label: 'Late by $overdue day${overdue == 1 ? '' : 's'}',
            tip:
                'Your period is slightly late. This can be normal due to '
                'stress, diet changes, or hormonal shifts.',
            dos: const [
              'Take a home pregnancy test if sexually active',
              'Track any symptoms like nausea or breast tenderness',
              'Maintain a balanced diet with folic acid',
              'Get adequate sleep and manage stress',
              'Continue taking prenatal vitamins if planning pregnancy',
            ],
            donts: const [
              "Don't panic — slight delays are common",
              'Avoid excessive caffeine and alcohol',
              "Don't start new intense exercise programs",
              'Avoid self-diagnosing — consult a doctor if worried',
              "Don't ignore persistent fatigue or nausea",
            ],
          );
        }
        if (overdue <= 7) {
          return CycleGuidance(
            phase: phase,
            title: 'Period Overdue',
            label: 'Late by $overdue days — 1 Week',
            tip:
                'A week late is significant. If you could be pregnant, test '
                'now. Otherwise, consult your healthcare provider.',
            dos: const [
              'Take a pregnancy test (best with morning urine)',
              'Start folic acid supplements (400mcg daily)',
              'Schedule an appointment with your OB-GYN',
              'Eat folate-rich foods (oranges, broccoli, lentils)',
              'Note any early pregnancy signs (fatigue, nausea, bloating)',
            ],
            donts: const [
              "Don't consume alcohol — you may be pregnant",
              'Avoid raw or undercooked food',
              "Don't take unprescribed medications",
              'Avoid hot tubs and saunas',
              "Don't smoke or be around secondhand smoke",
            ],
          );
        }
        return CycleGuidance(
          phase: phase,
          title: 'Period Overdue',
          label: 'Late by $overdue days',
          tip:
              'Your period is significantly overdue. If pregnancy is possible, '
              'confirm with a test. Consult your doctor for guidance.',
          dos: const [
            'Confirm pregnancy with a test or blood work',
            'Book an OB-GYN appointment immediately',
            'Start prenatal vitamins with DHA & folic acid',
            'Maintain light exercise (walking, prenatal yoga)',
            'Stay well-hydrated and eat balanced meals',
          ],
          donts: const [
            "Don't take any medication without doctor advice",
            'Absolutely avoid alcohol and smoking',
            'Avoid raw fish, unpasteurized dairy & deli meats',
            "Don't lift heavy objects",
            'Avoid high-stress situations',
          ],
        );

      case CyclePhase.fertile:
        return CycleGuidance(
          phase: phase,
          title: 'Fertile Window',
          label: 'Day $cycleDay — Ovulation Period',
          tip:
              'You are in your most fertile days! If planning pregnancy, this '
              'is the optimal time. Your energy levels are typically at their '
              'peak.',
          dos: const [
            'Track ovulation signs (cervical mucus, temp rise)',
            'If planning pregnancy — this is the best time',
            'Eat fertility-boosting foods (avocado, nuts, eggs)',
            'Stay active with moderate exercise',
            'Both partners should avoid alcohol & smoking',
          ],
          donts: const [
            "Don't use lubricants that harm sperm motility",
            'Avoid excessive stress and anxiety',
            "Don't skip meals or crash diet",
            'Avoid excessive heat (saunas, hot baths)',
            "Don't ignore ovulation tracking if trying to conceive",
          ],
        );

      case CyclePhase.follicular:
        final daysToFertile = s.fertileStartDay - cycleDay;
        return CycleGuidance(
          phase: phase,
          title: 'Follicular Phase',
          label: 'Day $cycleDay — Building Up',
          tip:
              'Your body is preparing for ovulation. Estrogen levels are '
              'rising. Energy and mood typically improve during this phase. '
              'Fertile window in ~$daysToFertile days.',
          dos: const [
            'Increase exercise intensity gradually',
            'Eat estrogen-supporting foods (flaxseeds, soy)',
            'Start planning for fertile window if trying to conceive',
            'Focus on strength training — energy is rising',
            'Socialize and take on challenging tasks',
          ],
          donts: const [
            "Don't overexert — build up gradually",
            'Avoid excessive sugar and processed foods',
            "Don't neglect sleep despite higher energy",
            'Avoid unnecessary medications',
            "Don't ignore any irregular symptoms",
          ],
        );

      case CyclePhase.luteal:
        return CycleGuidance(
          phase: phase,
          title: 'Luteal Phase',
          label: 'Day $cycleDay — Pre-Menstrual',
          tip:
              'Progesterone is dominant. You may experience PMS symptoms. '
              'Focus on comfort, magnesium-rich foods, and stress management. '
              'Next period in ~${s.daysUntilNext} days.',
          dos: const [
            'Eat magnesium-rich foods (dark chocolate, almonds, bananas)',
            'Practice yoga and meditation for PMS relief',
            'Maintain regular sleep schedule',
            'If trying to conceive — avoid alcohol completely',
            'Take calcium supplements to ease PMS',
          ],
          donts: const [
            'Avoid high-sodium foods (increases bloating)',
            "Don't skip exercise — stay lightly active",
            'Avoid excess caffeine (worsens anxiety)',
            "Don't make major decisions during mood swings",
            'Avoid processed/fried foods',
          ],
        );
    }
  }
}

/// Newest period first: by start day, then by when it was written.
List<PeriodLog> sortPeriodLogs(Iterable<PeriodLog> logs) =>
    logs.toList()..sort((a, b) {
      final byStart = b.start.compareTo(a.start);
      return byStart != 0 ? byStart : b.createdAt.compareTo(a.createdAt);
    });

/// A day as AlloConnect writes it: local midnight, ISO-8601 without a zone.
String isoDay(DateTime value) => dateOnly(value).toIso8601String();

/// Reads a stored day. A UTC timestamp is moved to local time first so a
/// date saved near midnight does not land on the day before.
DateTime? parseDay(dynamic raw) {
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return null;
  return dateOnly(parsed.isUtc ? parsed.toLocal() : parsed);
}

DateTime dateOnly(DateTime v) => DateTime(v.year, v.month, v.day);

/// [v]'s date moved by [days] calendar days, always at local midnight — unlike
/// adding a `Duration`, which drifts an hour across a daylight-saving change.
/// Whole calendar days from [from] to [to], unaffected by daylight saving.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

DateTime addDays(DateTime v, int days) =>
    DateTime(v.year, v.month, v.day + days);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int? _asInt(dynamic raw) {
  if (raw is num) return raw.round();
  if (raw == null) return null;
  return num.tryParse(raw.toString())?.round();
}
