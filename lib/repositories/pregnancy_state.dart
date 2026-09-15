/// Pure helpers for deciding which pregnancy state the app is in.
///
/// The status holds exactly two values, matching the API: 'pregnant' or
/// 'notpregnant'. It answers one question — is a pregnancy in progress? — and
/// is not a journey stage. "Pre Pregnancy" and "New Mom" are both
/// 'notpregnant'; what makes a mother a new mom is the baby she registers,
/// not a third status value.
///
/// Kept out of `UserSessionManager` (a GetX singleton wired to SQLite and
/// SharedPreferences) so the precedence rules can be tested directly. The
/// bugs these guard against: the stored LMP / EDD survive a delivery, so
/// trusting them ahead of the status left the whole app in pregnancy mode
/// after a pregnancy was completed — and because an LMP is collected from
/// every mother, trusting it at registration made everyone pregnant.
library;

/// A pregnancy is in progress.
const String pregnantStatus = 'pregnant';

/// No pregnancy in progress — planning one, or already delivered.
const String notPregnantStatus = 'notpregnant';

/// Every value the status is allowed to hold.
const Set<String> pregnancyStatuses = {pregnantStatus, notPregnantStatus};

/// How long after a birth she still counts as a new mom. A year covers the
/// postpartum content, the baby's first immunisation schedule and its
/// milestone checklist.
const int newMomWindowDays = 365;

/// Strips spaces, dashes and underscores so 'not pregnant', 'not_pregnant'
/// and 'notPregnant' all compare equal.
String normalizePregnancyStatus(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

/// Whether the mother is currently pregnant.
///
/// Only an explicit 'pregnant' counts, so a status left over from an older
/// build ('new_mom', 'postpartum') reads as not pregnant rather than falling
/// through to the dates. [hasPregnancyDates] is consulted only when no status
/// has been recorded at all — otherwise a stored LMP, which every mother has
/// so her next period can be predicted, would imply a pregnancy.
bool resolveIsPregnant({
  required String status,
  required bool hasPregnancyDates,
}) {
  final normalized = normalizePregnancyStatus(status);
  if (normalized.isEmpty) return hasPregnancyDates;
  return normalized == pregnantStatus;
}

/// Whether she is postpartum: not pregnant, with a birth in the last
/// [newMomWindowDays].
///
/// Picking "New Mom" at registration stores 'notpregnant' and sends her on to
/// register her baby, so the birth date is what decides this. Deriving it
/// keeps a mother who registered an older child out of postpartum care, which
/// a stored 'new_mom' status could not do.
bool resolveIsNewMom({
  required bool isPregnant,
  DateTime? lastBirthDate,
  DateTime? now,
}) {
  if (isPregnant || lastBirthDate == null) return false;
  final days = (now ?? DateTime.now()).difference(lastBirthDate).inDays;
  return days >= 0 && days <= newMomWindowDays;
}

/// Maps a registration status label ("Pregnant", "Pre Pregnancy", "New Mom")
/// onto the value stored in `pregnancyStatus`.
///
/// Only "Pregnant" is pregnant. "Pre Pregnancy" contains the substring
/// "pregnan" too, which is why a plain `contains` check is not enough, and
/// "New Mom" is not pregnant either — she goes on to register her baby, and
/// that is what puts her in postpartum care.
String pregnancyStatusForRegistration(
  String label, {
  bool isDad = false,
  bool registeringForPartner = false,
}) {
  if (isDad) {
    return registeringForPartner ? pregnantStatus : notPregnantStatus;
  }

  final normalized = label.toLowerCase().trim();
  if (normalized.contains('new')) return notPregnantStatus;
  if (normalized.startsWith('pre ') ||
      normalized.startsWith('pre-') ||
      normalized.startsWith('prepregnan')) {
    return notPregnantStatus;
  }
  return normalized.contains('pregnan') ? pregnantStatus : notPregnantStatus;
}

/// Whether a registration status label means she is currently pregnant.
bool isPregnantRegistrationLabel(String label) =>
    pregnancyStatusForRegistration(label) == pregnantStatus;

/// Whether a registration status label sends her on to register her baby.
bool isNewMomRegistrationLabel(String label) =>
    label.toLowerCase().trim().contains('new');
