/// The antenatal care plan AlloMom schedules when a pregnancy is registered.
///
/// Everything here is pure data plus date arithmetic — no database, no widgets
/// — so the schedule can be unit tested on its own.
///
/// **Month numbering.** "Month N" means *N months of pregnancy completed*, so a
/// month-N item falls on `LMP + N months`. Month 2 therefore lands around week
/// 8–9, which is when booking bloods are normally drawn.
library;

/// Adds [months] calendar months to [base], clamping the day to the length of
/// the target month.
///
/// `DateTime(2026, 2, 31)` silently rolls over into March, which would drift a
/// schedule anchored on the 29th–31st, so the day is clamped instead: an LMP of
/// 31 Jan gives 28 Feb, not 3 Mar.
DateTime addMonthsClamped(DateTime base, int months) {
  final zeroBased = base.month - 1 + months;
  final year = base.year + (zeroBased ~/ 12);
  final month = (zeroBased % 12) + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = base.day > lastDayOfMonth ? lastDayOfMonth : base.day;
  return DateTime(year, month, day);
}

/// Trimester a pregnancy month belongs to (1–3, months 1-3 / 4-6 / 7-10).
int trimesterForMonth(int month) {
  if (month <= 3) return 1;
  if (month <= 6) return 2;
  return 3;
}

/// The months a pregnancy runs for.
const List<int> pregnancyMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

/// Months pre-ticked on the ANC question.
///
/// Months 2–9: month 1 is usually before the pregnancy is even confirmed, and
/// month 10 is delivery. The user can tick or untick any month.
const List<int> defaultAncMonths = [2, 3, 4, 5, 6, 7, 8, 9];

/// A maternal vaccine dose due in a given pregnancy month.
class ScheduledVaccine {
  const ScheduledVaccine({
    required this.name,
    required this.month,
    required this.doseNumber,
    required this.purpose,
  });

  final String name;
  final int month;
  final int doseNumber;
  final String purpose;
}

/// The maternal immunisation schedule.
const List<ScheduledVaccine> vaccineSchedule = [
  ScheduledVaccine(
    name: 'TT-1 (Tetanus Toxoid, 1st dose)',
    month: 2,
    doseNumber: 1,
    purpose: 'Protects mother and newborn against tetanus',
  ),
  ScheduledVaccine(
    name: 'TT-2 (Tetanus Toxoid, 2nd dose)',
    month: 4,
    doseNumber: 2,
    purpose: 'Booster dose completing tetanus immunity',
  ),
  ScheduledVaccine(
    name: 'Influenza Vaccine (Flu Shot)',
    month: 6,
    doseNumber: 1,
    purpose: 'Guards against severe influenza in pregnancy',
  ),
  ScheduledVaccine(
    name: 'Tdap (Tetanus, Diphtheria, Pertussis)',
    month: 8,
    doseNumber: 1,
    purpose: 'Passes whooping cough antibodies to the baby',
  ),
];

/// A lab test or scan due in a given pregnancy month.
class ScheduledReport {
  const ScheduledReport({
    required this.name,
    required this.month,
    required this.purpose,
    required this.isRequired,
    required this.category,
  });

  final String name;
  final int month;
  final String purpose;

  /// False for tests a doctor orders only when indicated.
  final bool isRequired;

  /// `blood`, `urine`, `screening` or `monitoring`.
  final String category;
}

/// The antenatal investigation schedule.
const List<ScheduledReport> reportSchedule = [
  // ── Month 2: booking panel ──
  ScheduledReport(
    name: 'Complete Blood Count (CBC)',
    month: 2,
    purpose: 'Detect anemia',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Blood Group and Rh Factor',
    month: 2,
    purpose: 'Identify blood type incompatibility',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'HIV Test',
    month: 2,
    purpose: 'Screen for maternal HIV infection',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Tuberculosis (TB) Screening',
    month: 2,
    purpose: 'Screen for tuberculosis infection',
    isRequired: false,
    category: 'screening',
  ),
  ScheduledReport(
    name: 'Thyroid Function Test (TFT)',
    month: 2,
    purpose: 'Identify thyroid conditions',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'VDRL (Syphilis Test)',
    month: 2,
    purpose: 'Screen for syphilis',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Hepatitis B (HBsAg)',
    month: 2,
    purpose: 'Screen for Hepatitis B infection',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Urine Routine Examination',
    month: 2,
    purpose: 'Detect protein, sugar, and urinary infection',
    isRequired: true,
    category: 'urine',
  ),

  // ── Months 3–7: monthly anemia and urine monitoring ──
  ScheduledReport(
    name: 'Hemoglobin (Hb)',
    month: 3,
    purpose: 'Monitor anemia',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Urine Routine Examination',
    month: 3,
    purpose: 'Detect protein, sugar, and urinary infection',
    isRequired: true,
    category: 'urine',
  ),
  ScheduledReport(
    name: 'Hemoglobin (Hb)',
    month: 4,
    purpose: 'Monitor anemia',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Urine Routine Examination',
    month: 4,
    purpose: 'Detect protein, sugar, and urinary infection',
    isRequired: true,
    category: 'urine',
  ),
  ScheduledReport(
    name: 'Hemoglobin (Hb)',
    month: 5,
    purpose: 'Monitor anemia',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Urine Routine Examination',
    month: 5,
    purpose: 'Detect protein, sugar, and urinary infection',
    isRequired: true,
    category: 'urine',
  ),
  ScheduledReport(
    name: 'Oral Glucose Tolerance Test (OGTT)',
    month: 6,
    purpose: 'Screen for gestational diabetes',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Hemoglobin (Hb)',
    month: 6,
    purpose: 'Monitor anemia',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Urine Routine Examination',
    month: 6,
    purpose: 'Detect protein, sugar, and urinary infection',
    isRequired: true,
    category: 'urine',
  ),
  ScheduledReport(
    name: 'Hemoglobin (Hb)',
    month: 7,
    purpose: 'Monitor anemia',
    isRequired: true,
    category: 'blood',
  ),
  ScheduledReport(
    name: 'Urine Routine Examination',
    month: 7,
    purpose: 'Detect protein, sugar, and urinary infection',
    isRequired: true,
    category: 'urine',
  ),

  // ── Month 8: fetal wellbeing, if indicated ──
  ScheduledReport(
    name: 'Non-Stress Test (NST)',
    month: 8,
    purpose: 'Monitor fetal heart rate, if indicated',
    isRequired: false,
    category: 'monitoring',
  ),
];

/// Ordinal label for a pregnancy month, e.g. `2` -> "2nd Month".
String monthLabel(int month) {
  const suffixes = {1: 'st', 2: 'nd', 3: 'rd'};
  final suffix = (month >= 11 && month <= 13)
      ? 'th'
      : suffixes[month % 10] ?? 'th';
  return '$month$suffix Month';
}
