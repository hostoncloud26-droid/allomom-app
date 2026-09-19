import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

/// Status values the care screens render.
class ScheduleStatus {
  const ScheduleStatus._();

  static const pending = 'pending';
  static const done = 'done';
  static const missed = 'missed';
}

/// Derives a schedule row's status from its dates.
///
/// allomom-api-new stores no `status` column on any schedule table, and that is
/// the right shape: a visit is done exactly when it has a completion date, and
/// missed exactly when its window has closed without one. A stored status would
/// be a third fact that can disagree with the two that matter — and it would go
/// stale on its own, since nothing writes to a row as it ages past its due date.
String _statusFor({
  required DateTime? completedAt,
  required DateTime? dueDate,
  DateTime? windowEnd,
  DateTime? now,
}) {
  if (completedAt != null) return ScheduleStatus.done;
  final deadline = windowEnd ?? dueDate;
  if (deadline == null) return ScheduleStatus.pending;
  final today = now ?? DateTime.now();
  return today.isAfter(deadline) ? ScheduleStatus.missed : ScheduleStatus.pending;
}

/// Which pregnancy month [date] falls in, counted from the active LMP.
///
/// The server stores a month on ANC visits but not on vaccinations or lab
/// tests — their windows are clinical, expressed in gestational weeks. Deriving
/// the month from the same LMP the server anchored those windows on gives the
/// screens one consistent way to group all three.
int? _pregnancyMonthFor(DateTime? date) {
  if (date == null) return null;
  final lmp = PregnancyController.instance.lmpDate;
  if (lmp == null) return null;
  final days = date.difference(lmp).inDays;
  if (days < 0) return 1;
  final month = (days / 30.44).floor() + 1;
  return month.clamp(1, 10);
}

/// Pregnancy month (1-9) to trimester (1-3).
int _trimesterForMonth(int month) {
  if (month <= 3) return 1;
  if (month <= 6) return 2;
  return 3;
}

extension AncCheckupDateView on AncCheckupDate {
  String get status => _statusFor(
    completedAt: completedAt,
    dueDate: scheduledDate,
    windowEnd: scheduledDateRangeTo,
  );

  /// The visit's ordinal. Monthly contacts are numbered by the month they fall
  /// in, so the month *is* the visit number.
  int get visitNumber => month;

  int get pregnancyMonth => month;

  int get trimester => _trimesterForMonth(month);

  /// When the visit actually happened, as opposed to when it was due.
  DateTime? get actualDate => completedAt;

  bool get isDone => completedAt != null;
}

extension PregnancyReportChecklistView on PregnancyReportChecklist {
  String get status => _statusFor(
    completedAt: completedDate,
    dueDate: expectedDate,
    windowEnd: scheduledDateRangeTo,
  );

  DateTime? get dueDate => expectedDate;

  bool get isRequired => required;

  /// The report's category, as the server names it.
  String? get category => reportType;

  int? get pregnancyMonth =>
      _pregnancyMonthFor(scheduledDateRangeFrom ?? expectedDate);

  bool get isDone => completedDate != null;
}

extension PregnancyImmunizationRecordView on PregnancyImmunizationRecord {
  String get status => _statusFor(
    completedAt: receivedDate,
    dueDate: scheduledDate,
    windowEnd: scheduledDateRangeTo,
  );

  DateTime? get administeredDate => receivedDate;

  int? get pregnancyMonth =>
      _pregnancyMonthFor(scheduledDateRangeFrom ?? scheduledDate);

  /// The dose's ordinal, read off the vaccine name ("Td-2" -> 2).
  ///
  /// The server carries the dose in the name rather than a separate column,
  /// since the schedule is a fixed list of named doses.
  int get doseNumber {
    final match = RegExp(r'[-\s](\d+)$').firstMatch(vaccineName.trim());
    return match == null ? 1 : int.parse(match.group(1)!);
  }

  bool get isDone => receivedDate != null;
}

extension BabyImmunizationRecordView on BabyImmunizationRecord {
  String get status => _statusFor(
    completedAt: receivedDate,
    dueDate: scheduledDate,
    windowEnd: scheduledDateRangeTo,
  );

  /// Kept under the name the baby screens already use.
  DateTime? get vaccinationDate => receivedDate;

  DateTime? get expectedDate => scheduledDate;

  bool get isDone => receivedDate != null;
}

extension BabyMilestoneView on BabyMilestone {
  /// A milestone is reached exactly when it has a completion date — there is no
  /// separate flag that could disagree with it.
  bool get achieved => completedAt != null;

  DateTime? get completed => completedAt;
}
