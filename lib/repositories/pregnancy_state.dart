/// Pure helpers for deciding which pregnancy state the app is in.
///
/// Kept out of `UserSessionManager` (a GetX singleton wired to SQLite and
/// SharedPreferences) so the precedence rules can be tested directly. The
/// bug these guard against: the stored LMP / EDD survive a delivery, so
/// trusting them ahead of the status left the whole app in pregnancy mode
/// after a pregnancy was completed or deleted.
library;

/// Statuses that mean there is no pregnancy in progress.
const Set<String> nonPregnantStatuses = {
  'notpregnant',
  'newmom',
  'postpartum',
  'delivered',
  'completed',
};

/// Statuses that mean the mother has recently delivered.
const Set<String> postpartumStatuses = {'newmom', 'postpartum', 'delivered'};

/// Strips spaces, dashes and underscores so 'not pregnant', 'not_pregnant'
/// and 'notPregnant' all compare equal.
String normalizePregnancyStatus(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

/// Whether the mother is currently pregnant.
///
/// An explicit status always wins; [hasPregnancyDates] is only a fallback for
/// a missing or unrecognised status.
bool resolveIsPregnant({
  required String status,
  required bool hasPregnancyDates,
}) {
  final normalized = normalizePregnancyStatus(status);
  if (nonPregnantStatuses.contains(normalized)) return false;
  if (normalized == 'pregnant') return true;
  return hasPregnancyDates;
}

/// Whether the mother has recently delivered (postpartum, not simply not
/// pregnant).
bool resolveIsNewMom(String status) =>
    postpartumStatuses.contains(normalizePregnancyStatus(status));

/// Maps a registration status label ("Pregnant", "Pre Pregnancy", "New Mom")
/// onto the value stored in `pregnancyStatus`.
///
/// Only "Pregnant" is actually pregnant. "Pre Pregnancy" contains the substring
/// "pregnan" too, which is why a plain `contains` check is not enough. "New
/// Mom" keeps its own `new_mom` value: it is not pregnant either, but the app
/// still needs to tell postpartum apart from never-pregnant.
String pregnancyStatusForRegistration(
  String label, {
  bool isDad = false,
  bool registeringForPartner = false,
}) {
  if (isDad) return registeringForPartner ? 'pregnant' : 'notpregnant';

  final normalized = label.toLowerCase().trim();
  if (normalized.contains('new')) return 'new_mom';
  if (normalized.startsWith('pre ') ||
      normalized.startsWith('pre-') ||
      normalized.startsWith('prepregnan')) {
    return 'notpregnant';
  }
  return normalized.contains('pregnan') ? 'pregnant' : 'notpregnant';
}

/// Whether a registration status label means she is currently pregnant.
bool isPregnantRegistrationLabel(String label) =>
    pregnancyStatusForRegistration(label) == 'pregnant';
