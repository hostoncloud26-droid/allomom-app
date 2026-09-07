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
