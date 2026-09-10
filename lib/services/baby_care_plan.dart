/// The infant care plan AlloMom schedules when a baby is added.
///
/// Everything here is pure data plus date arithmetic — no database, no widgets
/// — so the schedule can be unit tested on its own. Mirrors the shape of
/// `pregnancy_care_plan.dart`.
///
/// Immunisations follow India's National Immunization Schedule (NIS); the
/// milestone list follows the usual WHO/IAP developmental checkpoints. Both
/// are anchored on the baby's date of birth.
library;

import 'package:allomom/services/pregnancy_care_plan.dart' show addMonthsClamped;

/// A vaccine dose due at a given age.
///
/// Exactly one of [ageInWeeks] / [ageInMonths] carries the age; weeks are used
/// for the tightly-spaced first-year doses, months for everything after.
class ScheduledBabyVaccine {
  const ScheduledBabyVaccine({
    required this.name,
    required this.purpose,
    this.ageInWeeks,
    this.ageInMonths,
    this.required = true,
  }) : assert(
         (ageInWeeks == null) != (ageInMonths == null),
         'Give exactly one of ageInWeeks / ageInMonths',
       );

  final String name;
  final String purpose;
  final int? ageInWeeks;
  final int? ageInMonths;

  /// False for doses that are recommended but not part of the core NIS.
  final bool required;

  /// When this dose falls due for a baby born on [dob].
  DateTime dueDateFrom(DateTime dob) {
    final weeks = ageInWeeks;
    if (weeks != null) return dob.add(Duration(days: weeks * 7));
    return addMonthsClamped(dob, ageInMonths!);
  }

  /// Human-readable age label, e.g. "At birth", "6 weeks", "9 months".
  String get ageLabel {
    final weeks = ageInWeeks;
    if (weeks != null) return weeks == 0 ? 'At birth' : '$weeks weeks';
    final months = ageInMonths!;
    return months == 1 ? '1 month' : '$months months';
  }
}

/// The infant immunisation schedule (India NIS, birth to 6 years).
const List<ScheduledBabyVaccine> babyVaccineSchedule = [
  // ─── At birth ───
  ScheduledBabyVaccine(
    name: 'BCG',
    ageInWeeks: 0,
    purpose: 'Protects against severe forms of childhood tuberculosis',
  ),
  ScheduledBabyVaccine(
    name: 'OPV-0 (Oral Polio, birth dose)',
    ageInWeeks: 0,
    purpose: 'First protection against poliomyelitis',
  ),
  ScheduledBabyVaccine(
    name: 'Hepatitis B-1 (birth dose)',
    ageInWeeks: 0,
    purpose: 'Prevents mother-to-child hepatitis B transmission',
  ),

  // ─── 6 weeks ───
  ScheduledBabyVaccine(
    name: 'Pentavalent-1',
    ageInWeeks: 6,
    purpose: 'Diphtheria, pertussis, tetanus, hepatitis B and Hib',
  ),
  ScheduledBabyVaccine(
    name: 'OPV-1',
    ageInWeeks: 6,
    purpose: 'Second polio dose',
  ),
  ScheduledBabyVaccine(
    name: 'Rotavirus-1',
    ageInWeeks: 6,
    purpose: 'Prevents severe rotavirus diarrhoea',
  ),
  ScheduledBabyVaccine(
    name: 'fIPV-1 (Injectable Polio)',
    ageInWeeks: 6,
    purpose: 'Fractional inactivated polio dose',
  ),
  ScheduledBabyVaccine(
    name: 'PCV-1 (Pneumococcal)',
    ageInWeeks: 6,
    purpose: 'Protects against pneumococcal pneumonia and meningitis',
  ),

  // ─── 10 weeks ───
  ScheduledBabyVaccine(
    name: 'Pentavalent-2',
    ageInWeeks: 10,
    purpose: 'Second dose of the five-in-one vaccine',
  ),
  ScheduledBabyVaccine(
    name: 'OPV-2',
    ageInWeeks: 10,
    purpose: 'Third polio dose',
  ),
  ScheduledBabyVaccine(
    name: 'Rotavirus-2',
    ageInWeeks: 10,
    purpose: 'Second rotavirus dose',
  ),

  // ─── 14 weeks ───
  ScheduledBabyVaccine(
    name: 'Pentavalent-3',
    ageInWeeks: 14,
    purpose: 'Final primary dose of the five-in-one vaccine',
  ),
  ScheduledBabyVaccine(
    name: 'OPV-3',
    ageInWeeks: 14,
    purpose: 'Fourth polio dose',
  ),
  ScheduledBabyVaccine(
    name: 'Rotavirus-3',
    ageInWeeks: 14,
    purpose: 'Final rotavirus dose',
  ),
  ScheduledBabyVaccine(
    name: 'fIPV-2 (Injectable Polio)',
    ageInWeeks: 14,
    purpose: 'Second fractional inactivated polio dose',
  ),
  ScheduledBabyVaccine(
    name: 'PCV-2 (Pneumococcal)',
    ageInWeeks: 14,
    purpose: 'Second pneumococcal dose',
  ),

  // ─── 6 months (recommended, not core NIS) ───
  ScheduledBabyVaccine(
    name: 'Influenza-1',
    ageInMonths: 6,
    purpose: 'Seasonal flu protection',
    required: false,
  ),

  // ─── 9 months ───
  ScheduledBabyVaccine(
    name: 'MR-1 (Measles-Rubella, 1st dose)',
    ageInMonths: 9,
    purpose: 'Protects against measles and rubella',
  ),
  ScheduledBabyVaccine(
    name: 'PCV Booster',
    ageInMonths: 9,
    purpose: 'Pneumococcal booster dose',
  ),
  ScheduledBabyVaccine(
    name: 'JE-1 (Japanese Encephalitis)',
    ageInMonths: 9,
    purpose: 'Given in JE-endemic districts only',
    required: false,
  ),

  // ─── 12 months ───
  ScheduledBabyVaccine(
    name: 'Hepatitis A-1',
    ageInMonths: 12,
    purpose: 'Protects against hepatitis A',
    required: false,
  ),

  // ─── 16-24 months ───
  ScheduledBabyVaccine(
    name: 'MR-2 (Measles-Rubella, 2nd dose)',
    ageInMonths: 16,
    purpose: 'Second measles-rubella dose',
  ),
  ScheduledBabyVaccine(
    name: 'DPT Booster-1',
    ageInMonths: 16,
    purpose: 'Diphtheria, pertussis and tetanus booster',
  ),
  ScheduledBabyVaccine(
    name: 'OPV Booster',
    ageInMonths: 16,
    purpose: 'Polio booster dose',
  ),
  ScheduledBabyVaccine(
    name: 'JE-2 (Japanese Encephalitis)',
    ageInMonths: 16,
    purpose: 'Second JE dose in endemic districts',
    required: false,
  ),
  ScheduledBabyVaccine(
    name: 'Varicella (Chickenpox)',
    ageInMonths: 18,
    purpose: 'Protects against chickenpox',
    required: false,
  ),

  // ─── 5-6 years ───
  ScheduledBabyVaccine(
    name: 'DPT Booster-2',
    ageInMonths: 60,
    purpose: 'Second diphtheria, pertussis and tetanus booster',
  ),
];

/// A developmental checkpoint expected around a given age.
class ScheduledMilestone {
  const ScheduledMilestone({
    required this.milestone,
    required this.description,
    required this.ageInMonths,
  });

  final String milestone;
  final String description;
  final int ageInMonths;

  DateTime dueDateFrom(DateTime dob) => addMonthsClamped(dob, ageInMonths);

  String get ageLabel => ageInMonths == 1 ? '1 month' : '$ageInMonths months';
}

/// Developmental milestones from birth to two years.
///
/// These are guides, not deadlines — babies reach them at their own pace.
const List<ScheduledMilestone> babyMilestonePlan = [
  ScheduledMilestone(
    milestone: 'Lifts head briefly',
    description:
        'Raises their head for a moment during tummy time and turns towards '
        'familiar sounds.',
    ageInMonths: 1,
  ),
  ScheduledMilestone(
    milestone: 'Social smile',
    description: 'Smiles back at you and starts making cooing sounds.',
    ageInMonths: 2,
  ),
  ScheduledMilestone(
    milestone: 'Holds head steady',
    description:
        'Keeps their head steady when held upright and pushes up on their '
        'forearms during tummy time.',
    ageInMonths: 3,
  ),
  ScheduledMilestone(
    milestone: 'Rolls over',
    description:
        'Rolls from tummy to back, reaches for toys and laughs out loud.',
    ageInMonths: 4,
  ),
  ScheduledMilestone(
    milestone: 'Sits with support',
    description:
        'Sits propped up, babbles strings of sounds and passes objects from '
        'hand to hand.',
    ageInMonths: 6,
  ),
  ScheduledMilestone(
    milestone: 'Sits without support',
    description:
        'Sits steadily on their own and reaches for things without toppling.',
    ageInMonths: 8,
  ),
  ScheduledMilestone(
    milestone: 'Crawls and responds to name',
    description:
        'Moves around by crawling or shuffling and looks up when you call '
        'their name.',
    ageInMonths: 9,
  ),
  ScheduledMilestone(
    milestone: 'Pulls to stand',
    description:
        'Pulls up on furniture, uses a pincer grip and waves bye-bye.',
    ageInMonths: 10,
  ),
  ScheduledMilestone(
    milestone: 'First words',
    description:
        'Says one or two clear words, stands alone briefly and understands '
        '"no".',
    ageInMonths: 12,
  ),
  ScheduledMilestone(
    milestone: 'Walks independently',
    description:
        'Takes steps without holding on, drinks from a cup and points at '
        'things they want.',
    ageInMonths: 15,
  ),
  ScheduledMilestone(
    milestone: 'Runs and says 10+ words',
    description:
        'Runs short distances, climbs onto furniture and uses ten or more '
        'words.',
    ageInMonths: 18,
  ),
  ScheduledMilestone(
    milestone: 'Two-word sentences',
    description:
        'Joins two words together, kicks a ball and follows simple '
        'instructions.',
    ageInMonths: 24,
  ),
];
